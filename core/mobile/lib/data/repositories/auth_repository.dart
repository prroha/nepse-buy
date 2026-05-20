import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/network/api_client.dart';
import '../../core/services/token_manager.dart';
import 'base_repository.dart';

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    dio: ref.watch(dioProvider),
    tokenManager: ref.watch(tokenManagerProvider),
  );
});

/// Auth response model
class AuthResponse {
  final String userId;
  final String email;
  final String? name;
  final String role;
  final String accessToken;
  final String refreshToken;

  const AuthResponse({
    required this.userId,
    required this.email,
    this.name,
    required this.role,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final user = data['user'] as Map<String, dynamic>;

    return AuthResponse(
      userId: user['id'] as String,
      email: user['email'] as String,
      name: user['name'] as String?,
      role: user['role'] as String? ?? 'USER',
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
  }

  /// Check if user has admin access (ADMIN or SUPER_ADMIN)
  bool get isAdmin => role == 'ADMIN' || role == 'SUPER_ADMIN';

  /// Check if user is a super admin (platform owner)
  bool get isSuperAdmin => role == 'SUPER_ADMIN';
}

/// Register response model (registration doesn't return tokens)
class RegisterResponse {
  final String userId;
  final String email;
  final String? name;

  const RegisterResponse({
    required this.userId,
    required this.email,
    this.name,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final user = data['user'] as Map<String, dynamic>;

    return RegisterResponse(
      userId: user['id'] as String,
      email: user['email'] as String,
      name: user['name'] as String?,
    );
  }
}

/// Token refresh response model
class TokenRefreshResponse {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String email;

  const TokenRefreshResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.email,
  });

  factory TokenRefreshResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final user = data['user'] as Map<String, dynamic>?;

    return TokenRefreshResponse(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      userId: user?['id'] as String? ?? '',
      email: user?['email'] as String? ?? '',
    );
  }
}

/// Verify reset token response
class VerifyResetTokenResponse {
  final bool valid;
  final String? email;

  const VerifyResetTokenResponse({
    required this.valid,
    this.email,
  });

  factory VerifyResetTokenResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return VerifyResetTokenResponse(
      valid: data['valid'] as bool,
      email: data['email'] as String?,
    );
  }
}

/// Verify email response
class VerifyEmailResponse {
  final bool verified;
  final String email;

  const VerifyEmailResponse({
    required this.verified,
    required this.email,
  });

  factory VerifyEmailResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return VerifyEmailResponse(
      verified: data['verified'] as bool,
      email: data['email'] as String,
    );
  }
}

/// Auth repository interface
abstract class AuthRepository {
  /// Login with email and password
  Future<Either<Failure, AuthResponse>> login({
    required String email,
    required String password,
  });

  /// Register a new user
  Future<Either<Failure, RegisterResponse>> register({
    required String email,
    required String password,
    String? name,
  });

  /// Anonymous register — backend creates an anon User and returns a JWT pair.
  /// Subject to the admin requireRegistration kill-switch (returns 403 if set).
  Future<Either<Failure, AuthResponse>> anonRegister({String? deviceId});

  /// Claim the currently-authenticated anonymous account by attaching email + password.
  Future<Either<Failure, void>> claimAccount({
    required String email,
    required String password,
    String? name,
  });

  /// Refresh access token using refresh token
  Future<Either<Failure, TokenRefreshResponse>> refreshToken(
    String refreshToken,
  );

  /// Logout the current user
  Future<Either<Failure, void>> logout();

  /// Change user password
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });

  /// Request password reset email
  Future<Either<Failure, void>> forgotPassword({
    required String email,
  });

  /// Verify password reset token
  Future<Either<Failure, VerifyResetTokenResponse>> verifyResetToken(
    String token,
  );

  /// Reset password with token
  Future<Either<Failure, void>> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  });

  /// Verify email with token
  Future<Either<Failure, VerifyEmailResponse>> verifyEmail(String token);

  /// Request a new verification email
  Future<Either<Failure, void>> sendVerificationEmail();
}

/// Auth repository implementation
class AuthRepositoryImpl with BaseRepository implements AuthRepository {
  final Dio _dio;
  final TokenManager _tokenManager;

  AuthRepositoryImpl({
    required Dio dio,
    required TokenManager tokenManager,
  })  : _dio = dio,
        _tokenManager = tokenManager;

  @override
  Future<Either<Failure, AuthResponse>> login({
    required String email,
    required String password,
  }) async {
    return safeCall(() async {
      final response = await _dio.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);

      // Save tokens
      await _tokenManager.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
        userId: authResponse.userId,
      );

      return authResponse;
    });
  }

  @override
  Future<Either<Failure, AuthResponse>> anonRegister({String? deviceId}) async {
    return safeCall(() async {
      final response = await _dio.post(
        ApiConstants.anonRegister,
        data: deviceId != null ? {'deviceId': deviceId} : <String, dynamic>{},
      );
      final authResponse = AuthResponse.fromJson(response.data);
      await _tokenManager.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
        userId: authResponse.userId,
      );
      return authResponse;
    });
  }

  @override
  Future<Either<Failure, void>> claimAccount({
    required String email,
    required String password,
    String? name,
  }) async {
    return safeCall(() async {
      await _dio.post(
        ApiConstants.claim,
        data: {
          'email': email,
          'password': password,
          if (name != null && name.isNotEmpty) 'name': name,
        },
      );
    });
  }

  @override
  Future<Either<Failure, RegisterResponse>> register({
    required String email,
    required String password,
    String? name,
  }) async {
    return safeCall(() async {
      final response = await _dio.post(
        ApiConstants.register,
        data: {
          'email': email,
          'password': password,
          if (name != null) 'name': name,
        },
      );

      return RegisterResponse.fromJson(response.data);
    });
  }

  @override
  Future<Either<Failure, TokenRefreshResponse>> refreshToken(
    String refreshToken,
  ) async {
    return safeCall(() async {
      final response = await _dio.post(
        ApiConstants.refresh,
        data: {
          'refreshToken': refreshToken,
        },
      );

      final tokenResponse = TokenRefreshResponse.fromJson(response.data);

      // Save new tokens
      await _tokenManager.saveTokens(
        accessToken: tokenResponse.accessToken,
        refreshToken: tokenResponse.refreshToken,
        userId: tokenResponse.userId,
      );

      return tokenResponse;
    });
  }

  @override
  Future<Either<Failure, void>> logout() async {
    return safeCall(() async {
      try {
        await _dio.post(ApiConstants.logout);
      } catch (_) {
        // Ignore logout API errors, still clear local tokens
      }
      await _tokenManager.clearTokens();
    });
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return safeCall(() async {
      await _dio.post(
        ApiConstants.changePassword,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );
    });
  }

  @override
  Future<Either<Failure, void>> forgotPassword({
    required String email,
  }) async {
    return safeCall(() async {
      await _dio.post(
        ApiConstants.forgotPassword,
        data: {'email': email},
      );
    });
  }

  @override
  Future<Either<Failure, VerifyResetTokenResponse>> verifyResetToken(
    String token,
  ) async {
    return safeCall(() async {
      final response = await _dio.get(ApiConstants.verifyResetToken(token));
      return VerifyResetTokenResponse.fromJson(response.data);
    });
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    return safeCall(() async {
      await _dio.post(
        ApiConstants.resetPassword,
        data: {
          'token': token,
          'password': password,
          'confirmPassword': confirmPassword,
        },
      );
    });
  }

  @override
  Future<Either<Failure, VerifyEmailResponse>> verifyEmail(String token) async {
    return safeCall(() async {
      final response = await _dio.get(ApiConstants.verifyEmail(token));
      return VerifyEmailResponse.fromJson(response.data);
    });
  }

  @override
  Future<Either<Failure, void>> sendVerificationEmail() async {
    return safeCall(() async {
      await _dio.post(ApiConstants.sendVerification);
    });
  }
}
