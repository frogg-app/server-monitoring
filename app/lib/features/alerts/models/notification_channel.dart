/// Notification channel type
enum NotificationChannelType {
  email,
  webhook,
  slack,
  discord,
  telegram,
  pushover;

  factory NotificationChannelType.fromString(String type) {
    return NotificationChannelType.values.firstWhere(
      (t) => t.name == type.toLowerCase(),
      orElse: () => NotificationChannelType.webhook,
    );
  }
}

/// Notification channel model
class NotificationChannel {
  final String id;
  final String name;
  final NotificationChannelType type;
  final Map<String, dynamic> config;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationChannel({
    required this.id,
    required this.name,
    required this.type,
    required this.config,
    required this.enabled,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationChannel.fromJson(Map<String, dynamic> json) {
    return NotificationChannel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: NotificationChannelType.fromString(json['type'] as String),
      config: json['config'] as Map<String, dynamic>? ?? {},
      enabled: json['enabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'config': config,
      'enabled': enabled,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationChannel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Create notification channel request
class CreateNotificationChannelRequest {
  final String name;
  final NotificationChannelType type;
  final Map<String, dynamic> config;

  const CreateNotificationChannelRequest({
    required this.name,
    required this.type,
    required this.config,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.name,
      'config': config,
    };
  }
}
