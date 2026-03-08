class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String register = '/auth/register';
  static const String loginEmail = '/auth/login/email';
  static const String loginPhone = '/auth/login/phone';
  static const String verifyOtp = '/auth/verify-otp';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  // Delivery Partner Registration & Profile
  static const String deliveryRegister = '/delivery/register';
  static const String deliveryProfile = '/delivery/me/profile';
  static const String deliveryUpdateLocation = '/delivery/me/location';
  static const String deliveryAvailability = '/delivery/me/availability';
  static const String deliveryShift = '/delivery/me/shift';

  // Delivery Assignments
  static const String deliveryAssignments = '/delivery/me/assignments';
  static String deliveryAssignmentById(String id) =>
      '/delivery/me/assignments/$id';
  static String acceptAssignment(String id) =>
      '/delivery/me/assignments/$id/accept';
  static String rejectAssignment(String id) =>
      '/delivery/me/assignments/$id/reject';
  static String pickupAssignment(String id) =>
      '/delivery/me/assignments/$id/pickup';
  static String deliverAssignment(String id) =>
      '/delivery/me/assignments/$id/deliver';

  // Earnings
  static const String deliveryEarnings = '/delivery/me/earnings';
  static const String deliveryEarningsHistory =
      '/delivery/me/earnings/history';
  static const String deliveryStats = '/delivery/me/stats';

  // Notifications
  static const String notifications = '/notifications';
  static String markNotificationRead(String id) => '/notifications/$id/read';
  static const String markAllNotificationsRead = '/notifications/read-all';

  // Media
  static const String uploadMedia = '/media/upload';
}
