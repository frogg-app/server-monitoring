/// Metric types
enum MetricType {
  cpuPercent,
  memoryPercent,
  memoryUsedBytes,
  memoryTotalBytes,
  diskPercent,
  diskUsedBytes,
  diskTotalBytes,
  networkRxBytes,
  networkTxBytes,
  loadAvg1,
  loadAvg5,
  loadAvg15,
  uptime;

  factory MetricType.fromString(String type) {
    switch (type) {
      case 'cpu_percent':
        return MetricType.cpuPercent;
      case 'memory_percent':
        return MetricType.memoryPercent;
      case 'memory_used_bytes':
        return MetricType.memoryUsedBytes;
      case 'memory_total_bytes':
        return MetricType.memoryTotalBytes;
      case 'disk_percent':
        return MetricType.diskPercent;
      case 'disk_used_bytes':
        return MetricType.diskUsedBytes;
      case 'disk_total_bytes':
        return MetricType.diskTotalBytes;
      case 'network_rx_bytes':
        return MetricType.networkRxBytes;
      case 'network_tx_bytes':
        return MetricType.networkTxBytes;
      case 'load_avg_1':
        return MetricType.loadAvg1;
      case 'load_avg_5':
        return MetricType.loadAvg5;
      case 'load_avg_15':
        return MetricType.loadAvg15;
      case 'uptime':
        return MetricType.uptime;
      default:
        return MetricType.cpuPercent;
    }
  }

  String toJsonString() {
    switch (this) {
      case MetricType.cpuPercent:
        return 'cpu_percent';
      case MetricType.memoryPercent:
        return 'memory_percent';
      case MetricType.memoryUsedBytes:
        return 'memory_used_bytes';
      case MetricType.memoryTotalBytes:
        return 'memory_total_bytes';
      case MetricType.diskPercent:
        return 'disk_percent';
      case MetricType.diskUsedBytes:
        return 'disk_used_bytes';
      case MetricType.diskTotalBytes:
        return 'disk_total_bytes';
      case MetricType.networkRxBytes:
        return 'network_rx_bytes';
      case MetricType.networkTxBytes:
        return 'network_tx_bytes';
      case MetricType.loadAvg1:
        return 'load_avg_1';
      case MetricType.loadAvg5:
        return 'load_avg_5';
      case MetricType.loadAvg15:
        return 'load_avg_15';
      case MetricType.uptime:
        return 'uptime';
    }
  }

  String get displayName {
    switch (this) {
      case MetricType.cpuPercent:
        return 'CPU';
      case MetricType.memoryPercent:
        return 'Memory';
      case MetricType.memoryUsedBytes:
        return 'Memory Used';
      case MetricType.memoryTotalBytes:
        return 'Memory Total';
      case MetricType.diskPercent:
        return 'Disk';
      case MetricType.diskUsedBytes:
        return 'Disk Used';
      case MetricType.diskTotalBytes:
        return 'Disk Total';
      case MetricType.networkRxBytes:
        return 'Network RX';
      case MetricType.networkTxBytes:
        return 'Network TX';
      case MetricType.loadAvg1:
        return 'Load (1m)';
      case MetricType.loadAvg5:
        return 'Load (5m)';
      case MetricType.loadAvg15:
        return 'Load (15m)';
      case MetricType.uptime:
        return 'Uptime';
    }
  }
}

/// Single metric data point
class MetricPoint {
  final DateTime timestamp;
  final double value;
  final Map<String, String>? labels;

  const MetricPoint({
    required this.timestamp,
    required this.value,
    this.labels,
  });

  factory MetricPoint.fromJson(Map<String, dynamic> json) {
    return MetricPoint(
      timestamp: DateTime.parse(json['timestamp'] as String),
      value: (json['value'] as num).toDouble(),
      labels: json['labels'] != null
          ? Map<String, String>.from(json['labels'] as Map)
          : null,
    );
  }
}

/// Time series data for a metric type
class MetricSeries {
  final MetricType type;
  final String? serverId;
  final List<MetricPoint> points;

  const MetricSeries({
    required this.type,
    this.serverId,
    required this.points,
  });

  factory MetricSeries.fromJson(Map<String, dynamic> json) {
    final pointsList = json['points'] as List<dynamic>;
    return MetricSeries(
      type: MetricType.fromString(json['type'] as String),
      serverId: json['server_id'] as String?,
      points: pointsList
          .map((p) => MetricPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Get latest value
  double? get latestValue => points.isNotEmpty ? points.last.value : null;

  /// Get average value
  double get average {
    if (points.isEmpty) return 0;
    return points.map((p) => p.value).reduce((a, b) => a + b) / points.length;
  }

  /// Get max value
  double get max {
    if (points.isEmpty) return 0;
    return points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
  }

  /// Get min value
  double get min {
    if (points.isEmpty) return 0;
    return points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
  }
}

/// Current system metrics snapshot
class SystemMetrics {
  final double cpuPercent;
  final double memoryPercent;
  final int memoryUsedBytes;
  final int memoryTotalBytes;
  final double diskPercent;
  final int diskUsedBytes;
  final int diskTotalBytes;
  final double loadAvg1;
  final double loadAvg5;
  final double loadAvg15;
  final int uptime;
  final DateTime timestamp;

  const SystemMetrics({
    required this.cpuPercent,
    required this.memoryPercent,
    required this.memoryUsedBytes,
    required this.memoryTotalBytes,
    required this.diskPercent,
    required this.diskUsedBytes,
    required this.diskTotalBytes,
    required this.loadAvg1,
    required this.loadAvg5,
    required this.loadAvg15,
    required this.uptime,
    required this.timestamp,
  });

  factory SystemMetrics.fromJson(Map<String, dynamic> json) {
    return SystemMetrics(
      cpuPercent: (json['cpu_percent'] as num).toDouble(),
      memoryPercent: (json['memory_percent'] as num).toDouble(),
      memoryUsedBytes: json['memory_used_bytes'] as int,
      memoryTotalBytes: json['memory_total_bytes'] as int,
      diskPercent: (json['disk_percent'] as num).toDouble(),
      diskUsedBytes: json['disk_used_bytes'] as int,
      diskTotalBytes: json['disk_total_bytes'] as int,
      loadAvg1: (json['load_avg_1'] as num).toDouble(),
      loadAvg5: (json['load_avg_5'] as num).toDouble(),
      loadAvg15: (json['load_avg_15'] as num).toDouble(),
      uptime: json['uptime'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Format uptime as human readable string
  String get uptimeFormatted {
    final days = uptime ~/ 86400;
    final hours = (uptime % 86400) ~/ 3600;
    final minutes = (uptime % 3600) ~/ 60;
    
    if (days > 0) {
      return '${days}d ${hours}h';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Format bytes as human readable string
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Metrics query parameters
class MetricsQuery {
  final String serverId;
  final List<MetricType>? types;
  final DateTime? startTime;
  final DateTime? endTime;
  final Duration? interval;

  const MetricsQuery({
    required this.serverId,
    this.types,
    this.startTime,
    this.endTime,
    this.interval,
  });

  Map<String, dynamic> toQueryParams() {
    return {
      if (types != null) 'types': types!.map((t) => t.toJsonString()).join(','),
      if (startTime != null) 'start': startTime!.toIso8601String(),
      if (endTime != null) 'end': endTime!.toIso8601String(),
      if (interval != null) 'interval': '${interval!.inSeconds}s',
    };
  }
}
