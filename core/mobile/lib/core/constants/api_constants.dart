/// API endpoint constants
class ApiConstants {
  // Base URL - configure via environment
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1', // Android emulator localhost
  );

  /// Base URL for the static JSON bundle published by GitHub Actions
  /// (see `.github/workflows/refresh-static-data.yml`).
  /// Override at build time: `--dart-define=STATIC_DATA_URL=https://raw.githubusercontent.com/<owner>/nepse-buy/main/data`
  static const String staticDataUrl = String.fromEnvironment(
    'STATIC_DATA_URL',
    defaultValue:
        'https://raw.githubusercontent.com/act3ai/nepse-buy/main/data',
  );

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String refresh = '/auth/refresh';
  static const String anonRegister = '/auth/anon';
  static const String claim = '/auth/claim';
  static const String changePassword = '/auth/change-password';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static String verifyResetToken(String token) => '/auth/verify-reset-token/$token';

  // Email verification endpoints
  static String verifyEmail(String token) => '/auth/verify-email/$token';
  static const String sendVerification = '/auth/send-verification';

  // Session management endpoints
  static const String sessions = '/auth/sessions';
  static String sessionById(String id) => '/auth/sessions/$id';

  // User profile endpoints
  static const String profile = '/users/me';
  static const String avatar = '/users/me/avatar';

  // Admin endpoints
  static const String adminStats = '/admin/stats';
  static const String adminUsers = '/admin/users';
  static String adminUserById(String id) => '/admin/users/$id';
  static const String adminAuditLogs = '/admin/audit-logs';
  static String adminAuditLogById(String id) => '/admin/audit-logs/$id';
  static const String adminAuditLogEntityTypes = '/admin/audit-logs/entity-types';
  static const String adminAuditLogActionTypes = '/admin/audit-logs/action-types';

  // Search endpoints
  static const String search = '/search';

  // Contact endpoints
  static const String contact = '/contact';

  // Notification endpoints
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static const String notificationsReadAll = '/notifications/read-all';
  static String notificationById(String id) => '/notifications/$id';
  static String notificationMarkRead(String id) => '/notifications/$id/read';

  // Stock endpoints (nepse-buy domain)
  static const String stocks = '/stocks';
  static String stockBySymbol(String symbol) => '/stocks/$symbol';

  // Watchlist endpoints
  static const String watchlist = '/watchlist';
  static const String watchlistItems = '/watchlist/items';
  static String watchlistItemById(String id) => '/watchlist/items/$id';

  // Signal endpoints
  static const String signalsToday = '/signals/today';
  static const String signalsHistory = '/signals/history';

  // Debt account endpoints (v0.3)
  static const String debtAccounts = '/debt-accounts';
  static String debtAccountById(String id) => '/debt-accounts/$id';

  // Position endpoints (v0.4)
  static const String positions = '/positions';
  static const String positionsPurchases = '/positions/purchases';
  static String positionById(String id) => '/positions/$id';

  // Trade + fee-schedule endpoints (v0.7)
  static const String trades = '/trades';
  static String tradeById(String id) => '/trades/$id';
  static const String feeSchedule = '/fee-schedule';

  // Screener endpoint (v0.8) — public, no auth required.
  static const String screener = '/screener';

  // Corporate actions endpoint (v0.8) — list public, create requires auth.
  static const String corporateActions = '/corporate-actions';
  static String corporateActionById(String id) => '/corporate-actions/$id';

  // Prevent instantiation
  ApiConstants._();
}

/// Application configuration constants
class AppConfig {
  /// Request timeout in seconds
  static const int requestTimeout = 30;

  /// Receive timeout in seconds
  static const int receiveTimeout = 30;

  /// Number of retry attempts for failed requests
  static const int retryAttempts = 3;

  /// Initial retry delay in milliseconds
  static const int retryDelay = 1000;

  /// Multiplier for exponential backoff
  static const int retryBackoffMultiplier = 2;

  // Prevent instantiation
  AppConfig._();
}

/// Pagination constants
class PaginationConfig {
  /// Default page size
  static const int defaultPageSize = 10;

  /// Page size for notifications
  static const int notificationsPageSize = 20;

  /// Page size for admin users list
  static const int adminUsersPageSize = 10;

  /// Page size for audit logs
  static const int auditLogsPageSize = 20;

  /// Limit for search results
  static const int searchLimit = 5;

  // Prevent instantiation
  PaginationConfig._();
}

/// Validation constants
class ValidationConfig {
  /// Minimum password length
  static const int passwordMinLength = 8;

  /// Maximum password length
  static const int passwordMaxLength = 128;

  /// Minimum name length
  static const int nameMinLength = 2;

  /// Maximum name length
  static const int nameMaxLength = 100;

  /// Maximum bio length
  static const int bioMaxLength = 500;

  /// Email regex pattern
  static final RegExp emailPattern = RegExp(
    r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)+$',
  );

  /// Password complexity pattern (at least one letter and one number)
  static final RegExp passwordComplexityPattern = RegExp(r'^(?=.*[a-zA-Z])(?=.*[0-9])');

  /// Name allowed characters pattern
  static final RegExp namePattern = RegExp(r"^[a-zA-Z\s'-]+$");

  // Prevent instantiation
  ValidationConfig._();
}

/// File upload constants
class FileUploadConfig {
  /// Maximum avatar file size in bytes (5 MB)
  static const int maxAvatarSize = 5 * 1024 * 1024;

  /// Maximum general file size in bytes (10 MB)
  static const int maxFileSize = 10 * 1024 * 1024;

  /// Allowed image MIME types for avatars
  static const List<String> allowedAvatarTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
  ];

  /// Allowed image extensions
  static const List<String> allowedImageExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
  ];

  // Prevent instantiation
  FileUploadConfig._();
}

/// Duration constants (in milliseconds)
class DurationConfig {
  /// Default toast duration
  static const int toastDefault = 4000;

  /// Error toast duration
  static const int toastError = 6000;

  /// Success indicator display time
  static const int successIndicator = 2000;

  /// Debounce delay for search input
  static const int searchDebounce = 300;

  // Prevent instantiation
  DurationConfig._();
}

/// User roles
class UserRoles {
  static const String user = 'USER';
  static const String admin = 'ADMIN';
  static const String superAdmin = 'SUPER_ADMIN';

  /// Check if a role has admin access (ADMIN or SUPER_ADMIN)
  static bool hasAdminAccess(String? role) =>
      role == admin || role == superAdmin;

  // Prevent instantiation
  UserRoles._();
}

/// Notification types
class NotificationTypes {
  static const String info = 'INFO';
  static const String success = 'SUCCESS';
  static const String warning = 'WARNING';
  static const String error = 'ERROR';
  static const String system = 'SYSTEM';

  // Prevent instantiation
  NotificationTypes._();
}

/// Audit action types
class AuditActions {
  static const String create = 'CREATE';
  static const String read = 'READ';
  static const String update = 'UPDATE';
  static const String delete = 'DELETE';
  static const String login = 'LOGIN';
  static const String logout = 'LOGOUT';
  static const String loginFailed = 'LOGIN_FAILED';
  static const String passwordChange = 'PASSWORD_CHANGE';
  static const String passwordReset = 'PASSWORD_RESET';
  static const String emailVerify = 'EMAIL_VERIFY';
  static const String adminAction = 'ADMIN_ACTION';

  // Prevent instantiation
  AuditActions._();
}

/// Contact message status
class ContactMessageStatus {
  static const String pending = 'PENDING';
  static const String read = 'READ';
  static const String replied = 'REPLIED';

  // Prevent instantiation
  ContactMessageStatus._();
}
