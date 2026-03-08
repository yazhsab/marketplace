class AppConstants {
  AppConstants._();

  static const String baseUrl = 'http://localhost:8080/api/v1';
  static const String appName = 'Marketplace Delivery';

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String partnerKey = 'partner_data';

  // Pagination
  static const int defaultPageSize = 20;

  // Timeouts
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Location
  static const int locationUpdateIntervalMs = 30000;
  static const double locationDistanceFilterMeters = 50;
}
