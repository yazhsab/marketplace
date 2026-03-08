import '../entities/user.dart';

abstract class AuthRepository {
  Future<AuthResult> loginWithEmail({
    required String email,
    required String password,
  });

  Future<OtpResult> sendOtp({required String phone});

  Future<AuthResult> verifyOtp({
    required String phone,
    required String otp,
    required String verificationId,
  });

  Future<AuthResult> refreshToken({required String refreshToken});

  Future<User> getProfile();

  Future<void> logout();
}

class AuthResult {
  final User user;
  final String accessToken;
  final String refreshToken;

  const AuthResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });
}

class OtpResult {
  final String verificationId;
  final String message;

  const OtpResult({
    required this.verificationId,
    required this.message,
  });
}
