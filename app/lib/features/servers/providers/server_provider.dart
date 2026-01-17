import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api.dart';
import '../models/models.dart';
import '../repositories/server_repository.dart';

/// Server repository provider
final serverRepositoryProvider = Provider<ServerRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ServerRepository(client);
});

/// Server list state
sealed class ServersState {
  const ServersState();
}

class ServersLoading extends ServersState {
  const ServersLoading();
}

class ServersLoaded extends ServersState {
  final List<ServerWithMetrics> servers;

  const ServersLoaded(this.servers);

  List<ServerWithMetrics> get onlineServers =>
      servers.where((s) => s.status == ServerStatus.online).toList();

  List<ServerWithMetrics> get offlineServers =>
      servers.where((s) => s.status == ServerStatus.offline).toList();

  List<ServerWithMetrics> get warningServers =>
      servers.where((s) => s.status == ServerStatus.warning).toList();

  int get totalCount => servers.length;
  int get onlineCount => onlineServers.length;
  int get offlineCount => offlineServers.length;
}

class ServersError extends ServersState {
  final String message;

  const ServersError(this.message);
}

/// Server list notifier
class ServersNotifier extends StateNotifier<ServersState> {
  final ServerRepository _repository;

  ServersNotifier(this._repository) : super(const ServersLoading()) {
    loadServers();
  }

  Future<void> loadServers() async {
    state = const ServersLoading();
    try {
      final servers = await _repository.getServersWithMetrics();
      state = ServersLoaded(servers);
    } catch (e) {
      state = ServersError(e.toString());
    }
  }

  Future<void> refresh() => loadServers();

  Future<Server> createServer(CreateServerRequest request) async {
    final server = await _repository.createServer(request);
    await loadServers(); // Refresh list
    return server;
  }

  Future<void> deleteServer(String id) async {
    await _repository.deleteServer(id);
    await loadServers(); // Refresh list
  }
}

/// Server list provider
final serversProvider =
    StateNotifierProvider<ServersNotifier, ServersState>((ref) {
  final repository = ref.watch(serverRepositoryProvider);
  return ServersNotifier(repository);
});

/// Single server state
sealed class ServerDetailState {
  const ServerDetailState();
}

class ServerDetailLoading extends ServerDetailState {
  const ServerDetailLoading();
}

class ServerDetailLoaded extends ServerDetailState {
  final Server server;

  const ServerDetailLoaded(this.server);
}

class ServerDetailError extends ServerDetailState {
  final String message;

  const ServerDetailError(this.message);
}

/// Single server notifier
class ServerDetailNotifier extends StateNotifier<ServerDetailState> {
  final ServerRepository _repository;
  final String serverId;

  ServerDetailNotifier(this._repository, this.serverId)
      : super(const ServerDetailLoading()) {
    loadServer();
  }

  Future<void> loadServer() async {
    state = const ServerDetailLoading();
    try {
      final server = await _repository.getServer(serverId);
      state = ServerDetailLoaded(server);
    } catch (e) {
      state = ServerDetailError(e.toString());
    }
  }

  Future<void> updateServer(UpdateServerRequest request) async {
    try {
      final server = await _repository.updateServer(serverId, request);
      state = ServerDetailLoaded(server);
    } catch (e) {
      state = ServerDetailError(e.toString());
    }
  }

  Future<bool> testConnection() async {
    return await _repository.testConnection(serverId);
  }
}

/// Server detail provider (family for multiple servers)
final serverDetailProvider = StateNotifierProvider.family<ServerDetailNotifier,
    ServerDetailState, String>((ref, serverId) {
  final repository = ref.watch(serverRepositoryProvider);
  return ServerDetailNotifier(repository, serverId);
});

/// Selected server provider for navigation
final selectedServerIdProvider = StateProvider<String?>((ref) => null);

/// Computed provider for selected server
final selectedServerProvider = Provider<ServerWithMetrics?>((ref) {
  final selectedId = ref.watch(selectedServerIdProvider);
  if (selectedId == null) return null;

  final serversState = ref.watch(serversProvider);
  if (serversState is ServersLoaded) {
    return serversState.servers
        .where((s) => s.id == selectedId)
        .firstOrNull;
  }
  return null;
});
