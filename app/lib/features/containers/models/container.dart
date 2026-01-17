/// Container state enumeration
enum ContainerState {
  running,
  paused,
  restarting,
  removing,
  exited,
  dead,
  created,
  unknown;

  factory ContainerState.fromString(String state) {
    return ContainerState.values.firstWhere(
      (s) => s.name == state.toLowerCase(),
      orElse: () => ContainerState.unknown,
    );
  }

  bool get isRunning => this == ContainerState.running;
  bool get canStart => this == ContainerState.exited || this == ContainerState.created;
  bool get canStop => this == ContainerState.running || this == ContainerState.paused;
  bool get canRestart => this == ContainerState.running;
  bool get canPause => this == ContainerState.running;
  bool get canUnpause => this == ContainerState.paused;
}

/// Container health status
enum HealthStatus {
  healthy,
  unhealthy,
  starting,
  none;

  factory HealthStatus.fromString(String? status) {
    if (status == null) return HealthStatus.none;
    return HealthStatus.values.firstWhere(
      (s) => s.name == status.toLowerCase(),
      orElse: () => HealthStatus.none,
    );
  }
}

/// Docker container model
class DockerContainer {
  final String id;
  final String name;
  final String image;
  final ContainerState state;
  final HealthStatus health;
  final String status;
  final DateTime createdAt;
  final Map<String, String> ports;
  final Map<String, String>? labels;

  const DockerContainer({
    required this.id,
    required this.name,
    required this.image,
    required this.state,
    required this.health,
    required this.status,
    required this.createdAt,
    required this.ports,
    this.labels,
  });

  factory DockerContainer.fromJson(Map<String, dynamic> json) {
    return DockerContainer(
      id: json['id'] as String,
      name: json['name'] as String,
      image: json['image'] as String,
      state: ContainerState.fromString(json['state'] as String),
      health: HealthStatus.fromString(json['health'] as String?),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      ports: Map<String, String>.from(json['ports'] as Map? ?? {}),
      labels: json['labels'] != null
          ? Map<String, String>.from(json['labels'] as Map)
          : null,
    );
  }

  /// Get short ID (first 12 chars)
  String get shortId => id.length > 12 ? id.substring(0, 12) : id;

  /// Check if container has a specific label
  bool hasLabel(String key) => labels?.containsKey(key) ?? false;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DockerContainer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Container stats (real-time metrics)
class ContainerStats {
  final String containerId;
  final double cpuPercent;
  final int memoryUsage;
  final int memoryLimit;
  final double memoryPercent;
  final int networkRxBytes;
  final int networkTxBytes;
  final int blockReadBytes;
  final int blockWriteBytes;
  final int pids;
  final DateTime timestamp;

  const ContainerStats({
    required this.containerId,
    required this.cpuPercent,
    required this.memoryUsage,
    required this.memoryLimit,
    required this.memoryPercent,
    required this.networkRxBytes,
    required this.networkTxBytes,
    required this.blockReadBytes,
    required this.blockWriteBytes,
    required this.pids,
    required this.timestamp,
  });

  factory ContainerStats.fromJson(Map<String, dynamic> json) {
    return ContainerStats(
      containerId: json['container_id'] as String,
      cpuPercent: (json['cpu_percent'] as num).toDouble(),
      memoryUsage: json['memory_usage'] as int,
      memoryLimit: json['memory_limit'] as int,
      memoryPercent: (json['memory_percent'] as num).toDouble(),
      networkRxBytes: json['network_rx_bytes'] as int,
      networkTxBytes: json['network_tx_bytes'] as int,
      blockReadBytes: json['block_read_bytes'] as int,
      blockWriteBytes: json['block_write_bytes'] as int,
      pids: json['pids'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Format memory as human readable string
  String get memoryFormatted {
    return '${_formatBytes(memoryUsage)} / ${_formatBytes(memoryLimit)}';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Container action types
enum ContainerAction {
  start,
  stop,
  restart,
  pause,
  unpause,
  remove;

  String get displayName {
    switch (this) {
      case ContainerAction.start:
        return 'Start';
      case ContainerAction.stop:
        return 'Stop';
      case ContainerAction.restart:
        return 'Restart';
      case ContainerAction.pause:
        return 'Pause';
      case ContainerAction.unpause:
        return 'Unpause';
      case ContainerAction.remove:
        return 'Remove';
    }
  }
}

/// Container log entry
class ContainerLog {
  final String stream; // stdout or stderr
  final DateTime timestamp;
  final String message;

  const ContainerLog({
    required this.stream,
    required this.timestamp,
    required this.message,
  });

  factory ContainerLog.fromJson(Map<String, dynamic> json) {
    return ContainerLog(
      stream: json['stream'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      message: json['message'] as String,
    );
  }

  bool get isError => stream == 'stderr';
}
