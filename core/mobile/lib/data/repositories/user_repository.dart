import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/network/api_client.dart';
import 'base_repository.dart';

/// User repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(dio: ref.watch(dioProvider));
});

/// User profile model
class UserProfile {
  final String id;
  final String email;
  final String? name;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.email,
    this.name,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final profile = data['profile'] as Map<String, dynamic>? ?? data;

    return UserProfile(
      id: profile['id'] as String,
      email: profile['email'] as String,
      name: profile['name'] as String?,
      role: profile['role'] as String,
      isActive: profile['isActive'] as bool,
      createdAt: DateTime.parse(profile['createdAt'] as String),
      updatedAt: DateTime.parse(profile['updatedAt'] as String),
    );
  }
}

/// User avatar model
class UserAvatar {
  final String? url;
  final String initials;

  const UserAvatar({
    this.url,
    required this.initials,
  });

  factory UserAvatar.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final avatar = data['avatar'] as Map<String, dynamic>? ?? data;

    return UserAvatar(
      url: avatar['url'] as String?,
      initials: avatar['initials'] as String,
    );
  }
}

/// Update profile request model
class UpdateProfileRequest {
  final String? name;
  final String? email;

  const UpdateProfileRequest({this.name, this.email});

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
    };
  }
}

/// User repository interface
abstract class UserRepository {
  /// Get current user profile
  Future<Either<Failure, UserProfile>> getProfile();

  /// Update current user profile
  Future<Either<Failure, UserProfile>> updateProfile(UpdateProfileRequest request);

  /// Get current user avatar
  Future<Either<Failure, UserAvatar>> getAvatar();

  /// Upload user avatar
  Future<Either<Failure, String>> uploadAvatar(
    File file, {
    void Function(int sent, int total)? onProgress,
  });

  /// Delete user avatar
  Future<Either<Failure, void>> deleteAvatar();
}

/// User repository implementation
class UserRepositoryImpl with BaseRepository implements UserRepository {
  final Dio _dio;

  UserRepositoryImpl({required Dio dio}) : _dio = dio;

  @override
  Future<Either<Failure, UserProfile>> getProfile() async {
    return safeCall(() async {
      final response = await _dio.get(ApiConstants.profile);
      return UserProfile.fromJson(response.data);
    });
  }

  @override
  Future<Either<Failure, UserProfile>> updateProfile(
    UpdateProfileRequest request,
  ) async {
    return safeCall(() async {
      final response = await _dio.patch(
        ApiConstants.profile,
        data: request.toJson(),
      );
      return UserProfile.fromJson(response.data);
    });
  }

  @override
  Future<Either<Failure, UserAvatar>> getAvatar() async {
    return safeCall(() async {
      final response = await _dio.get(ApiConstants.avatar);
      return UserAvatar.fromJson(response.data);
    });
  }

  @override
  Future<Either<Failure, String>> uploadAvatar(
    File file, {
    void Function(int sent, int total)? onProgress,
  }) async {
    return safeCall(() async {
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        ApiConstants.avatar,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
        onSendProgress: onProgress,
      );

      final data = response.data['data'] ?? response.data;
      final avatar = data['avatar'] as Map<String, dynamic>;
      return avatar['url'] as String;
    });
  }

  @override
  Future<Either<Failure, void>> deleteAvatar() async {
    return safeCall(() async {
      await _dio.delete(ApiConstants.avatar);
    });
  }
}
