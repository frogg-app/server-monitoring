import '../../../core/api/api.dart';
import '../models/container.dart';

/// Repository for Docker container API operations
class ContainerRepository {
  final ApiClient _client;

  ContainerRepository(this._client);

  /// Get all containers for a server
  Future<List<DockerContainer>> getContainers(String serverId) async {
    final response = await _client.get(ApiEndpoints.serverContainers(serverId));
    final data = response.data as Map<String, dynamic>;
    final containers = data['containers'] as List<dynamic>;
    return containers
        .map((c) => DockerContainer.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  /// Get container stats
  Future<ContainerStats> getContainerStats(
    String serverId,
    String containerId,
  ) async {
    final response = await _client.get(
      '${ApiEndpoints.serverContainers(serverId)}/$containerId/stats',
    );
    final data = response.data as Map<String, dynamic>;
    return ContainerStats.fromJson(data['stats'] as Map<String, dynamic>);
  }

  /// Perform action on container
  Future<void> performAction(
    String serverId,
    String containerId,
    ContainerAction action,
  ) async {
    await _client.post(
      '${ApiEndpoints.serverContainers(serverId)}/$containerId/${action.name}',
    );
  }

  /// Get container logs
  Future<List<ContainerLog>> getContainerLogs(
    String serverId,
    String containerId, {
    int? tail,
    bool? follow,
  }) async {
    final response = await _client.get(
      '${ApiEndpoints.serverContainers(serverId)}/$containerId/logs',
      queryParameters: {
        if (tail != null) 'tail': tail.toString(),
        if (follow != null) 'follow': follow.toString(),
      },
    );
    final data = response.data as Map<String, dynamic>;
    final logs = data['logs'] as List<dynamic>;
    return logs
        .map((l) => ContainerLog.fromJson(l as Map<String, dynamic>))
        .toList();
  }
}
