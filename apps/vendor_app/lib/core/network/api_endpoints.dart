class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String register = '/auth/register';
  static const String loginEmail = '/auth/login/email';
  static const String loginPhone = '/auth/login/phone';
  static const String verifyOtp = '/auth/verify-otp';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  // Vendor Profile
  static const String vendorMe = '/vendors/me';
  static const String vendorRegister = '/vendors/register';

  // Vendor Products
  static const String vendorProducts = '/vendors/me/products';
  static String vendorProductById(String id) => '/vendors/me/products/$id';
  static String vendorProductStock(String id) =>
      '/vendors/me/products/$id/stock';

  // Vendor Services
  static const String vendorServices = '/vendors/me/services';
  static String vendorServiceById(String id) => '/vendors/me/services/$id';

  // Vendor Slots
  static const String vendorSlots = '/vendors/me/slots';
  static String vendorSlotById(String id) => '/vendors/me/slots/$id';

  // Vendor Orders
  static const String vendorOrders = '/vendors/me/orders';
  static String vendorOrderById(String id) => '/vendors/me/orders/$id';
  static String vendorOrderStatus(String id) =>
      '/vendors/me/orders/$id/status';

  // Vendor Bookings
  static const String vendorBookings = '/vendors/me/bookings';
  static String vendorBookingById(String id) => '/vendors/me/bookings/$id';
  static String vendorBookingStatus(String id) =>
      '/vendors/me/bookings/$id/status';

  // Vendor Wallet
  static const String vendorWallet = '/vendors/me/wallet';
  static const String vendorWalletTransactions =
      '/vendors/me/wallet/transactions';
  static const String vendorWalletPayout = '/vendors/me/wallet/payout';

  // Vendor Reviews
  static const String vendorReviews = '/vendors/me/reviews';
  static String vendorReviewReply(String id) =>
      '/vendors/me/reviews/$id/reply';

  // Vendor Documents
  static const String vendorDocuments = '/vendors/me/documents';

  // Vendor Dashboard
  static const String vendorDashboard = '/vendors/me/dashboard';
  static const String vendorToggleOnline = '/vendors/me/toggle-online';

  // Categories
  static const String productCategories = '/products/categories';
  static const String serviceCategories = '/services/categories';

  // Media
  static const String uploadMedia = '/media/upload';

  // Notifications
  static const String notifications = '/notifications';
  static String markNotificationRead(String id) => '/notifications/$id/read';
  static const String markAllNotificationsRead = '/notifications/read-all';
}
