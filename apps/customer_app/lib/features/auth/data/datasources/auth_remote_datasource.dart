import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

class AuthRemoteDatasource {
  final ApiClient _apiClient;

  AuthRemoteDatasource({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<AuthResponseModel> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.register,
      data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'role': 'customer',
      },
    );
    return AuthResponseModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<AuthResponseModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.loginEmail,
      data: {
        'email': email,
        'password': password,
      },
    );
    return AuthResponseModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<Map<String, dynamic>> sendOtp({required String phone}) async {
    final response = await _apiClient.post(
      ApiEndpoints.loginPhone,
      data: {'phone': phone},
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<AuthResponseModel> verifyOtp({
    required String phone,
    required String otp,
    required String verificationId,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.verifyOtp,
      data: {
        'phone': phone,
        'otp': otp,
        'verificationId': verificationId,
      },
    );
    return AuthResponseModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<AuthResponseModel> refreshToken({required String refreshToken}) async {
    final response = await _apiClient.post(
      ApiEndpoints.refreshToken,
      data: {'refreshToken': refreshToken},
    );
    return AuthResponseModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<UserModel> getProfile() async {
    final response = await _apiClient.get(ApiEndpoints.profile);
    return UserModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }
}
