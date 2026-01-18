import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_config.dart';

/// Provider for the API client
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Provider for secure storage
/// On web, this uses localStorage with encryption
/// On mobile, it uses platform-specific secure storage
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

/// API client for making HTTP requests
class ApiClient {
  late final Dio _dio;
  String? _accessToken;
  String? _refreshToken;

  ApiClient({String? baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiConfig.defaultBaseUrl,
        connectTimeout: const Duration(seconds: ApiConfig.timeoutSeconds),
        receiveTimeout: const Duration(seconds: ApiConfig.timeoutSeconds),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add logging interceptor
    if (ApiConfig.enableLogging) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
        ),
      );
    }

    // Add auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  /// Set the access token
  void setAccessToken(String? token) {
    _accessToken = token;
  }

  /// Set the refresh token
  void setRefreshToken(String? token) {
    _refreshToken = token;
  }

  /// Get the current access token
  String? get accessToken => _accessToken;

  /// Get the current refresh token
  String? get refreshToken => _refreshToken;

  /// Clear all tokens
  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  /// Handle request to add auth header
  void _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    if (_accessToken != null) {
      options.headers[ApiConfig.authHeader] =
          '${ApiConfig.bearerPrefix} $_accessToken';
    }
    handler.next(options);
  }

  /// Handle errors, including token refresh
  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (error.response?.statusCode == 401 && _refreshToken != null) {
      // Try to refresh the token
      try {
        final response = await _dio.post(
          ApiEndpoints.refresh,
          data: {'refresh_token': _refreshToken},
          options: Options(
            headers: {}, // Don't send expired access token
          ),
        );

        if (response.statusCode == 200) {
          final data = response.data as Map<String, dynamic>;
          _accessToken = data['access_token'] as String?;
          _refreshToken = data['refresh_token'] as String?;

          // Retry the original request
          final retryResponse = await _dio.request(
            error.requestOptions.path,
            options: Options(
              method: error.requestOptions.method,
              headers: {
                ...error.requestOptions.headers,
                ApiConfig.authHeader: '${ApiConfig.bearerPrefix} $_accessToken',
              },
            ),
            data: error.requestOptions.data,
            queryParameters: error.requestOptions.queryParameters,
          );

          return handler.resolve(retryResponse);
        }
      } catch (_) {
        // Refresh failed, clear tokens
        clearTokens();
      }
    }
    handler.next(error);
  }

  /// Make a GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Make a POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Make a PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Make a PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Make a DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}

/// Exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  factory ApiException.fromDioError(DioException error) {
    String message = 'An error occurred';
    int? statusCode = error.response?.statusCode;

    if (error.response?.data != null && error.response?.data is Map) {
      final data = error.response?.data as Map;
      message = data['error']?.toString() ?? message;
    } else {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message = 'Connection timeout';
          break;
        case DioExceptionType.connectionError:
          message = 'No internet connection';
          break;
        case DioExceptionType.badResponse:
          message = 'Server error (${statusCode ?? 'unknown'})';
          break;
        default:
          message = error.message ?? 'Unknown error';
      }
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      data: error.response?.data,
    );
  }

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}
