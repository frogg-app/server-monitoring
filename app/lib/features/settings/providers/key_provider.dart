import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api.dart';

/// Generated SSH key pair
class GeneratedKeyPair {
  final String name;
  final String keyType;
  final String publicKey;
  final String privateKey;

  const GeneratedKeyPair({
    required this.name,
    required this.keyType,
    required this.publicKey,
    required this.privateKey,
  });

  factory GeneratedKeyPair.fromJson(Map<String, dynamic> json) {
    return GeneratedKeyPair(
      name: json['name'] as String,
      keyType: json['key_type'] as String,
      publicKey: json['public_key'] as String,
      privateKey: json['private_key'] as String,
    );
  }
}

/// Key service for generating SSH keys
class KeyService {
  final ApiClient _client;

  KeyService(this._client);

  /// Generate a new SSH key pair
  Future<GeneratedKeyPair> generateKey({
    String name = 'Generated Key',
    String keyType = 'ed25519',
  }) async {
    final response = await _client.post(
      ApiEndpoints.keysGenerate,
      data: {
        'name': name,
        'key_type': keyType,
      },
    );
    return GeneratedKeyPair.fromJson(response.data as Map<String, dynamic>);
  }
}

/// Key service provider
final keyServiceProvider = Provider<KeyService>((ref) {
  final client = ref.watch(apiClientProvider);
  return KeyService(client);
});
