import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remoteDatasource;

  AuthRepositoryImpl({required AuthRemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  @override
  Future<AuthResult> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remoteDatasource.loginWithEmail(
        email: email,
        password: password,
      );
      return AuthResult(
        user: response.user,
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<OtpResult> sendOtp({required String phone}) async {
    try {
      final data = await _remoteDatasource.sendOtp(phone: phone);
      return OtpResult(
        verificationId: data['verificationId'] as String? ?? '',
        message: data['message'] as String? ?? 'OTP sent successfully',
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<AuthResult> verifyOtp({
    required String phone,
    required String otp,
    required String verificationId,
  }) async {
    try {
      final response = await _remoteDatasource.verifyOtp(
        phone: phone,
        otp: otp,
        verificationId: verificationId,
      );
      return AuthResult(
        user: response.user,
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<AuthResult> refreshToken({required String refreshToken}) async {
    try {
      final response =
          await _remoteDatasource.refreshToken(refreshToken: refreshToken);
      return AuthResult(
        user: response.user,
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<User> getProfile() async {
    try {
      return await _remoteDatasource.getProfile();
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    // Server-side logout is optional; tokens are cleared locally
  }
}
