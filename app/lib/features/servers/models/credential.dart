/// Credential type enumeration
enum CredentialType {
  sshPassword,
  sshKey,
  apiKey;

  factory CredentialType.fromString(String type) {
    switch (type) {
      case 'ssh_password':
        return CredentialType.sshPassword;
      case 'ssh_key':
        return CredentialType.sshKey;
      case 'api_key':
        return CredentialType.apiKey;
      default:
        return CredentialType.sshPassword;
    }
  }

  String toJsonString() {
    switch (this) {
      case CredentialType.sshPassword:
        return 'ssh_password';
      case CredentialType.sshKey:
        return 'ssh_key';
      case CredentialType.apiKey:
        return 'api_key';
    }
  }
}

/// Credential model (metadata only - secrets never sent from server)
class Credential {
  final String id;
  final String name;
  final CredentialType type;
  final String? username;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Credential({
    required this.id,
    required this.name,
    required this.type,
    this.username,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Credential.fromJson(Map<String, dynamic> json) {
    return Credential(
      id: json['id'] as String,
      name: json['name'] as String,
      type: CredentialType.fromString(json['type'] as String),
      username: json['username'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toJsonString(),
      'username': username,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Credential && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Credential(id: $id, name: $name, type: $type)';
}

/// Create SSH password credential request
class CreateSshPasswordCredentialRequest {
  final String name;
  final String username;
  final String password;

  const CreateSshPasswordCredentialRequest({
    required this.name,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': 'ssh_password',
      'username': username,
      'password': password,
    };
  }
}

/// Create SSH key credential request
class CreateSshKeyCredentialRequest {
  final String name;
  final String username;
  final String privateKey;
  final String? passphrase;

  const CreateSshKeyCredentialRequest({
    required this.name,
    required this.username,
    required this.privateKey,
    this.passphrase,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': 'ssh_key',
      'username': username,
      'private_key': privateKey,
      if (passphrase != null) 'passphrase': passphrase,
    };
  }
}
