import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

// Auth states
abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

class AuthOtpSent extends AuthState {
  final String phone;
  final String verificationId;
  const AuthOtpSent({required this.phone, required this.verificationId});
}

// Repository provider
final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDatasource(apiClient: apiClient);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final datasource = ref.watch(authRemoteDatasourceProvider);
  return AuthRepositoryImpl(remoteDatasource: datasource);
});

// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final FlutterSecureStorage _storage;

  AuthNotifier({
    required AuthRepository repository,
    required FlutterSecureStorage storage,
  })  : _repository = repository,
        _storage = storage,
        super(const AuthInitial()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final token = await _storage.read(key: AppConstants.accessTokenKey);
      final userData = await _storage.read(key: AppConstants.userKey);

      if (token != null && token.isNotEmpty && userData != null) {
        final userMap = jsonDecode(userData) as Map<String, dynamic>;
        final user = UserModel.fromJson(userMap);
        state = AuthAuthenticated(user);
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (_) {
      state = const AuthUnauthenticated();
    }
  }

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final result = await _repository.loginWithEmail(
        email: email,
        password: password,
      );
      await _saveAuthData(result);
      state = AuthAuthenticated(result.user);
    } on Failure catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> sendOtp({required String phone}) async {
    state = const AuthLoading();
    try {
      final result = await _repository.sendOtp(phone: phone);
      state = AuthOtpSent(
        phone: phone,
        verificationId: result.verificationId,
      );
    } on Failure catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> verifyOtp({
    required String phone,
    required String otp,
    required String verificationId,
  }) async {
    state = const AuthLoading();
    try {
      final result = await _repository.verifyOtp(
        phone: phone,
        otp: otp,
        verificationId: verificationId,
      );
      await _saveAuthData(result);
      state = AuthAuthenticated(result.user);
    } on Failure catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {
      // Ignore server errors on logout
    }
    await _clearAuthData();
    state = const AuthUnauthenticated();
  }

  Future<void> refreshProfile() async {
    try {
      final user = await _repository.getProfile();
      final userModel = UserModel.fromEntity(user);
      await _storage.write(
        key: AppConstants.userKey,
        value: jsonEncode(userModel.toJson()),
      );
      state = AuthAuthenticated(user);
    } catch (_) {
      // Keep current state if refresh fails
    }
  }

  Future<void> _saveAuthData(AuthResult result) async {
    await _storage.write(
      key: AppConstants.accessTokenKey,
      value: result.accessToken,
    );
    await _storage.write(
      key: AppConstants.refreshTokenKey,
      value: result.refreshToken,
    );
    final userModel = UserModel.fromEntity(result.user);
    await _storage.write(
      key: AppConstants.userKey,
      value: jsonEncode(userModel.toJson()),
    );
  }

  Future<void> _clearAuthData() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.userKey);
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(repository: repository, storage: storage);
});
