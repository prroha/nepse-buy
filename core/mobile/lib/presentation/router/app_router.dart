import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/admin/admin_audit_logs_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_users_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/auth/verify_email_screen.dart';
import '../screens/error/not_found_screen.dart';
import '../screens/home/main_shell.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/stock_detail/stock_detail_screen.dart';
import '../screens/debt/debt_accounts_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/contact/contact_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/sessions/sessions_screen.dart';
import '../screens/portfolio/broker_inbox_screen.dart';
import '../screens/settings/backup_restore_screen.dart';
import '../screens/settings/change_password_screen.dart';
import '../screens/settings/security_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/signals/signal_history_screen.dart';
import '../screens/about/about_screen.dart';
import '../screens/faq/faq_screen.dart';
import '../screens/legal/legal_screen.dart';
import 'routes.dart';

/// GoRouter provider for navigation
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: Routes.home,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation == Routes.login ||
          state.matchedLocation == Routes.register ||
          state.matchedLocation == Routes.forgotPassword ||
          state.matchedLocation.startsWith(Routes.resetPassword) ||
          state.matchedLocation.startsWith(Routes.verifyEmail);

      // If not authenticated and trying to access protected route
      if (!isAuthenticated && !isAuthRoute) {
        return Routes.login;
      }

      // If authenticated and trying to access auth route
      if (isAuthenticated && isAuthRoute) {
        return Routes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: Routes.home,
        name: 'home',
        builder: (context, state) => const MainShell(),
      ),
      GoRoute(
        path: '/stocks/:symbol',
        name: 'stock-detail',
        builder: (context, state) {
          final symbol = state.pathParameters['symbol']!.toUpperCase();
          return StockDetailScreen(symbol: symbol);
        },
      ),
      GoRoute(
        path: Routes.debtAccounts,
        name: 'debt-accounts',
        builder: (context, state) => const DebtAccountsScreen(),
      ),
      GoRoute(
        path: Routes.brokerInbox,
        name: 'broker-inbox',
        builder: (context, state) => const BrokerInboxScreen(),
      ),
      GoRoute(
        path: Routes.signalHistory,
        name: 'signal-history',
        builder: (context, state) => const SignalHistoryScreen(),
      ),
      GoRoute(
        path: Routes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: Routes.resetPassword,
        name: 'reset-password',
        builder: (context, state) {
          // Get token from query parameters
          final token = state.uri.queryParameters['token'];
          return ResetPasswordScreen(token: token);
        },
      ),
      GoRoute(
        path: Routes.verifyEmail,
        name: 'verify-email',
        builder: (context, state) {
          // Get token from query parameters
          final token = state.uri.queryParameters['token'];
          return VerifyEmailScreen(token: token);
        },
      ),
      GoRoute(
        path: Routes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: Routes.search,
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: Routes.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: Routes.changePassword,
        name: 'change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: Routes.sessions,
        name: 'sessions',
        builder: (context, state) => const SessionsScreen(),
      ),
      GoRoute(
        path: Routes.backupRestore,
        name: 'backup-restore',
        builder: (context, state) => const BackupRestoreScreen(),
      ),
      GoRoute(
        path: Routes.security,
        name: 'security',
        builder: (context, state) => const SecurityScreen(),
      ),
      GoRoute(
        path: Routes.contact,
        name: 'contact',
        builder: (context, state) => const ContactScreen(),
      ),
      // About & Legal routes
      GoRoute(
        path: Routes.about,
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: Routes.faq,
        name: 'faq',
        builder: (context, state) => const FAQScreen(),
      ),
      GoRoute(
        path: Routes.terms,
        name: 'terms',
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: Routes.privacy,
        name: 'privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
      // Admin routes
      GoRoute(
        path: Routes.adminDashboard,
        name: 'admin-dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: Routes.adminUsers,
        name: 'admin-users',
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: Routes.adminAuditLogs,
        name: 'admin-audit-logs',
        builder: (context, state) => const AdminAuditLogsScreen(),
      ),
    ],
    // Custom error page for unknown routes
    errorBuilder: (context, state) => NotFoundScreen(
      path: state.uri.toString(),
    ),
  );
});
