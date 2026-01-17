import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api.dart';
import '../models/container.dart';
import '../repositories/container_repository.dart';

/// Container repository provider
final containerRepositoryProvider = Provider<ContainerRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ContainerRepository(client);
});

/// Container list state
sealed class ContainersState {
  const ContainersState();
}

class ContainersLoading extends ContainersState {
  const ContainersLoading();
}

class ContainersLoaded extends ContainersState {
  final List<DockerContainer> containers;

  const ContainersLoaded(this.containers);

  List<DockerContainer> get running =>
      containers.where((c) => c.state.isRunning).toList();

  List<DockerContainer> get stopped =>
      containers.where((c) => !c.state.isRunning).toList();

  int get runningCount => running.length;
  int get totalCount => containers.length;
}

class ContainersError extends ContainersState {
  final String message;

  const ContainersError(this.message);
}

/// Container list notifier for a specific server
class ContainersNotifier extends StateNotifier<ContainersState> {
  final ContainerRepository _repository;
  final String serverId;

  ContainersNotifier(this._repository, this.serverId)
      : super(const ContainersLoading()) {
    load();
  }

  Future<void> load() async {
    state = const ContainersLoading();
    try {
      final containers = await _repository.getContainers(serverId);
      state = ContainersLoaded(containers);
    } catch (e) {
      state = ContainersError(e.toString());
    }
  }

  Future<void> refresh() => load();

  Future<void> performAction(String containerId, ContainerAction action) async {
    try {
      await _repository.performAction(serverId, containerId, action);
      await load(); // Refresh after action
    } catch (e) {
      // Re-throw to be handled by UI
      rethrow;
    }
  }
}

/// Container list provider (family for per-server containers)
final containersProvider = StateNotifierProvider.family<ContainersNotifier,
    ContainersState, String>((ref, serverId) {
  final repository = ref.watch(containerRepositoryProvider);
  return ContainersNotifier(repository, serverId);
});

/// Container stats state
sealed class ContainerStatsState {
  const ContainerStatsState();
}

class ContainerStatsLoading extends ContainerStatsState {
  const ContainerStatsLoading();
}

class ContainerStatsLoaded extends ContainerStatsState {
  final ContainerStats stats;

  const ContainerStatsLoaded(this.stats);
}

class ContainerStatsError extends ContainerStatsState {
  final String message;

  const ContainerStatsError(this.message);
}

/// Container stats parameters
class ContainerStatsParams {
  final String serverId;
  final String containerId;

  const ContainerStatsParams({
    required this.serverId,
    required this.containerId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContainerStatsParams &&
        other.serverId == serverId &&
        other.containerId == containerId;
  }

  @override
  int get hashCode => Object.hash(serverId, containerId);
}

/// Container stats notifier
class ContainerStatsNotifier extends StateNotifier<ContainerStatsState> {
  final ContainerRepository _repository;
  final ContainerStatsParams params;

  ContainerStatsNotifier(this._repository, this.params)
      : super(const ContainerStatsLoading()) {
    load();
  }

  Future<void> load() async {
    state = const ContainerStatsLoading();
    try {
      final stats = await _repository.getContainerStats(
        params.serverId,
        params.containerId,
      );
      state = ContainerStatsLoaded(stats);
    } catch (e) {
      state = ContainerStatsError(e.toString());
    }
  }

  Future<void> refresh() => load();
}

/// Container stats provider (family)
final containerStatsProvider = StateNotifierProvider.family<
    ContainerStatsNotifier, ContainerStatsState, ContainerStatsParams>(
    (ref, params) {
  final repository = ref.watch(containerRepositoryProvider);
  return ContainerStatsNotifier(repository, params);
});

/// Container logs state
sealed class ContainerLogsState {
  const ContainerLogsState();
}

class ContainerLogsLoading extends ContainerLogsState {
  const ContainerLogsLoading();
}

class ContainerLogsLoaded extends ContainerLogsState {
  final List<ContainerLog> logs;

  const ContainerLogsLoaded(this.logs);
}

class ContainerLogsError extends ContainerLogsState {
  final String message;

  const ContainerLogsError(this.message);
}

/// Container logs notifier
class ContainerLogsNotifier extends StateNotifier<ContainerLogsState> {
  final ContainerRepository _repository;
  final ContainerStatsParams params;

  ContainerLogsNotifier(this._repository, this.params)
      : super(const ContainerLogsLoading()) {
    load();
  }

  Future<void> load({int tail = 100}) async {
    state = const ContainerLogsLoading();
    try {
      final logs = await _repository.getContainerLogs(
        params.serverId,
        params.containerId,
        tail: tail,
      );
      state = ContainerLogsLoaded(logs);
    } catch (e) {
      state = ContainerLogsError(e.toString());
    }
  }

  Future<void> refresh() => load();
}

/// Container logs provider (family)
final containerLogsProvider = StateNotifierProvider.family<ContainerLogsNotifier,
    ContainerLogsState, ContainerStatsParams>((ref, params) {
  final repository = ref.watch(containerRepositoryProvider);
  return ContainerLogsNotifier(repository, params);
});
