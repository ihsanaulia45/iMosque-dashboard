/// API and database table constants
class ApiConstants {
  ApiConstants._();

  // Table names
  static const String profilesTable = 'profiles';
  static const String mosquesTable = 'mosques';
  static const String auditLogsTable = 'audit_logs';
  static const String systemSettingsTable = 'system_settings';
  static const String mosqueImagesTable = 'mosque_images';
  static const String mosqueFacilitiesTable = 'mosque_facilities';
  static const String mosqueContactsTable = 'mosque_contacts';
  static const String mosqueImamsTable = 'mosque_imams';
  static const String mosqueReviewsTable = 'mosque_reviews';

  // Stored procedures / RPC
  static const String getCurrentUserRole = 'get_current_user_role';
  static const String isAdminOrDeveloper = 'is_admin_or_developer';
}

/// User roles enum
enum UserRole {
  user('user'),
  ustadz('ustadz'),
  operator('operator'),
  admin('admin'),
  developer('developer');

  final String value;
  const UserRole(this.value);

  /// Get display name
  String get displayName {
    switch (this) {
      case UserRole.user:
        return 'User';
      case UserRole.ustadz:
        return 'Ustadz';
      case UserRole.operator:
        return 'Operator';
      case UserRole.admin:
        return 'Admin';
      case UserRole.developer:
        return 'Developer';
    }
  }

  /// Check if role has dashboard access
  bool get hasDashboardAccess {
    return this == UserRole.admin || this == UserRole.developer;
  }

  /// Check if role is developer
  bool get isDeveloper => this == UserRole.developer;

  /// Check if role is admin
  bool get isAdmin => this == UserRole.admin;

  /// Parse from string
  static UserRole fromString(String? value) {
    if (value == null) return UserRole.user;
    return UserRole.values.firstWhere(
      (role) => role.value == value.toLowerCase(),
      orElse: () => UserRole.user,
    );
  }
}

/// Audit log action types
class AuditAction {
  AuditAction._();

  // User actions
  static const String userLogin = 'user.login';
  static const String userLogout = 'user.logout';
  static const String userBlock = 'user.block';
  static const String userUnblock = 'user.unblock';
  static const String userRoleChange = 'user.role_change';

  // Mosque actions
  static const String mosqueCreate = 'mosque.create';
  static const String mosqueUpdate = 'mosque.update';
  static const String mosqueVerify = 'mosque.verify';
  static const String mosqueReject = 'mosque.reject';
  static const String mosqueActivate = 'mosque.activate';
  static const String mosqueDeactivate = 'mosque.deactivate';

  // Settings actions
  static const String settingUpdate = 'setting.update';
}

/// Audit log target types
class AuditTargetType {
  AuditTargetType._();

  static const String user = 'user';
  static const String mosque = 'mosque';
  static const String setting = 'setting';
}
