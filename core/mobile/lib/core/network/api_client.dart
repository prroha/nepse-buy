import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import 'api_interceptors.dart';

/// Dio provider for dependency injection
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: Duration(seconds: AppConfig.requestTimeout),
      receiveTimeout: Duration(seconds: AppConfig.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Add interceptors (order matters: request ID first for tracing)
  dio.interceptors.addAll([
    RequestIdInterceptor(),
    LoggingInterceptor(),
    AuthInterceptor(ref),
  ]);

  return dio;
});
