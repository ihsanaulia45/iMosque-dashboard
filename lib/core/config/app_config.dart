/// Application configuration constants
class AppConfig {
  AppConfig._();

  /// App name
  static const String appName = 'iMosque Admin';

  /// App version
  static const String appVersion = '1.0.0';

  /// Session timeout in minutes
  static const int sessionTimeoutMinutes = 30;

  /// Session warning before timeout in minutes
  static const int sessionWarningMinutes = 5;

  /// Pagination default page size
  static const int defaultPageSize = 10;

  /// Pagination page size options
  static const List<int> pageSizeOptions = [10, 25, 50, 100];

  /// Date format for display
  static const String dateFormat = 'dd MMM yyyy';

  /// DateTime format for display
  static const String dateTimeFormat = 'dd MMM yyyy HH:mm';

  /// Time format for display
  static const String timeFormat = 'HH:mm';

  /// Audit log retention days
  static const int auditLogRetentionDays = 90;

  /// Debounce duration for search in milliseconds
  static const int searchDebounceMs = 500;
}
