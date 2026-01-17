import '../../../core/api/api.dart';
import '../models/models.dart';

/// Repository for server API operations
class ServerRepository {
  final ApiClient _client;

  ServerRepository(this._client);

  /// Get all servers
  Future<List<Server>> getServers() async {
    final response = await _client.get(ApiEndpoints.servers);
    final data = response.data as Map<String, dynamic>;
    final servers = data['servers'] as List<dynamic>;
    return servers
        .map((s) => Server.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  /// Get servers with metrics summary
  Future<List<ServerWithMetrics>> getServersWithMetrics() async {
    final response = await _client.get(
      ApiEndpoints.servers,
      queryParameters: {'include_metrics': 'true'},
    );
    final data = response.data as Map<String, dynamic>;
    final servers = data['servers'] as List<dynamic>;
    return servers
        .map((s) => ServerWithMetrics.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  /// Get a single server by ID
  Future<Server> getServer(String id) async {
    final response = await _client.get(ApiEndpoints.server(id));
    final data = response.data as Map<String, dynamic>;
    return Server.fromJson(data['server'] as Map<String, dynamic>);
  }

  /// Create a new server
  Future<Server> createServer(CreateServerRequest request) async {
    final response = await _client.post(
      ApiEndpoints.servers,
      data: request.toJson(),
    );
    final data = response.data as Map<String, dynamic>;
    return Server.fromJson(data['server'] as Map<String, dynamic>);
  }

  /// Update a server
  Future<Server> updateServer(String id, UpdateServerRequest request) async {
    final response = await _client.patch(
      ApiEndpoints.server(id),
      data: request.toJson(),
    );
    final data = response.data as Map<String, dynamic>;
    return Server.fromJson(data['server'] as Map<String, dynamic>);
  }

  /// Delete a server
  Future<void> deleteServer(String id) async {
    await _client.delete(ApiEndpoints.server(id));
  }

  /// Test server connection
  Future<bool> testConnection(String id) async {
    try {
      final response = await _client.post('${ApiEndpoints.server(id)}/test');
      final data = response.data as Map<String, dynamic>;
      return data['success'] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get server credentials
  Future<List<Credential>> getServerCredentials(String serverId) async {
    final response = await _client.get(ApiEndpoints.serverCredentials(serverId));
    final data = response.data as Map<String, dynamic>;
    final credentials = data['credentials'] as List<dynamic>;
    return credentials
        .map((c) => Credential.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  /// Create SSH password credential for server
  Future<Credential> createSshPasswordCredential(
    String serverId,
    CreateSshPasswordCredentialRequest request,
  ) async {
    final response = await _client.post(
      ApiEndpoints.serverCredentials(serverId),
      data: request.toJson(),
    );
    final data = response.data as Map<String, dynamic>;
    return Credential.fromJson(data['credential'] as Map<String, dynamic>);
  }

  /// Create SSH key credential for server
  Future<Credential> createSshKeyCredential(
    String serverId,
    CreateSshKeyCredentialRequest request,
  ) async {
    final response = await _client.post(
      ApiEndpoints.serverCredentials(serverId),
      data: request.toJson(),
    );
    final data = response.data as Map<String, dynamic>;
    return Credential.fromJson(data['credential'] as Map<String, dynamic>);
  }

  /// Add credential to server
  Future<void> addCredentialToServer(String serverId, String credentialId) async {
    await _client.post(
      ApiEndpoints.serverCredentials(serverId),
      data: {'credential_id': credentialId},
    );
  }

  /// Remove credential from server
  Future<void> removeCredentialFromServer(String serverId, String credentialId) async {
    await _client.delete('${ApiEndpoints.serverCredentials(serverId)}/$credentialId');
  }
}
