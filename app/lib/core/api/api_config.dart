/// API configuration and constants
class ApiConfig {
  /// Base URL for the API
  /// Use relative path for web to work with nginx proxy
  static const String defaultBaseUrl = '/api/v1';

  /// API request timeout in seconds
  static const int timeoutSeconds = 30;

  /// Enable request/response logging
  static const bool enableLogging = true;

  /// Auth header name
  static const String authHeader = 'Authorization';

  /// Bearer token prefix
  static const String bearerPrefix = 'Bearer';
}

/// API endpoints
class ApiEndpoints {
  // Auth endpoints
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';

  // Server endpoints
  static const String servers = '/servers';
  static String server(String id) => '/servers/$id';
  static String serverTest(String id) => '/servers/$id/test';
  static String serverMetrics(String id) => '/servers/$id/metrics';
  static String serverContainers(String id) => '/servers/$id/containers';
  static String serverCredentials(String id) => '/servers/$id/credentials';

  // Credential endpoints
  static const String credentials = '/credentials';
  static String credential(String id) => '/credentials/$id';

  // Metrics endpoints
  static const String metrics = '/metrics';
  static String metricsByServer(String id) => '/servers/$id/metrics';

  // Alerts endpoints
  static const String alerts = '/alerts';
  static const String alertRules = '/alerts/rules';
  static String alertRule(String id) => '/alerts/rules/$id';
  static const String alertEvents = '/alerts/events';
  static String alertEvent(String id) => '/alerts/events/$id';

  // Settings endpoints
  static const String settings = '/settings';
  static const String notificationChannels = '/settings/notifications';

  // Key management endpoints
  static const String keysGenerate = '/keys/generate';
}
