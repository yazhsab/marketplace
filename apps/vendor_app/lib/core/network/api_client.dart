import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';
import '../error/failures.dart';
import 'api_endpoints.dart';

class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  ApiClient({
    required Dio dio,
    required FlutterSecureStorage storage,
  })  : _dio = dio,
        _storage = storage {
    _dio.options = BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout:
          const Duration(milliseconds: AppConstants.connectTimeout),
      receiveTimeout:
          const Duration(milliseconds: AppConstants.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    _dio.interceptors.addAll([
      _authInterceptor(),
      _errorInterceptor(),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print('[API] $obj'),
      ),
    ]);
  }

  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.accessTokenKey);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    );
  }

  InterceptorsWrapper _errorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            final retryResponse = await _retryRequest(error.requestOptions);
            return handler.resolve(retryResponse);
          } else {
            await _clearTokens();
            return handler.reject(error);
          }
        }
        handler.next(error);
      },
    );
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken =
          await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await Dio().post(
        '${AppConstants.baseUrl}${ApiEndpoints.refreshToken}',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        await _storage.write(
          key: AppConstants.accessTokenKey,
          value: data['accessToken'],
        );
        await _storage.write(
          key: AppConstants.refreshTokenKey,
          value: data['refreshToken'],
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<Response> _retryRequest(RequestOptions requestOptions) async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    requestOptions.headers['Authorization'] = 'Bearer $token';
    return _dio.fetch(requestOptions);
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.userKey);
  }

  Failure _mapDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkFailure(
            'No internet connection. Please try again.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        final message = error.response?.data?['message'] as String? ??
            'Something went wrong';
        if (statusCode == 401 || statusCode == 403) {
          return AuthFailure(message);
        }
        return ServerFailure(message, statusCode: statusCode);
      case DioExceptionType.cancel:
        return const ServerFailure('Request cancelled');
      default:
        return const ServerFailure('An unexpected error occurred');
    }
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(path,
          queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(path,
          data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(path,
          data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch(path,
          data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(path,
          data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Response> uploadFile(
    String path, {
    required FormData formData,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      return await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }
}
