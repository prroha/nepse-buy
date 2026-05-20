import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../constants/api_constants.dart';
import '../services/token_manager.dart';

/// Header name for request correlation ID
const String requestIdHeader = 'x-request-id';

/// UUID generator instance for request IDs
const _uuid = Uuid();

/// Request ID interceptor for end-to-end request tracing
///
/// Generates a unique UUID for each request and adds it to the
/// x-request-id header. This enables correlation of requests
/// across client, server, and logs.
class RequestIdInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Generate unique request ID
    final requestId = _uuid.v4();
    options.headers[requestIdHeader] = requestId;

    // Store request ID for error logging
    options.extra['requestId'] = requestId;

    if (kDebugMode) {
      print('REQUEST ID: $requestId');
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final requestId = err.requestOptions.extra['requestId'] as String?;

    if (kDebugMode && requestId != null) {
      print('ERROR [requestId: $requestId]: ${err.response?.statusCode} ${err.requestOptions.uri}');
      print('   ${err.message}');
    }

    handler.next(err);
  }
}

/// Logging interceptor for debugging
/// Includes request ID for correlation when available
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      final requestId = options.headers[requestIdHeader] ?? options.extra['requestId'];
      final idPrefix = requestId != null ? '[${requestId.toString().substring(0, 8)}] ' : '';
      print('${idPrefix}REQUEST: ${options.method} ${options.uri}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final requestId = response.requestOptions.extra['requestId'];
      final idPrefix = requestId != null ? '[${requestId.toString().substring(0, 8)}] ' : '';
      print('${idPrefix}RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final requestId = err.requestOptions.extra['requestId'];
      final idPrefix = requestId != null ? '[${requestId.toString().substring(0, 8)}] ' : '';
      print('${idPrefix}ERROR: ${err.response?.statusCode} ${err.requestOptions.uri}');
      print('   ${err.message}');
    }
    handler.next(err);
  }
}

/// Auth interceptor for adding tokens and handling refresh
class AuthInterceptor extends Interceptor {
  final Ref _ref;
  bool _isRefreshing = false;
  final List<_QueuedRequest> _requestQueue = [];

  AuthInterceptor(this._ref);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for public endpoints
    if (_isPublicEndpoint(options.path)) {
      handler.next(options);
      return;
    }

    // Add access token if available
    final tokenManager = _ref.read(tokenManagerProvider);
    final accessToken = await tokenManager.getAccessToken();

    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 - try to refresh token
    if (err.response?.statusCode == 401 && !_isPublicEndpoint(err.requestOptions.path)) {
      // Don't retry refresh endpoint failures
      if (err.requestOptions.path.contains('/auth/refresh')) {
        await _handleRefreshFailure();
        handler.next(err);
        return;
      }

      // Attempt token refresh
      final refreshResult = await _attemptTokenRefresh(err.requestOptions);

      if (refreshResult != null) {
        // Retry the original request with new token
        handler.resolve(refreshResult);
        return;
      }
    }

    handler.next(err);
  }

  Future<Response<dynamic>?> _attemptTokenRefresh(RequestOptions originalRequest) async {
    final tokenManager = _ref.read(tokenManagerProvider);

    // If already refreshing, queue this request
    if (_isRefreshing) {
      final completer = Completer<Response<dynamic>?>();
      _requestQueue.add(_QueuedRequest(originalRequest, completer));
      return completer.future;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await tokenManager.getRefreshToken();
      if (refreshToken == null) {
        await _handleRefreshFailure();
        return null;
      }

      // Create a fresh Dio instance for refresh to avoid interceptor loops
      final refreshDio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: Duration(seconds: AppConfig.requestTimeout),
        receiveTimeout: Duration(seconds: AppConfig.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ));

      final response = await refreshDio.post(
        ApiConstants.refresh,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final newAccessToken = data['accessToken'] as String;
        final newRefreshToken = data['refreshToken'] as String;
        final user = data['user'] as Map<String, dynamic>?;

        // Save new tokens
        await tokenManager.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
          userId: user?['id'] as String?,
        );

        // Retry original request with new token
        originalRequest.headers['Authorization'] = 'Bearer $newAccessToken';

        // Create a Dio instance for retrying
        final retryDio = Dio(BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: Duration(seconds: AppConfig.requestTimeout),
          receiveTimeout: Duration(seconds: AppConfig.receiveTimeout),
        ));

        final retryResponse = await retryDio.request(
          originalRequest.path,
          data: originalRequest.data,
          queryParameters: originalRequest.queryParameters,
          options: Options(
            method: originalRequest.method,
            headers: originalRequest.headers,
          ),
        );

        // Process queued requests
        _processQueue(newAccessToken);

        return retryResponse;
      } else {
        await _handleRefreshFailure();
        return null;
      }
    } on DioException catch (_) {
      await _handleRefreshFailure();
      return null;
    } catch (_) {
      await _handleRefreshFailure();
      return null;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _handleRefreshFailure() async {
    final tokenManager = _ref.read(tokenManagerProvider);
    await tokenManager.clearTokens();

    // Fail all queued requests
    for (final queuedRequest in _requestQueue) {
      queuedRequest.completer.complete(null);
    }
    _requestQueue.clear();
  }

  void _processQueue(String newAccessToken) {
    for (final queuedRequest in _requestQueue) {
      // Retry each queued request with new token
      _retryRequest(queuedRequest, newAccessToken);
    }
    _requestQueue.clear();
  }

  Future<void> _retryRequest(_QueuedRequest queuedRequest, String newAccessToken) async {
    try {
      final options = queuedRequest.options;
      options.headers['Authorization'] = 'Bearer $newAccessToken';

      final retryDio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: Duration(seconds: AppConfig.requestTimeout),
        receiveTimeout: Duration(seconds: AppConfig.receiveTimeout),
      ));

      final response = await retryDio.request(
        options.path,
        data: options.data,
        queryParameters: options.queryParameters,
        options: Options(
          method: options.method,
          headers: options.headers,
        ),
      );

      queuedRequest.completer.complete(response);
    } catch (_) {
      queuedRequest.completer.complete(null);
    }
  }

  bool _isPublicEndpoint(String path) {
    const publicEndpoints = [
      '/auth/login',
      '/auth/register',
      '/auth/refresh',
    ];
    return publicEndpoints.any((e) => path.contains(e));
  }
}

/// Helper class to queue requests during token refresh
class _QueuedRequest {
  final RequestOptions options;
  final Completer<Response<dynamic>?> completer;

  _QueuedRequest(this.options, this.completer);
}
