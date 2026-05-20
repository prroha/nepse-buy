import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/api_constants.dart';
import '../errors/failures.dart';
import '../network/api_client.dart';

/// Export format types
enum ExportFormat { json, csv }

/// Export service provider
final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService(dio: ref.watch(dioProvider));
});

/// Export service for downloading and sharing exported data
class ExportService {
  final Dio _dio;

  ExportService({required Dio dio}) : _dio = dio;

  /// Export user's personal data (GDPR compliant)
  /// Downloads the file and saves it to temporary directory
  Future<Either<Failure, File>> exportMyData({
    ExportFormat format = ExportFormat.json,
  }) async {
    try {
      final formatStr = format == ExportFormat.csv ? 'csv' : 'json';
      final extension = format == ExportFormat.csv ? 'csv' : 'json';
      final timestamp = DateTime.now().toIso8601String().split('T')[0];
      final filename = 'my-data-$timestamp.$extension';

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$filename';

      // Download file
      await _dio.download(
        '${ApiConstants.profile}/export?format=$formatStr',
        filePath,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Accept': format == ExportFormat.csv
                ? 'text/csv'
                : 'application/json',
          },
        ),
      );

      return Right(File(filePath));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure('Failed to export data: ${e.toString()}'));
    }
  }

  /// Export all users (admin only)
  Future<Either<Failure, File>> exportAllUsers({bool stream = false}) async {
    try {
      final timestamp = DateTime.now().toIso8601String().split('T')[0];
      final filename = 'users-export-$timestamp.csv';

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$filename';

      // Download file
      await _dio.download(
        '${ApiConstants.adminUsers}/export${stream ? '?stream=true' : ''}',
        filePath,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Accept': 'text/csv',
          },
        ),
      );

      return Right(File(filePath));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure('Failed to export users: ${e.toString()}'));
    }
  }

  /// Export audit logs (admin only)
  Future<Either<Failure, File>> exportAuditLogs({
    DateTime? startDate,
    DateTime? endDate,
    String? action,
    String? userId,
  }) async {
    try {
      final timestamp = DateTime.now().toIso8601String().split('T')[0];
      final filename = 'audit-logs-export-$timestamp.csv';

      // Build query parameters
      final queryParams = <String, String>{};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      if (action != null) {
        queryParams['action'] = action;
      }
      if (userId != null) {
        queryParams['userId'] = userId;
      }

      final queryString = queryParams.isNotEmpty
          ? '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}'
          : '';

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$filename';

      // Download file
      await _dio.download(
        '${ApiConstants.adminAuditLogs}/export$queryString',
        filePath,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Accept': 'text/csv',
          },
        ),
      );

      return Right(File(filePath));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure('Failed to export audit logs: ${e.toString()}'));
    }
  }

  /// Share exported file using system share dialog
  Future<Either<Failure, void>> shareFile(File file, {String? subject}) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: subject,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to share file: ${e.toString()}'));
    }
  }

  /// Save file to downloads directory (Android) or documents (iOS)
  Future<Either<Failure, String>> saveToDownloads(File file) async {
    try {
      Directory? targetDir;

      if (Platform.isAndroid) {
        // Use external storage downloads directory on Android
        targetDir = Directory('/storage/emulated/0/Download');
        if (!await targetDir.exists()) {
          targetDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        // Use application documents directory on iOS
        targetDir = await getApplicationDocumentsDirectory();
      }

      if (targetDir == null) {
        return const Left(ServerFailure('Could not access storage directory'));
      }

      final filename = file.path.split('/').last;
      final newPath = '${targetDir.path}/$filename';

      await file.copy(newPath);

      return Right(newPath);
    } catch (e) {
      return Left(ServerFailure('Failed to save file: ${e.toString()}'));
    }
  }

  /// Export and share user data in one step
  Future<Either<Failure, void>> exportAndShareMyData({
    ExportFormat format = ExportFormat.json,
  }) async {
    final exportResult = await exportMyData(format: format);

    return exportResult.fold(
      (failure) => Left(failure),
      (file) => shareFile(file, subject: 'My Data Export'),
    );
  }

  /// Export and share all users in one step (admin only)
  Future<Either<Failure, void>> exportAndShareUsers() async {
    final exportResult = await exportAllUsers();

    return exportResult.fold(
      (failure) => Left(failure),
      (file) => shareFile(file, subject: 'Users Export'),
    );
  }

  /// Handle Dio errors
  Failure _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const NetworkFailure('Connection timeout');
      case DioExceptionType.connectionError:
        return const NetworkFailure('No internet connection');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 500;
        final data = e.response?.data;
        String message = 'Export failed';

        if (data is Map<String, dynamic>) {
          final error = data['error'] as Map<String, dynamic>?;
          message = error?['message'] as String? ?? message;
        }

        if (statusCode == 401) {
          return const AuthFailure('Not authenticated');
        } else if (statusCode == 403) {
          return const AuthFailure('Permission denied');
        }

        return ServerFailure(message);
      default:
        return ServerFailure(e.message ?? 'Export failed');
    }
  }
}
