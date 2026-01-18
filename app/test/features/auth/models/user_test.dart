import 'package:flutter_test/flutter_test.dart';
import 'package:server_monitoring/features/auth/models/user.dart';

void main() {
  group('User', () {
    test('fromJson should parse valid user data', () {
      final json = {
        'id': 'test-id-123',
        'username': 'testuser',
        'email': 'test@example.com',
        'display_name': 'Test User',
        'role': 'admin',
        'is_active': true,
        'last_login_at': '2025-01-18T10:00:00Z',
        'created_at': '2025-01-01T00:00:00Z',
        'updated_at': '2025-01-18T10:00:00Z',
      };

      final user = User.fromJson(json);

      expect(user.id, 'test-id-123');
      expect(user.username, 'testuser');
      expect(user.email, 'test@example.com');
      expect(user.displayName, 'Test User');
      expect(user.role, 'admin');
      expect(user.isActive, true);
      expect(user.lastLoginAt, isNotNull);
    });

    test('fromJson should handle missing optional fields', () {
      final json = {
        'id': 'test-id-123',
        'username': 'testuser',
        'email': 'test@example.com',
        'role': 'viewer',
        'created_at': '2025-01-01T00:00:00Z',
        'updated_at': '2025-01-18T10:00:00Z',
      };

      final user = User.fromJson(json);

      expect(user.id, 'test-id-123');
      expect(user.username, 'testuser');
      expect(user.displayName, isNull);
      expect(user.lastLoginAt, isNull);
    });

    test('fromJson should throw FormatException for missing required fields', () {
      final jsonMissingId = {
        'username': 'testuser',
        'email': 'test@example.com',
      };

      expect(
        () => User.fromJson(jsonMissingId),
        throwsA(isA<FormatException>()),
      );

      final jsonMissingUsername = {
        'id': 'test-id-123',
        'email': 'test@example.com',
      };

      expect(
        () => User.fromJson(jsonMissingUsername),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromJson should handle null values in required fields', () {
      final json = {
        'id': null,
        'username': 'testuser',
        'email': 'test@example.com',
      };

      expect(
        () => User.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('AuthTokens', () {
    test('fromJson should parse valid token data', () {
      final json = {
        'access_token': 'test-access-token',
        'refresh_token': 'test-refresh-token',
        'expires_in': 3600,
        'token_type': 'Bearer',
      };

      final tokens = AuthTokens.fromJson(json);

      expect(tokens.accessToken, 'test-access-token');
      expect(tokens.refreshToken, 'test-refresh-token');
      expect(tokens.expiresIn, 3600);
      expect(tokens.tokenType, 'Bearer');
    });

    test('fromJson should use defaults for optional fields', () {
      final json = {
        'access_token': 'test-access-token',
        'refresh_token': 'test-refresh-token',
      };

      final tokens = AuthTokens.fromJson(json);

      expect(tokens.accessToken, 'test-access-token');
      expect(tokens.refreshToken, 'test-refresh-token');
      expect(tokens.expiresIn, 3600); // default
      expect(tokens.tokenType, 'Bearer'); // default
    });

    test('fromJson should throw FormatException for missing tokens', () {
      final jsonMissingAccess = {
        'refresh_token': 'test-refresh-token',
      };

      expect(
        () => AuthTokens.fromJson(jsonMissingAccess),
        throwsA(isA<FormatException>()),
      );

      final jsonMissingRefresh = {
        'access_token': 'test-access-token',
      };

      expect(
        () => AuthTokens.fromJson(jsonMissingRefresh),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('LoginResponse', () {
    test('fromJson should parse complete login response', () {
      final json = {
        'access_token': 'test-access-token',
        'refresh_token': 'test-refresh-token',
        'expires_in': 3600,
        'token_type': 'Bearer',
        'user': {
          'id': 'user-123',
          'username': 'admin',
          'email': 'admin@example.com',
          'display_name': 'Administrator',
          'role': 'admin',
          'is_active': true,
          'created_at': '2025-01-01T00:00:00Z',
          'updated_at': '2025-01-18T10:00:00Z',
        },
      };

      final response = LoginResponse.fromJson(json);

      expect(response.tokens.accessToken, 'test-access-token');
      expect(response.tokens.refreshToken, 'test-refresh-token');
      expect(response.user.id, 'user-123');
      expect(response.user.username, 'admin');
      expect(response.user.email, 'admin@example.com');
    });

    test('fromJson should throw FormatException if user is missing', () {
      final json = {
        'access_token': 'test-access-token',
        'refresh_token': 'test-refresh-token',
      };

      expect(
        () => LoginResponse.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromJson should throw FormatException if user is not a map', () {
      final json = {
        'access_token': 'test-access-token',
        'refresh_token': 'test-refresh-token',
        'user': 'not-a-map',
      };

      expect(
        () => LoginResponse.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromJson should throw FormatException if user data is invalid', () {
      final json = {
        'access_token': 'test-access-token',
        'refresh_token': 'test-refresh-token',
        'user': {
          'username': 'admin', // missing id
        },
      };

      expect(
        () => LoginResponse.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromJson should parse actual API response format', () {
      // This is the exact format returned by the backend /api/v1/auth/login endpoint
      final json = {
        'access_token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.example',
        'refresh_token': 'C80GBctgnS27md3RcmnAuXWwGSZsE32sQdTKz0EY01Y=',
        'expires_in': 900,
        'token_type': 'Bearer',
        'user': {
          'id': '8a4eb285-2aa6-4a5d-81f1-067b241c33ab',
          'username': 'admin',
          'email': 'admin@localhost',
          'display_name': 'Administrator',
          'role': 'admin',
          'is_active': true,
          'last_login_at': '2026-01-18T10:27:25.380768Z',
          'created_at': '2026-01-18T08:26:55.848243Z',
          'updated_at': '2026-01-18T10:27:25.380768Z',
        },
      };

      final response = LoginResponse.fromJson(json);

      expect(response.tokens.accessToken, contains('example'));
      expect(response.tokens.refreshToken, isNotEmpty);
      expect(response.tokens.expiresIn, 900);
      expect(response.tokens.tokenType, 'Bearer');
      expect(response.user.id, '8a4eb285-2aa6-4a5d-81f1-067b241c33ab');
      expect(response.user.username, 'admin');
      expect(response.user.email, 'admin@localhost');
      expect(response.user.displayName, 'Administrator');
      expect(response.user.role, 'admin');
      expect(response.user.isActive, true);
      expect(response.user.lastLoginAt, isNotNull);
    });
  });
}
