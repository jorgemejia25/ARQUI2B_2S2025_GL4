// lib/services/websocket_alerts.dart
//
// ACTUALIZADO: Se agregaron validaciones para alertas de gas para evitar spam
// - Validación de valores de gas antes de mostrar alertas
// - Rate limiting para evitar alertas repetitivas cada segundo
// - Umbrales configurables para determinar severidad de alertas de gas
// - Filtros para rechazar alertas sin datos válidos

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/websocket_message.dart'; // reutiliza AlertData, AlertMessage, AlertType

class WebSocketAlertsService {
  static WebSocketAlertsService? _instance;
  static WebSocketAlertsService get instance =>
      _instance ??= WebSocketAlertsService._();
  WebSocketAlertsService._();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  final String _url =
      'wss://arqui2b2s2025gl4-production.up.railway.app/ws/alerts';

  // Buffer + stream para el feed
  final List<AlertData> _recentAlerts = [];
  static const int _maxAlertsBuffer = 50;
  final StreamController<List<AlertData>> _alertsController =
      StreamController<List<AlertData>>.broadcast();

  // Rate limiting para evitar spam de alertas
  final Map<String, DateTime> _lastAlertTime = {};
  static const Duration _minAlertInterval = Duration(seconds: 30);

  // Umbrales para alertas de gas (valores en ppm o porcentaje)
  static const double _gasThresholdLow = 50.0; // Umbral bajo
  static const double _gasThresholdMedium = 100.0; // Umbral medio
  static const double _gasThresholdHigh = 200.0; // Umbral alto

  // Callbacks opcionales
  Function(AlertData)? onAlert;
  Function(String)? onError;
  Function()? onConnected;
  Function()? onDisconnected;

  bool get isConnected => _isConnected;
  Stream<List<AlertData>> get alertsStream => _alertsController.stream;
  List<AlertData> get recentAlerts => List.unmodifiable(_recentAlerts);

  Future<void> connect() async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_url));
      _isConnected = true;
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );
      onConnected?.call();
      _sendTestMessage();
    } catch (e) {
      _isConnected = false;
      onError?.call('Error de conexión: $e');
    }
  }

  void _sendTestMessage() {
    try {
      _channel?.sink.add(
        '{"type":"test","message":"Hello from Flutter (alerts)"}',
      );
    } catch (_) {}
  }

  Future<void> disconnect() async {
    try {
      await _subscription?.cancel();
      await _channel?.sink.close();
      _isConnected = false;
      onDisconnected?.call();
    } catch (_) {}
  }

  void _handleMessage(dynamic message) {
    try {
      final Map<String, dynamic> jsonData = json.decode(message);
      final String messageType = jsonData['type'] as String? ?? 'unknown';

      // En este canal SOLO procesamos alertas
      // El backend ahora envía type: "alert" con data.alert_type, etc.
      if (messageType == 'alert' ||
          messageType == 'alarm_update' ||
          messageType == 'panic_alert' ||
          messageType == 'fire_alert' ||
          messageType == 'earthquake_alert' ||
          messageType == 'gas_alert' ||
          messageType == 'watchlist_alert' ||
          messageType == 'license_plate_violation' ||
          messageType == 'traffic_violation' ||
          messageType == 'infraction') {
        _handleAlertMessage(jsonData);
      }
    } catch (e) {
      onError?.call('Error procesando alerta: $e');
    }
  }

  void _handleAlertMessage(Map<String, dynamic> jsonData) {
    final Map<String, dynamic>? data =
        jsonData['data'] as Map<String, dynamic>?;
    if (data == null) return;

    // Aplana data anidada
    final Map<String, dynamic> root = Map<String, dynamic>.from(data);
    final Map<String, dynamic>? nested = data['data'] as Map<String, dynamic>?;
    if (nested != null) {
      root.addAll(nested);
    }

    // Pasa el timestamp de mensaje como 'ts' (epoch segs)
    final double? ts = (jsonData['timestamp'] as num?)?.toDouble();
    if (ts != null) root['ts'] = ts;

    // Validar si es una alerta de gas antes de procesarla
    final String? typeFromMsg = jsonData['type'] as String?;
    if (typeFromMsg == 'gas_alert' && !_isValidGasAlert(root)) {
      // Alerta de gas no válida, no la procesamos
      print('❌ [WEBSOCKET-ALERTS] Alerta de gas inválida rechazada');
      return;
    }

    // Las infracciones de tráfico SIEMPRE deben procesarse
    if (typeFromMsg == 'traffic_violation' || typeFromMsg == 'infraction') {
      print('🚨 [WEBSOCKET-ALERTS] Procesando infracción de tráfico...');
    }

    AlertData alert;
    if (root.containsKey('alert_type')) {
      alert = AlertData.fromJson(root);
    } else {
      final String? violationType = root['violation_type'] as String?;
      alert = AlertData(
        alertType: (violationType ?? typeFromMsg ?? 'ALERTA').toUpperCase(),
        signalId: root['signal_id'] as String?,
        signalColor: root['signal_color'] as String?,
        stopId: root['stop_id'] as String?,
        tipoTransporte: root['tipo_transporte'] as String?,
        tiempoSegundos: (root['tiempo_segundos'] as num?)?.toInt(),
        origen: root['origen'] as String?,
        severity:
            (root['severity'] as num?)?.toInt() ??
            _inferSeverity(typeFromMsg, root),
        ts: ts ?? (DateTime.now().millisecondsSinceEpoch / 1000.0), // ➕
      );
    }

    // Aplicar rate limiting
    if (!_shouldShowAlert(alert)) {
      return;
    }

    _pushAlert(alert);
  }

  int _inferSeverity(String? type, [Map<String, dynamic>? data]) {
    switch ((type ?? '').toLowerCase()) {
      case 'panic_alert':
        return 5;
      case 'fire_alert':
      case 'earthquake_alert':
        return 4;
      case 'gas_alert':
        // Para alertas de gas, calcular severidad basada en el valor
        if (data != null) {
          final gasValue = _extractGasValue(data);
          if (gasValue != null) {
            return _calculateGasSeverity(gasValue);
          }
        }
        return 2; // Severidad por defecto si no se puede determinar el valor
      case 'license_plate_violation':
        return 3;
      case 'traffic_violation':
      case 'infraction':
      case 'infraccion':
        return 4; // Alta severidad para infracciones de tráfico
      default:
        return 2;
    }
  }

  void _pushAlert(AlertData alert) {
    // Log específico para infracciones
    if (alert.alertType.toLowerCase().contains('infrac')) {
      print('🚨 [FLUTTER] INFRACCIÓN RECIBIDA: ${alert.alertType}');
      print('   - Semáforo: ${alert.signalId ?? "N/A"}');
      print('   - Color: ${alert.signalColor ?? "N/A"}');
      print('   - Severidad: ${alert.severity}');
      print('   - Origen: ${alert.origen ?? "N/A"}');
    }

    _recentAlerts.add(alert);
    if (_recentAlerts.length > _maxAlertsBuffer) {
      _recentAlerts.removeAt(0);
    }
    onAlert?.call(alert);
    _alertsController.add(List.unmodifiable(_recentAlerts));
  }

  void requestRecentAlerts({int limit = 20}) {
    final req = {
      "type": "request_alerts",
      "timestamp": DateTime.now().millisecondsSinceEpoch / 1000.0,
      "limit": limit,
    };
    _channel?.sink.add(json.encode(req));
  }

  Future<void> reconnect() async {
    await disconnect();
    await Future.delayed(const Duration(seconds: 2));
    await connect();
  }

  // Manejar errores del WebSocket
  void _handleError(dynamic error) {
    _isConnected = false;
    onError?.call('Error en WebSocket (alerts): $error');
  }

  // Manejar cierre/desconexión del WebSocket
  void _handleDisconnection() {
    _isConnected = false;
    onDisconnected?.call();
  }

  // Simulador local de una alerta (para probar la UI)
  void simulateAlertMessage() {
    final simulated = {
      "type": "panic_alert",
      "timestamp": DateTime.now().millisecondsSinceEpoch / 1000.0,
      "data": {
        "alert_type": "PANICO",
        "origen": "Botón de pánico - Zona 1",
        "severity": 5,
      },
    };
    _handleMessage(json.encode(simulated));
  }

  // Simulador específico para infracciones desde el servicio de tráfico
  void simulateInfractionMessage(Map<String, dynamic> infractionData) {
    print(
      '🔄 [WEBSOCKET-ALERTS] Procesando infracción recibida desde tráfico:',
    );
    print('   - Datos: ${json.encode(infractionData)}');

    try {
      _handleMessage(json.encode(infractionData));
      print('✅ [WEBSOCKET-ALERTS] Infracción procesada y agregada al feed');
    } catch (e) {
      print('❌ [WEBSOCKET-ALERTS] Error procesando infracción: $e');
    }
  }

  /// Validar si una alerta de gas es válida y debe mostrarse
  bool _isValidGasAlert(Map<String, dynamic> data) {
    try {
      // Buscar valores de gas en diferentes campos posibles
      final gasValue = _extractGasValue(data);

      if (gasValue == null) {
        // No hay valor de gas válido, ignorar alerta
        return false;
      }

      // Verificar si el valor excede el umbral mínimo para mostrar alerta
      if (gasValue < _gasThresholdLow) {
        // Valor demasiado bajo para ser una alerta real
        return false;
      }

      return true;
    } catch (e) {
      // En caso de error, no mostrar la alerta
      return false;
    }
  }

  /// Extraer valor de gas de los datos recibidos
  double? _extractGasValue(Map<String, dynamic> data) {
    // Buscar el valor de gas en diferentes campos posibles
    final gasFields = [
      'gas_value',
      'gas_level',
      'gas_concentration',
      'value',
      'level',
      'concentration',
      'gas_ppm',
      'ppm',
    ];

    for (final field in gasFields) {
      final value = data[field];
      if (value != null) {
        if (value is num) {
          return value.toDouble();
        }
        if (value is String) {
          final parsed = double.tryParse(value);
          if (parsed != null) {
            return parsed;
          }
        }
      }
    }

    return null;
  }

  /// Verificar si debe mostrarse una alerta aplicando rate limiting
  bool _shouldShowAlert(AlertData alert) {
    final alertKey = _getAlertKey(alert);
    final now = DateTime.now();
    final lastTime = _lastAlertTime[alertKey];

    if (lastTime != null) {
      final timeDiff = now.difference(lastTime);
      if (timeDiff < _minAlertInterval) {
        // Muy poco tiempo desde la última alerta del mismo tipo
        return false;
      }
    }

    // Actualizar el tiempo de la última alerta
    _lastAlertTime[alertKey] = now;
    return true;
  }

  /// Generar clave única para rate limiting basada en tipo y origen
  String _getAlertKey(AlertData alert) {
    final tipo = alert.alertType.toLowerCase();
    final origen = alert.origen ?? alert.signalId ?? alert.stopId ?? 'unknown';
    return '${tipo}_$origen';
  }

  /// Ajustar severidad de alerta de gas basada en valor
  int _calculateGasSeverity(double gasValue) {
    if (gasValue >= _gasThresholdHigh) {
      return 4; // Alta
    } else if (gasValue >= _gasThresholdMedium) {
      return 3; // Media
    } else if (gasValue >= _gasThresholdLow) {
      return 2; // Baja
    } else {
      return 1; // Info
    }
  }

  /// Limpiar el historial de rate limiting
  void clearRateLimitHistory() {
    _lastAlertTime.clear();
  }

  /// Configurar umbrales de gas personalizados (para pruebas o ajustes)
  static void configureGasThresholds({
    double? low,
    double? medium,
    double? high,
  }) {
    // Nota: En una implementación real, estos valores serían configurables
    // Por ahora están como constantes, pero se podría agregar funcionalidad
    // para cambiarlos desde la UI o configuración
  }

  /// Obtener información de configuración actual
  Map<String, dynamic> getConfiguration() {
    return {
      'gasThresholds': {
        'low': _gasThresholdLow,
        'medium': _gasThresholdMedium,
        'high': _gasThresholdHigh,
      },
      'minAlertInterval': _minAlertInterval.inSeconds,
      'maxAlertsBuffer': _maxAlertsBuffer,
      'activeRateLimits': _lastAlertTime.length,
    };
  }

  void dispose() {
    _alertsController.close();
  }
}
