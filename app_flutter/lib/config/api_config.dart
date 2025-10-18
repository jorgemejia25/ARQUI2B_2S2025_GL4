/// Configuración centralizada de URLs para el API
/// Sistema de Seguridad de Tráfico - Arquitectura de Software 2
class ApiConfig {
  // URLs de desarrollo local
  static const String _localBaseUrl = 'http://69.164.244.224:8001';

  //DANT: local HOST ME FUNCIONA probar si no te funciona

  // URL actual (se puede cambiar dinámicamente)
  static String get baseUrl {
    // En una implementación real, esto se obtendría del ConfigService
    // Por ahora mantenemos el valor por defecto
    return _localBaseUrl; // Cambiar a _productionBaseUrl para producción
  }

  // Endpoints del API
  static const String apiV1Prefix = '/api/v1';

  // Endpoints de datos del dashboard
  static String get dashboardBaseUrl => '$baseUrl$apiV1Prefix/data/dashboard';
  static String get dashboardSummaryUrl => '$dashboardBaseUrl/summary';
  static String get dashboardMetricsUrl => '$dashboardBaseUrl/metrics';
  static String get dashboardGasChartUrl => '$dashboardBaseUrl/charts/gas';
  static String get dashboardSeismicChartUrl =>
      '$dashboardBaseUrl/charts/seismic';
  static String get dashboardHourlyStatsUrl => '$dashboardBaseUrl/stats/hourly';
  // NUEVOS: Endpoints posiciones de buses
  static String get busPositionMetroUrl =>
      '$dashboardBaseUrl/bus-position/metro';
  static String get busPositionUrbanUrl =>
      '$dashboardBaseUrl/bus-position/urban';

  // Endpoints de alertas
  static String get alertsBaseUrl => '$baseUrl$apiV1Prefix/alerts';
  static String get alertsUrl => alertsBaseUrl;
  static String get alertsByTypeUrl => '$alertsBaseUrl/type';
  static String get alertsBySeverityUrl => '$alertsBaseUrl/severity';
  static String get alertsRecentUrl => '$alertsBaseUrl/recent';

  // Endpoints de paradas de autobús
  static String get busStopsBaseUrl => '$baseUrl$apiV1Prefix/bus-stops';
  static String get busStopsUrl => busStopsBaseUrl;
  static String get busStopsByRouteUrl => '$busStopsBaseUrl/route';
  static String get busStopsNearbyUrl => '$busStopsBaseUrl/nearby';

  // Endpoints de salud del sistema
  static String get healthUrl => '$baseUrl/health';
  static String get healthDetailedUrl => '$baseUrl/health/detailed';

  // WebSocket URLs
  static String get wsBaseUrl => baseUrl.replaceFirst('http', 'ws');
  static String get wsTrafficUrl => '$wsBaseUrl/ws/traffic';
  static String get wsAlertsUrl => '$wsBaseUrl/ws/alerts';
  static String get wsStopsUrl => '$wsBaseUrl/ws/stops';
  static String get wsGeneralUrl => '$wsBaseUrl/ws/general';

  // Configuración de timeouts
  static const Duration defaultTimeout = Duration(seconds: 10);
  static const Duration longTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 5);

  // Configuración de reconexión WebSocket
  static const int maxReconnectAttempts = 5;
  static const Duration reconnectDelay = Duration(seconds: 2);
  static const Duration maxReconnectDelay = Duration(seconds: 32);

  // Headers por defecto
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Configuración de rate limiting para alertas
  static const Duration minAlertInterval = Duration(seconds: 30);
  static const int maxAlertsBuffer = 50;

  // Umbrales para alertas de gas (en PPM)
  static const double gasThresholdLow = 50.0;
  static const double gasThresholdMedium = 100.0;
  static const double gasThresholdHigh = 200.0;

  // Configuración de logging
  static const bool enableDebugLogs = true;
  static const bool enableNetworkLogs = true;
  static const bool enableWebSocketLogs = true;

  /// Verificar si estamos en modo de desarrollo
  static bool get isDevelopment =>
      baseUrl.contains('localhost') || baseUrl.contains('127.0.0.1');

  /// Verificar si estamos en modo de producción
  static bool get isProduction => !isDevelopment;

  /// Obtener URL completa para un endpoint
  static String getFullUrl(String endpoint) {
    if (endpoint.startsWith('http')) {
      return endpoint;
    }
    return '$baseUrl$endpoint';
  }

  /// Obtener URL de WebSocket completa
  static String getWebSocketUrl(String endpoint) {
    if (endpoint.startsWith('ws')) {
      return endpoint;
    }
    return '$wsBaseUrl$endpoint';
  }

  /// Obtener configuración actual
  static Map<String, dynamic> getCurrentConfig() {
    return {
      'baseUrl': baseUrl,
      'isDevelopment': isDevelopment,
      'isProduction': isProduction,
      'timeouts': {
        'default': defaultTimeout.inSeconds,
        'long': longTimeout.inSeconds,
        'short': shortTimeout.inSeconds,
      },
      'websocket': {
        'trafficUrl': wsTrafficUrl,
        'alertsUrl': wsAlertsUrl,
        'stopsUrl': wsStopsUrl,
        'generalUrl': wsGeneralUrl,
        'maxReconnectAttempts': maxReconnectAttempts,
        'reconnectDelay': reconnectDelay.inSeconds,
      },
      'rateLimiting': {
        'minAlertInterval': minAlertInterval.inSeconds,
        'maxAlertsBuffer': maxAlertsBuffer,
      },
      'gasThresholds': {
        'low': gasThresholdLow,
        'medium': gasThresholdMedium,
        'high': gasThresholdHigh,
      },
      'logging': {
        'debug': enableDebugLogs,
        'network': enableNetworkLogs,
        'websocket': enableWebSocketLogs,
      },
    };
  }

  /// Cambiar a modo de desarrollo
  static void switchToDevelopment() {
    // Nota: En una implementación real, esto se haría a través de
    // variables de entorno o configuración persistente
  }

  /// Cambiar a modo de producción
  static void switchToProduction() {
    // Nota: En una implementación real, esto se haría a través de
    // variables de entorno o configuración persistente
  }
}
