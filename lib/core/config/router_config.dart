import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../constants/route_constants.dart';
import '../../data/providers/auth_provider.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/dashboard/dashboard_screen.dart';
import '../../presentation/users/user_list_screen.dart';
import '../../presentation/users/user_detail_screen.dart';
import '../../presentation/mosques/mosque_list_screen.dart';
import '../../presentation/mosques/mosque_detail_screen.dart';
import '../../presentation/mosques/mosque_form_screen.dart';
import '../../presentation/mosques/pending_mosques_screen.dart';
import '../../presentation/audit_logs/audit_log_screen.dart';
import '../../presentation/settings/settings_screen.dart';
import '../../presentation/profile/profile_screen.dart';
import '../../presentation/shared/layouts/admin_layout.dart';

/// Router configuration for admin dashboard
class RouterConfig {
  RouterConfig._();

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');
  static final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  /// Create router instance
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: RouteConstants.dashboard,
      debugLogDiagnostics: true,
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isLoginRoute = state.matchedLocation == RouteConstants.login;

        // If not authenticated and not on login page, redirect to login
        if (!isAuthenticated && !isLoginRoute) {
          return RouteConstants.login;
        }

        // If authenticated and on login page, redirect to dashboard
        if (isAuthenticated && isLoginRoute) {
          return RouteConstants.dashboard;
        }

        // Check if user has dashboard access
        if (isAuthenticated && !authProvider.hasDashboardAccess) {
          // User is authenticated but doesn't have admin/developer role
          authProvider.signOut();
          return RouteConstants.login;
        }

        return null;
      },
      routes: [
        // Login route (outside shell)
        GoRoute(
          path: RouteConstants.login,
          name: RouteNames.login,
          builder: (context, state) => const LoginScreen(),
        ),

        // Main routes (inside shell with layout)
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) => AdminLayout(child: child),
          routes: [
            // Dashboard
            GoRoute(
              path: RouteConstants.dashboard,
              name: RouteNames.dashboard,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: DashboardScreen(),
              ),
            ),

            // Users
            GoRoute(
              path: RouteConstants.users,
              name: RouteNames.users,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: UserListScreen(),
              ),
              routes: [
                GoRoute(
                  path: ':id',
                  name: RouteNames.userDetail,
                  builder: (context, state) {
                    final userId = state.pathParameters['id']!;
                    return UserDetailScreen(userId: userId);
                  },
                ),
              ],
            ),

            // Mosques
            GoRoute(
              path: RouteConstants.mosques,
              name: RouteNames.mosques,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: MosqueListScreen(),
              ),
              routes: [
                GoRoute(
                  path: 'new',
                  name: RouteNames.mosqueNew,
                  builder: (context, state) => const MosqueFormScreen(),
                ),
                GoRoute(
                  path: 'pending',
                  name: RouteNames.mosquePending,
                  builder: (context, state) => const PendingMosquesScreen(),
                ),
                GoRoute(
                  path: ':id',
                  name: RouteNames.mosqueDetail,
                  builder: (context, state) {
                    final mosqueId = state.pathParameters['id']!;
                    return MosqueDetailScreen(mosqueId: mosqueId);
                  },
                  routes: [
                    GoRoute(
                      path: 'edit',
                      name: RouteNames.mosqueEdit,
                      builder: (context, state) {
                        final mosqueId = state.pathParameters['id']!;
                        return MosqueFormScreen(mosqueId: mosqueId);
                      },
                    ),
                  ],
                ),
              ],
            ),

            // Audit Logs
            GoRoute(
              path: RouteConstants.auditLogs,
              name: RouteNames.auditLogs,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: AuditLogScreen(),
              ),
            ),

            // Settings
            GoRoute(
              path: RouteConstants.settings,
              name: RouteNames.settings,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: SettingsScreen(),
              ),
            ),

            // Profile
            GoRoute(
              path: RouteConstants.profile,
              name: RouteNames.profile,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ProfileScreen(),
              ),
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Page not found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                state.error?.toString() ?? 'Unknown error',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(RouteConstants.dashboard),
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
