import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api.dart';
import '../models/metrics.dart';
import '../repositories/metrics_repository.dart';

/// Metrics repository provider
final metricsRepositoryProvider = Provider<MetricsRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return MetricsRepository(client);
});

/// Current metrics state for a server
sealed class CurrentMetricsState {
  const CurrentMetricsState();
}

class CurrentMetricsLoading extends CurrentMetricsState {
  const CurrentMetricsLoading();
}

class CurrentMetricsLoaded extends CurrentMetricsState {
  final SystemMetrics metrics;

  const CurrentMetricsLoaded(this.metrics);
}

class CurrentMetricsError extends CurrentMetricsState {
  final String message;

  const CurrentMetricsError(this.message);
}

/// Current metrics notifier for a specific server
class CurrentMetricsNotifier extends StateNotifier<CurrentMetricsState> {
  final MetricsRepository _repository;
  final String serverId;

  CurrentMetricsNotifier(this._repository, this.serverId)
      : super(const CurrentMetricsLoading()) {
    load();
  }

  Future<void> load() async {
    state = const CurrentMetricsLoading();
    try {
      final metrics = await _repository.getCurrentMetrics(serverId);
      state = CurrentMetricsLoaded(metrics);
    } catch (e) {
      state = CurrentMetricsError(e.toString());
    }
  }

  Future<void> refresh() => load();
}

/// Current metrics provider (family for per-server metrics)
final currentMetricsProvider = StateNotifierProvider.family<
    CurrentMetricsNotifier, CurrentMetricsState, String>((ref, serverId) {
  final repository = ref.watch(metricsRepositoryProvider);
  return CurrentMetricsNotifier(repository, serverId);
});

/// Metric history state
sealed class MetricHistoryState {
  const MetricHistoryState();
}

class MetricHistoryLoading extends MetricHistoryState {
  const MetricHistoryLoading();
}

class MetricHistoryLoaded extends MetricHistoryState {
  final List<MetricSeries> series;

  const MetricHistoryLoaded(this.series);

  /// Get series by type
  MetricSeries? getSeriesByType(MetricType type) {
    return series.where((s) => s.type == type).firstOrNull;
  }
}

class MetricHistoryError extends MetricHistoryState {
  final String message;

  const MetricHistoryError(this.message);
}

/// Metric history query parameters
class MetricHistoryParams {
  final String serverId;
  final List<MetricType> types;
  final Duration range;

  const MetricHistoryParams({
    required this.serverId,
    required this.types,
    this.range = const Duration(hours: 1),
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MetricHistoryParams &&
        other.serverId == serverId &&
        other.types.length == types.length &&
        other.range == range;
  }

  @override
  int get hashCode => Object.hash(serverId, types.length, range);
}

/// Metric history notifier
class MetricHistoryNotifier extends StateNotifier<MetricHistoryState> {
  final MetricsRepository _repository;
  final MetricHistoryParams params;

  MetricHistoryNotifier(this._repository, this.params)
      : super(const MetricHistoryLoading()) {
    load();
  }

  Future<void> load() async {
    state = const MetricHistoryLoading();
    try {
      final now = DateTime.now();
      final query = MetricsQuery(
        serverId: params.serverId,
        types: params.types,
        startTime: now.subtract(params.range),
        endTime: now,
      );
      final series = await _repository.getMetricHistory(query);
      state = MetricHistoryLoaded(series);
    } catch (e) {
      state = MetricHistoryError(e.toString());
    }
  }

  Future<void> refresh() => load();
}

/// Metric history provider (family for different queries)
final metricHistoryProvider = StateNotifierProvider.family<MetricHistoryNotifier,
    MetricHistoryState, MetricHistoryParams>((ref, params) {
  final repository = ref.watch(metricsRepositoryProvider);
  return MetricHistoryNotifier(repository, params);
});

/// Time range for metric charts
enum TimeRange {
  hour(Duration(hours: 1), '1h'),
  sixHours(Duration(hours: 6), '6h'),
  day(Duration(days: 1), '24h'),
  week(Duration(days: 7), '7d'),
  month(Duration(days: 30), '30d');

  const TimeRange(this.duration, this.label);

  final Duration duration;
  final String label;
}

/// Selected time range provider
final selectedTimeRangeProvider = StateProvider<TimeRange>((ref) => TimeRange.hour);
