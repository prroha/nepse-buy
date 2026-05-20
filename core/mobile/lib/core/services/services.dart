/// Core services for the application.
///
/// This library exports all core services:
/// - [TokenManager] - Secure storage for authentication tokens
/// - [ToastService] - Toast notifications (snackbars)
///
/// Example:
/// ```dart
/// import 'package:your_app/core/services/services.dart';
///
/// // Token management
/// final tokenManager = TokenManager();
/// await tokenManager.saveTokens(accessToken, refreshToken);
///
/// // Toast notifications
/// final toastService = ToastService();
/// toastService.showSuccess(context, 'Profile saved!');
/// ```
library services;

export 'export_service.dart';
export 'toast_service.dart';
export 'token_manager.dart';
