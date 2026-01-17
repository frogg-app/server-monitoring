import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/api/api.dart';
import '../models/user.dart';

/// Keys for secure storage
class AuthStorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userData = 'user_data';
}

/// Auth state
sealed class AuthState {
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
  final String? message;
  const AuthUnauthenticated([this.message]);
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

/// Auth notifier for managing authentication state
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage;

  AuthNotifier(this._apiClient, this._storage) : super(const AuthInitial()) {
    _checkAuthStatus();
  }

  /// Check if user is already authenticated
  Future<void> _checkAuthStatus() async {
    state = const AuthLoading();

    try {
      final accessToken = await _storage.read(key: AuthStorageKeys.accessToken);
      final refreshToken = await _storage.read(key: AuthStorageKeys.refreshToken);

      if (accessToken == null || refreshToken == null) {
        state = const AuthUnauthenticated();
        return;
      }

      _apiClient.setAccessToken(accessToken);
      _apiClient.setRefreshToken(refreshToken);

      // Verify token by fetching current user
      final response = await _apiClient.get(ApiEndpoints.me);
      final user = User.fromJson(response.data as Map<String, dynamic>);
      state = AuthAuthenticated(user);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Token expired or invalid
        await _clearStoredAuth();
        state = const AuthUnauthenticated();
      } else {
        state = AuthError(ApiException.fromDioError(e).message);
      }
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  /// Login with username and password
  Future<void> login(String username, String password) async {
    state = const AuthLoading();

    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {
          'username': username,
          'password': password,
        },
      );

      final loginResponse = LoginResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      // Store tokens
      await _storage.write(
        key: AuthStorageKeys.accessToken,
        value: loginResponse.tokens.accessToken,
      );
      await _storage.write(
        key: AuthStorageKeys.refreshToken,
        value: loginResponse.tokens.refreshToken,
      );

      // Set tokens in API client
      _apiClient.setAccessToken(loginResponse.tokens.accessToken);
      _apiClient.setRefreshToken(loginResponse.tokens.refreshToken);

      state = AuthAuthenticated(loginResponse.user);
    } on DioException catch (e) {
      state = AuthError(ApiException.fromDioError(e).message);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  /// Logout the current user
  Future<void> logout() async {
    try {
      final refreshToken = await _storage.read(key: AuthStorageKeys.refreshToken);
      if (refreshToken != null) {
        await _apiClient.post(
          ApiEndpoints.logout,
          data: {'refresh_token': refreshToken},
        );
      }
    } catch (_) {
      // Ignore errors during logout
    }

    await _clearStoredAuth();
    state = const AuthUnauthenticated();
  }

  /// Clear stored authentication data
  Future<void> _clearStoredAuth() async {
    await _storage.delete(key: AuthStorageKeys.accessToken);
    await _storage.delete(key: AuthStorageKeys.refreshToken);
    await _storage.delete(key: AuthStorageKeys.userData);
    _apiClient.clearTokens();
  }

  /// Refresh the current user data
  Future<void> refreshUser() async {
    if (state is! AuthAuthenticated) return;

    try {
      final response = await _apiClient.get(ApiEndpoints.me);
      final user = User.fromJson(response.data as Map<String, dynamic>);
      state = AuthAuthenticated(user);
    } catch (_) {
      // Keep current state on error
    }
  }
}

/// Provider for auth state
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(apiClient, storage);
});

/// Provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState is AuthAuthenticated;
});

/// Provider to get current user (nullable)
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is AuthAuthenticated) {
    return authState.user;
  }
  return null;
});
