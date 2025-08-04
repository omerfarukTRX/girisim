// ------------------------------
// lib/core/constants/app_constants.dart

class AppConstants {
  static const String appName = 'GirişİM';
  static const String appVersion = '1.0.0';

  // API
  static const Duration apiTimeout = Duration(seconds: 30);

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';

  // Pagination
  static const int pageSize = 20;

  // Cache
  static const Duration cacheExpiry = Duration(hours: 1);
}
