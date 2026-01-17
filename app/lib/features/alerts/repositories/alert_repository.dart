import '../../../core/api/api.dart';
import '../models/models.dart';

/// Repository for alert API operations
class AlertRepository {
  final ApiClient _client;

  AlertRepository(this._client);

  // Alert Rules

  /// Get all alert rules
  Future<List<AlertRule>> getAlertRules() async {
    final response = await _client.get(ApiEndpoints.alertRules);
    final data = response.data as Map<String, dynamic>;
    final rules = data['rules'] as List<dynamic>;
    return rules
        .map((r) => AlertRule.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Get a single alert rule
  Future<AlertRule> getAlertRule(String id) async {
    final response = await _client.get(ApiEndpoints.alertRule(id));
    final data = response.data as Map<String, dynamic>;
    return AlertRule.fromJson(data['rule'] as Map<String, dynamic>);
  }

  /// Create an alert rule
  Future<AlertRule> createAlertRule(CreateAlertRuleRequest request) async {
    final response = await _client.post(
      ApiEndpoints.alertRules,
      data: request.toJson(),
    );
    final data = response.data as Map<String, dynamic>;
    return AlertRule.fromJson(data['rule'] as Map<String, dynamic>);
  }

  /// Update an alert rule
  Future<AlertRule> updateAlertRule(String id, Map<String, dynamic> updates) async {
    final response = await _client.patch(
      ApiEndpoints.alertRule(id),
      data: updates,
    );
    final data = response.data as Map<String, dynamic>;
    return AlertRule.fromJson(data['rule'] as Map<String, dynamic>);
  }

  /// Delete an alert rule
  Future<void> deleteAlertRule(String id) async {
    await _client.delete(ApiEndpoints.alertRule(id));
  }

  /// Toggle alert rule enabled/disabled
  Future<AlertRule> toggleAlertRule(String id, bool enabled) async {
    return updateAlertRule(id, {'enabled': enabled});
  }

  // Alert Events

  /// Get alert events
  Future<List<AlertEvent>> getAlertEvents({
    String? serverId,
    AlertEventState? state,
    int? limit,
  }) async {
    final response = await _client.get(
      ApiEndpoints.alertEvents,
      queryParameters: {
        if (serverId != null) 'server_id': serverId,
        if (state != null) 'state': state.name,
        if (limit != null) 'limit': limit.toString(),
      },
    );
    final data = response.data as Map<String, dynamic>;
    final events = data['events'] as List<dynamic>;
    return events
        .map((e) => AlertEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Acknowledge an alert event
  Future<AlertEvent> acknowledgeAlertEvent(String id) async {
    final response = await _client.post('${ApiEndpoints.alertEvent(id)}/acknowledge');
    final data = response.data as Map<String, dynamic>;
    return AlertEvent.fromJson(data['event'] as Map<String, dynamic>);
  }

  // Notification Channels

  /// Get all notification channels
  Future<List<NotificationChannel>> getNotificationChannels() async {
    final response = await _client.get(ApiEndpoints.notificationChannels);
    final data = response.data as Map<String, dynamic>;
    final channels = data['channels'] as List<dynamic>;
    return channels
        .map((c) => NotificationChannel.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  /// Create a notification channel
  Future<NotificationChannel> createNotificationChannel(
    CreateNotificationChannelRequest request,
  ) async {
    final response = await _client.post(
      ApiEndpoints.notificationChannels,
      data: request.toJson(),
    );
    final data = response.data as Map<String, dynamic>;
    return NotificationChannel.fromJson(data['channel'] as Map<String, dynamic>);
  }

  /// Delete a notification channel
  Future<void> deleteNotificationChannel(String id) async {
    await _client.delete('${ApiEndpoints.notificationChannels}/$id');
  }

  /// Test a notification channel
  Future<bool> testNotificationChannel(String id) async {
    try {
      final response = await _client.post(
        '${ApiEndpoints.notificationChannels}/$id/test',
      );
      final data = response.data as Map<String, dynamic>;
      return data['success'] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }
}
