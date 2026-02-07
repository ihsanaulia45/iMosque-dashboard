/// Route path constants for the admin dashboard
class RouteConstants {
  RouteConstants._();

  // Auth routes
  static const String login = '/login';

  // Main routes
  static const String dashboard = '/';
  static const String users = '/users';
  static const String userDetail = '/users/:id';
  static const String mosques = '/mosques';
  static const String mosqueDetail = '/mosques/:id';
  static const String mosqueNew = '/mosques/new';
  static const String mosqueEdit = '/mosques/:id/edit';
  static const String mosquePending = '/mosques/pending';
  static const String auditLogs = '/logs';
  static const String settings = '/settings';
  static const String profile = '/profile';

  // Helper methods for dynamic routes
  static String getUserDetailPath(String id) => '/users/$id';
  static String getMosqueDetailPath(String id) => '/mosques/$id';
  static String getMosqueEditPath(String id) => '/mosques/$id/edit';
}

/// Route names for navigation
class RouteNames {
  RouteNames._();

  static const String login = 'login';
  static const String dashboard = 'dashboard';
  static const String users = 'users';
  static const String userDetail = 'user-detail';
  static const String mosques = 'mosques';
  static const String mosqueDetail = 'mosque-detail';
  static const String mosqueNew = 'mosque-new';
  static const String mosqueEdit = 'mosque-edit';
  static const String mosquePending = 'mosque-pending';
  static const String auditLogs = 'audit-logs';
  static const String settings = 'settings';
  static const String profile = 'profile';
}
