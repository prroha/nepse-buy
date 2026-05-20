/// Base failure class for all application failures
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, [this.code]);

  @override
  String toString() => 'Failure: $message (code: $code)';
}

/// Server-related failures (API errors, 5xx responses)
class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server error occurred', String? code])
      : super(message, code);
}

/// Network-related failures (no internet, timeout)
class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Network error occurred', String? code])
      : super(message, code);
}

/// Authentication failures (401, invalid token)
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([String message = 'Unauthorized', String? code])
      : super(message, code);
}

/// Validation failures (400, invalid input)
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure([
    String message = 'Validation error',
    this.fieldErrors,
    String? code,
  ]) : super(message, code);
}

/// Cache-related failures (local storage errors)
class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache error occurred', String? code])
      : super(message, code);
}

/// Unknown/unexpected failures
class UnknownFailure extends Failure {
  const UnknownFailure([String message = 'An unexpected error occurred', String? code])
      : super(message, code);
}

/// Authentication-required failures. Distinct from UnauthorizedFailure (401 from
/// the server) — this signals a local auth precondition not met (no session,
/// missing role) before an outbound call is attempted.
class AuthFailure extends Failure {
  const AuthFailure([String message = 'Authentication required', String? code])
      : super(message, code);
}
