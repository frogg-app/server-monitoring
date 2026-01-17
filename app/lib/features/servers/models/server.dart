/// Server status enumeration
enum ServerStatus {
  online,
  offline,
  warning,
  unknown;

  factory ServerStatus.fromString(String status) {
    return ServerStatus.values.firstWhere(
      (s) => s.name == status.toLowerCase(),
      orElse: () => ServerStatus.unknown,
    );
  }
}

/// Server model
class Server {
  final String id;
  final String name;
  final String hostname;
  final int port;
  final String? description;
  final List<String> tags;
  final ServerStatus status;
  final DateTime? lastSeenAt;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Server({
    required this.id,
    required this.name,
    required this.hostname,
    required this.port,
    this.description,
    required this.tags,
    required this.status,
    this.lastSeenAt,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Server.fromJson(Map<String, dynamic> json) {
    return Server(
      id: json['id'] as String,
      name: json['name'] as String,
      hostname: json['hostname'] as String,
      port: json['port'] as int? ?? 22,
      description: json['description'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      status: ServerStatus.fromString(json['status'] as String? ?? 'unknown'),
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'] as String)
          : null,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'hostname': hostname,
      'port': port,
      'description': description,
      'tags': tags,
      'status': status.name,
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Server copyWith({
    String? id,
    String? name,
    String? hostname,
    int? port,
    String? description,
    List<String>? tags,
    ServerStatus? status,
    DateTime? lastSeenAt,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Server(
      id: id ?? this.id,
      name: name ?? this.name,
      hostname: hostname ?? this.hostname,
      port: port ?? this.port,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if server is online
  bool get isOnline => status == ServerStatus.online;

  /// Get status color
  String get statusLabel {
    switch (status) {
      case ServerStatus.online:
        return 'Online';
      case ServerStatus.offline:
        return 'Offline';
      case ServerStatus.warning:
        return 'Warning';
      case ServerStatus.unknown:
        return 'Unknown';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Server && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Server(id: $id, name: $name, status: $status)';
}

/// Server with metrics summary
class ServerWithMetrics extends Server {
  final double? cpuPercent;
  final double? memoryPercent;
  final double? diskPercent;
  final int? uptime;

  const ServerWithMetrics({
    required super.id,
    required super.name,
    required super.hostname,
    required super.port,
    super.description,
    required super.tags,
    required super.status,
    super.lastSeenAt,
    super.createdBy,
    required super.createdAt,
    required super.updatedAt,
    this.cpuPercent,
    this.memoryPercent,
    this.diskPercent,
    this.uptime,
  });

  factory ServerWithMetrics.fromJson(Map<String, dynamic> json) {
    return ServerWithMetrics(
      id: json['id'] as String,
      name: json['name'] as String,
      hostname: json['hostname'] as String,
      port: json['port'] as int? ?? 22,
      description: json['description'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      status: ServerStatus.fromString(json['status'] as String? ?? 'unknown'),
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'] as String)
          : null,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      cpuPercent: (json['cpu_percent'] as num?)?.toDouble(),
      memoryPercent: (json['memory_percent'] as num?)?.toDouble(),
      diskPercent: (json['disk_percent'] as num?)?.toDouble(),
      uptime: json['uptime'] as int?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'cpu_percent': cpuPercent,
      'memory_percent': memoryPercent,
      'disk_percent': diskPercent,
      'uptime': uptime,
    };
  }
}

/// Create server request
class CreateServerRequest {
  final String name;
  final String hostname;
  final int port;
  final String? description;
  final List<String>? tags;

  const CreateServerRequest({
    required this.name,
    required this.hostname,
    this.port = 22,
    this.description,
    this.tags,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'hostname': hostname,
      'port': port,
      if (description != null) 'description': description,
      if (tags != null) 'tags': tags,
    };
  }
}

/// Update server request
class UpdateServerRequest {
  final String? name;
  final String? hostname;
  final int? port;
  final String? description;
  final List<String>? tags;

  const UpdateServerRequest({
    this.name,
    this.hostname,
    this.port,
    this.description,
    this.tags,
  });

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (hostname != null) 'hostname': hostname,
      if (port != null) 'port': port,
      if (description != null) 'description': description,
      if (tags != null) 'tags': tags,
    };
  }
}
