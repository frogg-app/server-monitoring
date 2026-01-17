import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api.dart';
import '../models/models.dart';
import '../repositories/alert_repository.dart';

/// Alert repository provider
final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return AlertRepository(client);
});

// Alert Rules

/// Alert rules state
sealed class AlertRulesState {
  const AlertRulesState();
}

class AlertRulesLoading extends AlertRulesState {
  const AlertRulesLoading();
}

class AlertRulesLoaded extends AlertRulesState {
  final List<AlertRule> rules;

  const AlertRulesLoaded(this.rules);

  List<AlertRule> get enabled => rules.where((r) => r.enabled).toList();
  List<AlertRule> get disabled => rules.where((r) => !r.enabled).toList();
}

class AlertRulesError extends AlertRulesState {
  final String message;

  const AlertRulesError(this.message);
}

/// Alert rules notifier
class AlertRulesNotifier extends StateNotifier<AlertRulesState> {
  final AlertRepository _repository;

  AlertRulesNotifier(this._repository) : super(const AlertRulesLoading()) {
    load();
  }

  Future<void> load() async {
    state = const AlertRulesLoading();
    try {
      final rules = await _repository.getAlertRules();
      state = AlertRulesLoaded(rules);
    } catch (e) {
      state = AlertRulesError(e.toString());
    }
  }

  Future<void> refresh() => load();

  Future<AlertRule> createRule(CreateAlertRuleRequest request) async {
    final rule = await _repository.createAlertRule(request);
    await load();
    return rule;
  }

  Future<void> deleteRule(String id) async {
    await _repository.deleteAlertRule(id);
    await load();
  }

  Future<void> toggleRule(String id, bool enabled) async {
    await _repository.toggleAlertRule(id, enabled);
    await load();
  }
}

/// Alert rules provider
final alertRulesProvider =
    StateNotifierProvider<AlertRulesNotifier, AlertRulesState>((ref) {
  final repository = ref.watch(alertRepositoryProvider);
  return AlertRulesNotifier(repository);
});

// Alert Events

/// Alert events state
sealed class AlertEventsState {
  const AlertEventsState();
}

class AlertEventsLoading extends AlertEventsState {
  const AlertEventsLoading();
}

class AlertEventsLoaded extends AlertEventsState {
  final List<AlertEvent> events;

  const AlertEventsLoaded(this.events);

  List<AlertEvent> get firing => events.where((e) => e.isFiring).toList();
  List<AlertEvent> get resolved => events.where((e) => !e.isFiring).toList();
  int get firingCount => firing.length;
}

class AlertEventsError extends AlertEventsState {
  final String message;

  const AlertEventsError(this.message);
}

/// Alert events notifier
class AlertEventsNotifier extends StateNotifier<AlertEventsState> {
  final AlertRepository _repository;

  AlertEventsNotifier(this._repository) : super(const AlertEventsLoading()) {
    load();
  }

  Future<void> load({AlertEventState? filterState}) async {
    state = const AlertEventsLoading();
    try {
      final events = await _repository.getAlertEvents(state: filterState);
      state = AlertEventsLoaded(events);
    } catch (e) {
      state = AlertEventsError(e.toString());
    }
  }

  Future<void> refresh() => load();

  Future<void> acknowledge(String eventId) async {
    await _repository.acknowledgeAlertEvent(eventId);
    await load();
  }
}

/// Alert events provider
final alertEventsProvider =
    StateNotifierProvider<AlertEventsNotifier, AlertEventsState>((ref) {
  final repository = ref.watch(alertRepositoryProvider);
  return AlertEventsNotifier(repository);
});

/// Firing alerts count provider (for badges)
final firingAlertsCountProvider = Provider<int>((ref) {
  final state = ref.watch(alertEventsProvider);
  if (state is AlertEventsLoaded) {
    return state.firingCount;
  }
  return 0;
});

// Notification Channels

/// Notification channels state
sealed class NotificationChannelsState {
  const NotificationChannelsState();
}

class NotificationChannelsLoading extends NotificationChannelsState {
  const NotificationChannelsLoading();
}

class NotificationChannelsLoaded extends NotificationChannelsState {
  final List<NotificationChannel> channels;

  const NotificationChannelsLoaded(this.channels);
}

class NotificationChannelsError extends NotificationChannelsState {
  final String message;

  const NotificationChannelsError(this.message);
}

/// Notification channels notifier
class NotificationChannelsNotifier extends StateNotifier<NotificationChannelsState> {
  final AlertRepository _repository;

  NotificationChannelsNotifier(this._repository)
      : super(const NotificationChannelsLoading()) {
    load();
  }

  Future<void> load() async {
    state = const NotificationChannelsLoading();
    try {
      final channels = await _repository.getNotificationChannels();
      state = NotificationChannelsLoaded(channels);
    } catch (e) {
      state = NotificationChannelsError(e.toString());
    }
  }

  Future<void> refresh() => load();

  Future<NotificationChannel> createChannel(
    CreateNotificationChannelRequest request,
  ) async {
    final channel = await _repository.createNotificationChannel(request);
    await load();
    return channel;
  }

  Future<void> deleteChannel(String id) async {
    await _repository.deleteNotificationChannel(id);
    await load();
  }

  Future<bool> testChannel(String id) async {
    return await _repository.testNotificationChannel(id);
  }
}

/// Notification channels provider
final notificationChannelsProvider = StateNotifierProvider<
    NotificationChannelsNotifier, NotificationChannelsState>((ref) {
  final repository = ref.watch(alertRepositoryProvider);
  return NotificationChannelsNotifier(repository);
});
