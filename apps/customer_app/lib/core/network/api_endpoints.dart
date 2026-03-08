class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String register = '/auth/register';
  static const String loginEmail = '/auth/login/email';
  static const String loginPhone = '/auth/login/phone';
  static const String verifyOtp = '/auth/verify-otp';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  // Users
  static const String profile = '/users/me';
  static const String addresses = '/users/me/addresses';
  static String addressById(String id) => '/users/me/addresses/$id';

  // Vendors
  static const String vendors = '/vendors';
  static String vendorById(String id) => '/vendors/$id';
  static String vendorProducts(String id) => '/vendors/$id/products';
  static String vendorServices(String id) => '/vendors/$id/services';
  static String vendorReviews(String id) => '/vendors/$id/reviews';
  static const String nearbyVendors = '/vendors/nearby';

  // Products
  static const String products = '/products';
  static String productById(String id) => '/products/$id';
  static const String popularProducts = '/products/popular';
  static const String productCategories = '/products/categories';

  // Services
  static const String services = '/services';
  static String serviceById(String id) => '/services/$id';
  static String serviceSlots(String id) => '/services/$id/slots';
  static const String topServices = '/services/top';
  static const String serviceCategories = '/services/categories';

  // Orders
  static const String orders = '/orders';
  static String orderById(String id) => '/orders/$id';
  static String cancelOrder(String id) => '/orders/$id/cancel';

  // Bookings
  static const String bookings = '/bookings';
  static String bookingById(String id) => '/bookings/$id';
  static String cancelBooking(String id) => '/bookings/$id/cancel';

  // Payments
  static const String payments = '/payments';
  static const String createPaymentOrder = '/payments/create-order';
  static const String verifyPayment = '/payments/verify';

  // Reviews
  static const String reviews = '/reviews';
  static String reviewById(String id) => '/reviews/$id';

  // Notifications
  static const String notifications = '/notifications';
  static String markNotificationRead(String id) => '/notifications/$id/read';
  static const String markAllNotificationsRead = '/notifications/read-all';

  // Search
  static const String search = '/search';
  static const String searchSuggestions = '/search/suggestions';

  // Media
  static const String uploadMedia = '/media/upload';
}
