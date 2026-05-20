/// Base exception class
abstract class AppException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  const AppException(this.message, [this.statusCode, this.code]);

  @override
  String toString() => 'AppException: $message (status: $statusCode, code: $code)';
}

/// Server exception (API errors)
class ServerException extends AppException {
  const ServerException([
    String message = 'Server error',
    int? statusCode,
    String? code,
  ]) : super(message, statusCode, code);
}

/// Network exception (connectivity issues)
class NetworkException extends AppException {
  const NetworkException([String message = 'Network error']) : super(message);
}

/// Unauthorized exception (401)
class UnauthorizedException extends AppException {
  const UnauthorizedException([String message = 'Unauthorized'])
      : super(message, 401);
}

/// Validation exception (400, 422)
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException([
    String message = 'Validation error',
    this.fieldErrors,
    int? statusCode,
  ]) : super(message, statusCode);
}

/// Cache exception (local storage errors)
class CacheException extends AppException {
  const CacheException([String message = 'Cache error']) : super(message);
}
