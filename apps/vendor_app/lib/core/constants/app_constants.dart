class AppConstants {
  AppConstants._();

  static const String baseUrl = 'http://localhost:8080/api/v1';
  static const String appName = 'Marketplace Vendor';

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String vendorKey = 'vendor_data';

  // Pagination
  static const int defaultPageSize = 20;

  // Timeouts
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Image
  static const double maxImageWidth = 1024;
  static const double maxImageHeight = 1024;
  static const int imageQuality = 80;
  static const int maxProductImages = 5;
}
