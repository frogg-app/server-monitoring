/// Alert severity levels
enum AlertSeverity {
  critical,
  warning,
  info;

  factory AlertSeverity.fromString(String severity) {
    return AlertSeverity.values.firstWhere(
      (s) => s.name == severity.toLowerCase(),
      orElse: () => AlertSeverity.info,
    );
  }
}

/// Alert rule operator
enum AlertOperator {
  gt,
  gte,
  lt,
  lte,
  eq,
  neq;

  factory AlertOperator.fromString(String op) {
    return AlertOperator.values.firstWhere(
      (o) => o.name == op.toLowerCase(),
      orElse: () => AlertOperator.gt,
    );
  }

  String get displayName {
    switch (this) {
      case AlertOperator.gt:
        return '>';
      case AlertOperator.gte:
        return '≥';
      case AlertOperator.lt:
        return '<';
      case AlertOperator.lte:
        return '≤';
      case AlertOperator.eq:
        return '=';
      case AlertOperator.neq:
        return '≠';
    }
  }
}

/// Alert rule model
class AlertRule {
  final String id;
  final String name;
  final String? description;
  final String metricType;
  final AlertOperator operator;
  final double threshold;
  final Duration duration;
  final AlertSeverity severity;
  final bool enabled;
  final String? serverId;
  final List<String> notificationChannelIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AlertRule({
    required this.id,
    required this.name,
    this.description,
    required this.metricType,
    required this.operator,
    required this.threshold,
    required this.duration,
    required this.severity,
    required this.enabled,
    this.serverId,
    required this.notificationChannelIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AlertRule.fromJson(Map<String, dynamic> json) {
    return AlertRule(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      metricType: json['metric_type'] as String,
      operator: AlertOperator.fromString(json['operator'] as String),
      threshold: (json['threshold'] as num).toDouble(),
      duration: Duration(seconds: json['duration_seconds'] as int? ?? 60),
      severity: AlertSeverity.fromString(json['severity'] as String),
      enabled: json['enabled'] as bool? ?? true,
      serverId: json['server_id'] as String?,
      notificationChannelIds:
          (json['notification_channel_ids'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'metric_type': metricType,
      'operator': operator.name,
      'threshold': threshold,
      'duration_seconds': duration.inSeconds,
      'severity': severity.name,
      'enabled': enabled,
      'server_id': serverId,
      'notification_channel_ids': notificationChannelIds,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get condition as readable string
  String get conditionString =>
      '$metricType ${operator.displayName} $threshold for ${duration.inMinutes}m';

  AlertRule copyWith({
    String? id,
    String? name,
    String? description,
    String? metricType,
    AlertOperator? operator,
    double? threshold,
    Duration? duration,
    AlertSeverity? severity,
    bool? enabled,
    String? serverId,
    List<String>? notificationChannelIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AlertRule(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      metricType: metricType ?? this.metricType,
      operator: operator ?? this.operator,
      threshold: threshold ?? this.threshold,
      duration: duration ?? this.duration,
      severity: severity ?? this.severity,
      enabled: enabled ?? this.enabled,
      serverId: serverId ?? this.serverId,
      notificationChannelIds: notificationChannelIds ?? this.notificationChannelIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Alert event state
enum AlertEventState {
  firing,
  resolved;

  factory AlertEventState.fromString(String state) {
    return AlertEventState.values.firstWhere(
      (s) => s.name == state.toLowerCase(),
      orElse: () => AlertEventState.firing,
    );
  }
}

/// Alert event model
class AlertEvent {
  final String id;
  final String ruleId;
  final String ruleName;
  final String? serverId;
  final String? serverName;
  final AlertSeverity severity;
  final AlertEventState state;
  final double value;
  final String message;
  final DateTime firedAt;
  final DateTime? resolvedAt;
  final bool acknowledged;
  final String? acknowledgedBy;
  final DateTime? acknowledgedAt;

  const AlertEvent({
    required this.id,
    required this.ruleId,
    required this.ruleName,
    this.serverId,
    this.serverName,
    required this.severity,
    required this.state,
    required this.value,
    required this.message,
    required this.firedAt,
    this.resolvedAt,
    required this.acknowledged,
    this.acknowledgedBy,
    this.acknowledgedAt,
  });

  factory AlertEvent.fromJson(Map<String, dynamic> json) {
    return AlertEvent(
      id: json['id'] as String,
      ruleId: json['rule_id'] as String,
      ruleName: json['rule_name'] as String,
      serverId: json['server_id'] as String?,
      serverName: json['server_name'] as String?,
      severity: AlertSeverity.fromString(json['severity'] as String),
      state: AlertEventState.fromString(json['state'] as String),
      value: (json['value'] as num).toDouble(),
      message: json['message'] as String,
      firedAt: DateTime.parse(json['fired_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      acknowledged: json['acknowledged'] as bool? ?? false,
      acknowledgedBy: json['acknowledged_by'] as String?,
      acknowledgedAt: json['acknowledged_at'] != null
          ? DateTime.parse(json['acknowledged_at'] as String)
          : null,
    );
  }

  /// Check if alert is currently firing
  bool get isFiring => state == AlertEventState.firing;

  /// Get duration of alert
  Duration get duration {
    final end = resolvedAt ?? DateTime.now();
    return end.difference(firedAt);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AlertEvent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Create alert rule request
class CreateAlertRuleRequest {
  final String name;
  final String? description;
  final String metricType;
  final AlertOperator operator;
  final double threshold;
  final int durationSeconds;
  final AlertSeverity severity;
  final String? serverId;
  final List<String>? notificationChannelIds;

  const CreateAlertRuleRequest({
    required this.name,
    this.description,
    required this.metricType,
    required this.operator,
    required this.threshold,
    this.durationSeconds = 60,
    required this.severity,
    this.serverId,
    this.notificationChannelIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      'metric_type': metricType,
      'operator': operator.name,
      'threshold': threshold,
      'duration_seconds': durationSeconds,
      'severity': severity.name,
      if (serverId != null) 'server_id': serverId,
      if (notificationChannelIds != null)
        'notification_channel_ids': notificationChannelIds,
    };
  }
}
