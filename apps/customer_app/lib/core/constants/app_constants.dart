class AppConstants {
  AppConstants._();

  static const String baseUrl = 'http://localhost:8080/api/v1';
  static const String appName = 'Marketplace';

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';

  // Pagination
  static const int defaultPageSize = 20;

  // Timeouts
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Razorpay
  static const String razorpayKeyId = 'rzp_test_your_key_here';
}
