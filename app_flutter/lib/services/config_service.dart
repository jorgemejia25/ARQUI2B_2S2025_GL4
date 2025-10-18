/// Servicio para gestionar la configuración de la aplicación
/// Permite cambiar entre modo desarrollo y producción
class ConfigService {
  static ConfigService? _instance;
  static ConfigService get instance => _instance ??= ConfigService._();

  ConfigService._();

  // Valores por defecto
  static const String _defaultEnvironment = 'development';

  String _currentEnvironment = _defaultEnvironment;
  String? _customBaseUrl;
  String? _customWsUrl;

  /// Inicializar el servicio de configuración
  Future<void> initialize() async {
    // En una implementación real, esto cargaría desde SharedPreferences
    // Por ahora usamos valores por defecto
    _currentEnvironment = _defaultEnvironment;
    _customBaseUrl = null;
    _customWsUrl = null;
  }

  /// Obtener la URL base actual
  String get currentBaseUrl {
    if (_customBaseUrl != null) {
      return _customBaseUrl!;
    }

    switch (_currentEnvironment) {
      case 'production':
        return 'http://69.164.244.224:8001';
      case 'development':
      default:
        return 'http://69.164.244.224:8001';
    }
  }

  /// Obtener la URL base de WebSocket actual
  String get currentWsBaseUrl {
    if (_customWsUrl != null) {
      return _customWsUrl!;
    }

    return currentBaseUrl.replaceFirst('http', 'ws');
  }

  /// Obtener el entorno actual
  String get currentEnvironment => _currentEnvironment;

  /// Verificar si estamos en modo desarrollo
  bool get isDevelopment => _currentEnvironment == 'development';

  /// Verificar si estamos en modo producción
  bool get isProduction => _currentEnvironment == 'production';

  /// Cambiar a modo desarrollo
  Future<void> switchToDevelopment() async {
    _currentEnvironment = 'development';
  }

  /// Cambiar a modo producción
  Future<void> switchToProduction() async {
    _currentEnvironment = 'production';
  }

  /// Establecer URL base personalizada
  Future<void> setCustomBaseUrl(String url) async {
    _customBaseUrl = url;
  }

  /// Establecer URL WebSocket personalizada
  Future<void> setCustomWsUrl(String url) async {
    _customWsUrl = url;
  }

  /// Limpiar configuración personalizada
  Future<void> clearCustomUrls() async {
    _customBaseUrl = null;
    _customWsUrl = null;
  }

  /// Resetear a configuración por defecto
  Future<void> resetToDefaults() async {
    _currentEnvironment = _defaultEnvironment;
    _customBaseUrl = null;
    _customWsUrl = null;
  }

  /// Obtener configuración actual
  Map<String, dynamic> getCurrentConfig() {
    return {
      'environment': _currentEnvironment,
      'baseUrl': currentBaseUrl,
      'wsBaseUrl': currentWsBaseUrl,
      'isDevelopment': isDevelopment,
      'isProduction': isProduction,
      'customBaseUrl': _customBaseUrl,
      'customWsUrl': _customWsUrl,
    };
  }

  /// Obtener URLs completas para diferentes servicios
  Map<String, String> getServiceUrls() {
    final baseUrl = currentBaseUrl;
    final wsBaseUrl = currentWsBaseUrl;

    return {
      'dashboard': '$baseUrl/api/v1/data/dashboard',
      'alerts': '$baseUrl/api/v1/alerts',
      'busStops': '$baseUrl/api/v1/bus-stops',
      'health': '$baseUrl/health',
      'wsTraffic': '$wsBaseUrl/ws/traffic',
      'wsAlerts': '$wsBaseUrl/ws/alerts',
      'wsStops': '$wsBaseUrl/ws/stops',
      'wsGeneral': '$wsBaseUrl/ws/general',
    };
  }

  /// Validar URL
  bool isValidUrl(String url) {
    try {
      Uri.parse(url);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Obtener información de conectividad
  Future<Map<String, dynamic>> getConnectivityInfo() async {
    return {
      'currentEnvironment': _currentEnvironment,
      'baseUrl': currentBaseUrl,
      'wsBaseUrl': currentWsBaseUrl,
      'serviceUrls': getServiceUrls(),
      'isValidBaseUrl': isValidUrl(currentBaseUrl),
      'isValidWsUrl': isValidUrl(currentWsBaseUrl),
    };
  }
}
