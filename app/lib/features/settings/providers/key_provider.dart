import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api.dart';

/// Generated SSH key pair
class GeneratedKeyPair {
  final String? id;
  final String name;
  final String keyType;
  final String publicKey;
  final String privateKey;
  final String fingerprint;
  final bool stored;

  const GeneratedKeyPair({
    this.id,
    required this.name,
    required this.keyType,
    required this.publicKey,
    required this.privateKey,
    required this.fingerprint,
    this.stored = false,
  });

  factory GeneratedKeyPair.fromJson(Map<String, dynamic> json) {
    return GeneratedKeyPair(
      id: json['id'] as String?,
      name: json['name'] as String,
      keyType: json['key_type'] as String,
      publicKey: json['public_key'] as String,
      privateKey: json['private_key'] as String? ?? '',
      fingerprint: json['fingerprint'] as String? ?? '',
      stored: json['stored'] as bool? ?? false,
    );
  }
}

/// Stored SSH key (without private key)
class SSHKey {
  final String id;
  final String name;
  final String keyType;
  final String publicKey;
  final String fingerprint;
  final bool hasPrivateKey;
  final DateTime createdAt;

  const SSHKey({
    required this.id,
    required this.name,
    required this.keyType,
    required this.publicKey,
    required this.fingerprint,
    required this.hasPrivateKey,
    required this.createdAt,
  });

  factory SSHKey.fromJson(Map<String, dynamic> json) {
    return SSHKey(
      id: json['id'] as String,
      name: json['name'] as String,
      keyType: json['key_type'] as String,
      publicKey: json['public_key'] as String,
      fingerprint: json['fingerprint'] as String,
      hasPrivateKey: json['has_private_key'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Key deployment result
class KeyDeployment {
  final String id;
  final String serverId;
  final String keyId;
  final DateTime? deployedAt;
  final String status;
  final String? message;

  const KeyDeployment({
    required this.id,
    required this.serverId,
    required this.keyId,
    this.deployedAt,
    required this.status,
    this.message,
  });

  factory KeyDeployment.fromJson(Map<String, dynamic> json) {
    return KeyDeployment(
      id: json['id'] as String,
      serverId: json['server_id'] as String,
      keyId: json['key_id'] as String,
      deployedAt: json['deployed_at'] != null
          ? DateTime.parse(json['deployed_at'] as String)
          : null,
      status: json['deploy_status'] as String,
      message: json['deploy_message'] as String?,
    );
  }
}

/// Key service for managing SSH keys
class KeyService {
  final ApiClient _client;

  KeyService(this._client);

  /// Generate a new SSH key pair
  Future<GeneratedKeyPair> generateKey({
    String name = 'Generated Key',
    String keyType = 'ed25519',
    bool store = false,
  }) async {
    final response = await _client.post(
      ApiEndpoints.keysGenerate,
      data: {
        'name': name,
        'key_type': keyType,
        'store': store,
      },
    );
    return GeneratedKeyPair.fromJson(response.data as Map<String, dynamic>);
  }

  /// List all stored SSH keys
  Future<List<SSHKey>> listKeys() async {
    final response = await _client.get('/keys');
    final keys = response.data['keys'] as List<dynamic>;
    return keys
        .map((k) => SSHKey.fromJson(k as Map<String, dynamic>))
        .toList();
  }

  /// Get a specific key by ID
  Future<SSHKey> getKey(String id) async {
    final response = await _client.get('/keys/$id');
    return SSHKey.fromJson(response.data as Map<String, dynamic>);
  }

  /// Delete a key by ID
  Future<void> deleteKey(String id) async {
    await _client.delete('/keys/$id');
  }

  /// Deploy a key to a server
  Future<KeyDeployment> deployKey({
    required String serverId,
    required String keyId,
    String? username,
    String? password,
  }) async {
    final response = await _client.post(
      '/servers/$serverId/keys/$keyId/deploy',
      data: {
        if (username != null) 'username': username,
        if (password != null) 'password': password,
      },
    );
    return KeyDeployment.fromJson({
      'id': '',
      'server_id': serverId,
      'key_id': keyId,
      'deploy_status': response.data['status'] as String,
      'deploy_message': response.data['message'] as String?,
    });
  }

  /// List deployments for a key
  Future<List<KeyDeployment>> listDeployments(String keyId) async {
    final response = await _client.get('/keys/$keyId/deployments');
    final deployments = response.data['deployments'] as List<dynamic>;
    return deployments
        .map((d) => KeyDeployment.fromJson(d as Map<String, dynamic>))
        .toList();
  }
}

/// Key service provider
final keyServiceProvider = Provider<KeyService>((ref) {
  final client = ref.watch(apiClientProvider);
  return KeyService(client);
});

/// Keys list provider
final keysListProvider = FutureProvider<List<SSHKey>>((ref) async {
  final keyService = ref.watch(keyServiceProvider);
  return keyService.listKeys();
});
