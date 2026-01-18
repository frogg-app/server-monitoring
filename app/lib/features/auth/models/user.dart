/// User model representing an authenticated user
class User {
  final String id;
  final String username;
  final String email;
  final String? displayName;
  final String role;
  final bool isActive;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.username,
    required this.email,
    this.displayName,
    required this.role,
    required this.isActive,
    this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final username = json['username'];
    final email = json['email'];
    final role = json['role'];
    final createdAt = json['created_at'];
    final updatedAt = json['updated_at'];
    
    if (id == null || id is! String) {
      throw FormatException('Invalid or missing user id');
    }
    if (username == null || username is! String) {
      throw FormatException('Invalid or missing username');
    }
    
    return User(
      id: id,
      username: username,
      email: email is String ? email : '',
      displayName: json['display_name'] as String?,
      role: role is String ? role : 'user',
      isActive: json['is_active'] as bool? ?? true,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.tryParse(json['last_login_at'] as String)
          : null,
      createdAt: createdAt is String ? DateTime.parse(createdAt) : DateTime.now(),
      updatedAt: updatedAt is String ? DateTime.parse(updatedAt) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'display_name': displayName,
      'role': role,
      'is_active': isActive,
      'last_login_at': lastLoginAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? displayName,
    String? role,
    bool? isActive,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if user has admin role
  bool get isAdmin => role == 'admin';

  /// Check if user has editor role or higher
  bool get canEdit => role == 'admin' || role == 'editor';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'User(id: $id, username: $username, role: $role)';
}

/// Authentication tokens
class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String tokenType;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.tokenType,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    final accessToken = json['access_token'];
    final refreshToken = json['refresh_token'];
    final expiresIn = json['expires_in'];
    final tokenType = json['token_type'];
    
    if (accessToken == null || accessToken is! String) {
      throw FormatException('Invalid or missing access_token in response');
    }
    if (refreshToken == null || refreshToken is! String) {
      throw FormatException('Invalid or missing refresh_token in response');
    }
    
    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: expiresIn is int ? expiresIn : 3600,
      tokenType: tokenType is String ? tokenType : 'Bearer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': expiresIn,
      'token_type': tokenType,
    };
  }
}

/// Login response containing tokens and user info
class LoginResponse {
  final AuthTokens tokens;
  final User user;

  const LoginResponse({
    required this.tokens,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final userData = json['user'];
    if (userData == null || userData is! Map<String, dynamic>) {
      throw FormatException('Invalid or missing user data in login response');
    }
    
    return LoginResponse(
      tokens: AuthTokens.fromJson(json),
      user: User.fromJson(userData),
    );
  }
}
