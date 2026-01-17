import '../../../core/api/api.dart';
import '../models/metrics.dart';

/// Repository for metrics API operations
class MetricsRepository {
  final ApiClient _client;

  MetricsRepository(this._client);

  /// Get current metrics for a server
  Future<SystemMetrics> getCurrentMetrics(String serverId) async {
    final response = await _client.get(
      ApiEndpoints.serverMetrics(serverId),
      queryParameters: {'current': 'true'},
    );
    final data = response.data as Map<String, dynamic>;
    return SystemMetrics.fromJson(data['metrics'] as Map<String, dynamic>);
  }

  /// Get metric history for a server
  Future<List<MetricSeries>> getMetricHistory(MetricsQuery query) async {
    final response = await _client.get(
      ApiEndpoints.serverMetrics(query.serverId),
      queryParameters: query.toQueryParams(),
    );
    final data = response.data as Map<String, dynamic>;
    final series = data['series'] as List<dynamic>;
    return series
        .map((s) => MetricSeries.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  /// Get aggregated metrics for dashboard
  Future<Map<String, dynamic>> getDashboardMetrics() async {
    final response = await _client.get('/metrics/dashboard');
    return response.data as Map<String, dynamic>;
  }
}
