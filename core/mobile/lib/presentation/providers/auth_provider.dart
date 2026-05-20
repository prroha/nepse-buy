import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/token_manager.dart';
import '../../data/repositories/auth_repository.dart';

/// Auth state class
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final String? userId;
  final String? email;
  final String? role;
  final bool emailVerified;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.userId,
    this.email,
    this.role,
    this.emailVerified = false,
  });

  /// Check if the current user has admin access (ADMIN or SUPER_ADMIN)
  bool get isAdmin => role == 'ADMIN' || role == 'SUPER_ADMIN';

  /// Check if the current user is a super admin (platform owner)
  bool get isSuperAdmin => role == 'SUPER_ADMIN';

  /// Check if the email is verified
  bool get isEmailVerified => emailVerified;

  /// True when the current account was created via /auth/anon — detected by
  /// the email pattern anon-<uuid>@nepse-buy.local. Used by UI to surface
  /// a "Claim account" affordance without requiring a backend round-trip.
  bool get isAnonymous => email != null && email!.startsWith('anon-') && email!.endsWith('@nepse-buy.local');

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    String? userId,
    String? email,
    String? role,
    bool? emailVerified,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      role: role ?? this.role,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }
}

/// Auth state notifier for managing authentication state
class AuthNotifier extends StateNotifier<AuthState> {
  final TokenManager _tokenManager;
  final AuthRepository _authRepository;

  AuthNotifier(this._tokenManager, this._authRepository)
      : super(const AuthState(isAuthenticated: true, isLoading: false));

  /// Post-pivot the REST backend is gone — the app is local-only. We
  /// initialise the auth state as "authenticated" in the constructor so
  /// the router doesn't bounce to /login and no network call is made.
  /// `_authRepository` and `_tokenManager` stay wired in case a future
  /// build re-introduces account-based features (e.g., multi-device sync).

  /// Claim the currently-authenticated anonymous account by attaching email + password.
  Future<bool> claimAccount({
    required String email,
    required String password,
    String? name,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _authRepository.claimAccount(email: email, password: password, name: name);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(
          isLoading: false,
          email: email,
          emailVerified: false,
        );
        return true;
      },
    );
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    // Basic validation before API call
    if (email.isEmpty || password.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: 'Email and password are required',
      );
      return false;
    }

    final result = await _authRepository.login(
      email: email,
      password: password,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
        return false;
      },
      (authResponse) {
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          userId: authResponse.userId,
          email: authResponse.email,
          role: authResponse.role,
        );
        return true;
      },
    );
  }

  /// Register a new user
  Future<bool> register(String email, String password, String confirmPassword) async {
    state = state.copyWith(isLoading: true, error: null);

    // Basic validation
    if (email.isEmpty || password.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: 'Email and password are required',
      );
      return false;
    }

    if (password != confirmPassword) {
      state = state.copyWith(
        isLoading: false,
        error: 'Passwords do not match',
      );
      return false;
    }

    if (password.length < 8) {
      state = state.copyWith(
        isLoading: false,
        error: 'Password must be at least 8 characters',
      );
      return false;
    }

    // Register first
    final registerResult = await _authRepository.register(
      email: email,
      password: password,
    );

    return await registerResult.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
        return false;
      },
      (registerResponse) async {
        // After successful registration, login to get tokens
        final loginResult = await _authRepository.login(
          email: email,
          password: password,
        );

        return loginResult.fold(
          (failure) {
            state = state.copyWith(
              isLoading: false,
              error: 'Registration successful, but login failed: ${failure.message}',
            );
            return false;
          },
          (authResponse) {
            state = state.copyWith(
              isAuthenticated: true,
              isLoading: false,
              userId: authResponse.userId,
              email: authResponse.email,
              role: authResponse.role,
            );
            return true;
          },
        );
      },
    );
  }

  /// Logout the current user
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authRepository.logout();
      state = const AuthState(isAuthenticated: false, isLoading: false);
    } catch (e) {
      // Even if logout fails, clear local state
      await _tokenManager.clearTokens();
      state = const AuthState(isAuthenticated: false, isLoading: false);
    }
  }

  /// Clear any error messages
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Force logout (called when token refresh fails)
  Future<void> forceLogout() async {
    await _tokenManager.clearTokens();
    state = const AuthState(
      isAuthenticated: false,
      isLoading: false,
      error: 'Session expired. Please login again.',
    );
  }

  /// Change password
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    // Basic validation
    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: 'All password fields are required',
      );
      return false;
    }

    if (newPassword.length < 8) {
      state = state.copyWith(
        isLoading: false,
        error: 'New password must be at least 8 characters',
      );
      return false;
    }

    if (newPassword != confirmPassword) {
      state = state.copyWith(
        isLoading: false,
        error: 'New passwords do not match',
      );
      return false;
    }

    if (currentPassword == newPassword) {
      state = state.copyWith(
        isLoading: false,
        error: 'New password must be different from current password',
      );
      return false;
    }

    final result = await _authRepository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
        return false;
      },
      (_) {
        state = state.copyWith(isLoading: false);
        return true;
      },
    );
  }
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final tokenManager = ref.watch(tokenManagerProvider);
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(tokenManager, authRepository);
});
