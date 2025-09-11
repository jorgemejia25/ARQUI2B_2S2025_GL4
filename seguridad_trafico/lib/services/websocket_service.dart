import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/websocket_message.dart';
import '../models/traffic_light.dart';

class WebSocketService {
  static WebSocketService? _instance;
  static WebSocketService get instance => _instance ??= WebSocketService._();

  WebSocketService._();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  String _url = 'wss://arqui2b2s2025gl4-production.up.railway.app/ws/traffic';
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  // Callbacks para manejar los mensajes
  Function(WebSocketMessage)? onTrafficUpdate;
  Function(EtaUpdateMessage)? onEtaUpdate;
  Function(String)? onError;
  Function()? onConnected;
  Function()? onDisconnected;

  bool get isConnected => _isConnected;

  /// Conectar al WebSocket
  Future<void> connect() async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_url));

      _isConnected = true;

      // Escuchar mensajes
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );

      onConnected?.call();

      // Enviar un mensaje de prueba para verificar la conexión
      _sendTestMessage();
    } catch (e) {
      _isConnected = false;
      onError?.call('Error de conexión: $e');
    }
  }

  /// Enviar mensaje de prueba
  void _sendTestMessage() {
    try {
      final testMessage = '{"type": "test", "message": "Hello from Flutter"}';
      _channel?.sink.add(testMessage);
    } catch (e) {
      // Error enviando mensaje de prueba
    }
  }

  /// Desconectar del WebSocket
  Future<void> disconnect() async {
    try {
      _reconnectTimer?.cancel();
      await _subscription?.cancel();
      await _channel?.sink.close();
      _isConnected = false;
      _reconnectAttempts = 0;
      onDisconnected?.call();
    } catch (e) {
      print('Error desconectando WebSocket: $e');
    }
  }

  /// Manejar mensajes recibidos
  void _handleMessage(dynamic message) {
    try {
      final Map<String, dynamic> jsonData = json.decode(message);

      final String messageType = jsonData['type'] as String? ?? 'unknown';

      // Manejar diferentes tipos de mensajes
      switch (messageType) {
        case 'traffic_update':
          _handleTrafficUpdateMessage(jsonData);
          break;
        case 'eta_update':
          _handleEtaUpdateMessage(jsonData);
          break;
        case 'connection_established':
          _handleConnectionEstablishedMessage(jsonData);
          break;
        case 'test':
          break;
        default:
          // Tipo de mensaje no reconocido
          break;
      }
    } catch (e) {
      onError?.call('Error procesando mensaje: $e');
    }
  }

  /// Manejar mensaje de actualización de tráfico
  void _handleTrafficUpdateMessage(Map<String, dynamic> jsonData) {
    try {
      // Extraer datos directamente del formato del servidor
      final data = jsonData['data'] as Map<String, dynamic>;
      final signalId = data['signal_id'] as String;
      final signalColor = data['signal_color'] as String;

      // Procesar directamente sin usar el modelo WebSocketMessage
      _processTrafficUpdateDirect(signalId, signalColor, jsonData);
    } catch (e) {
      onError?.call('Error procesando mensaje de tráfico: $e');
    }
  }

  /// Procesar actualización de tráfico directamente
  void _processTrafficUpdateDirect(
    String signalId,
    String signalColor,
    Map<String, dynamic> fullMessage,
  ) {
    // Extraer datos adicionales del mensaje completo
    final data = fullMessage['data'] as Map<String, dynamic>;
    final violationType = data['violation_type'] as String? ?? 'signal_update';
    final alertType = violationType == 'red_light'
        ? 'INFRACCION'
        : 'SIGNAL_UPDATE';
    final severity = violationType == 'red_light' ? 3 : 1;

    // Mapear el ID del semáforo del WebSocket al ID del SVG
    final svgId = _mapSignalIdToSvgId(signalId);
    if (svgId == null) {
      return;
    }

    // Mapear el color del WebSocket al estado del semáforo
    final trafficState = _mapColorToTrafficState(signalColor);

    if (trafficState == null) {
      return;
    }

    // Crear un mensaje simplificado para el callback
    final simplifiedMessage = WebSocketMessage(
      type: 'traffic_update',
      timestamp: DateTime.now().millisecondsSinceEpoch / 1000.0,
      data: TrafficUpdateData(
        signalId: signalId,
        signalColor: signalColor,
        violationType: violationType,
        timestamp: DateTime.now().toIso8601String(),
        alertData: AlertData(
          alertType: alertType,
          signalId: signalId,
          signalColor: signalColor,
          severity: severity,
        ),
      ),
    );

    onTrafficUpdate?.call(simplifiedMessage);
  }

  /// Manejar mensaje de conexión establecida
  void _handleConnectionEstablishedMessage(Map<String, dynamic> jsonData) {
    // No necesitamos procesar este mensaje, solo confirmar la conexión
  }

  /// Manejar mensaje de actualización de ETA
  void _handleEtaUpdateMessage(Map<String, dynamic> jsonData) {
    try {
      final EtaUpdateMessage etaMessage = EtaUpdateMessage.fromJson(jsonData);

      onEtaUpdate?.call(etaMessage);
    } catch (e) {
      onError?.call('Error procesando mensaje de ETA: $e');
    }
  }

  /// Mapear ID del WebSocket al ID del SVG
  String? _mapSignalIdToSvgId(String signalId) {
    // El servidor está enviando IDs directos (S1, S2, etc.) en lugar de SEMAFORO_001
    // Verificar si ya es un ID válido del SVG
    if (signalId.startsWith('S') && signalId.length <= 3) {
      // Es un ID directo del SVG (S1, S2, S3, etc.)
      return signalId;
    }

    // Mapeo de IDs del WebSocket a IDs del SVG (para compatibilidad)
    final Map<String, String> idMapping = {
      'SEMAFORO_001': 'S1',
      'SEMAFORO_002': 'S2',
      'SEMAFORO_003': 'S3',
      'SEMAFORO_004': 'S4',
      'SEMAFORO_005': 'S5',
      'SEMAFORO_006': 'S6',
      'SEMAFORO_007': 'S7',
      'SEMAFORO_008': 'S8',
      'SEMAFORO_009': 'S9',
      'SEMAFORO_010': 'S10',
    };

    return idMapping[signalId];
  }

  /// Mapear color del WebSocket al estado del semáforo
  TrafficLightState? _mapColorToTrafficState(String color) {
    switch (color.toLowerCase()) {
      case 'red':
        return TrafficLightState.red;
      case 'yellow':
        return TrafficLightState.yellow;
      case 'green':
        return TrafficLightState.green;
      case 'off':
        return TrafficLightState.off;
      default:
        return null;
    }
  }

  /// Manejar errores
  void _handleError(dynamic error) {
    _isConnected = false;
    print('WebSocket Error: $error');

    // Manejar diferentes tipos de errores
    if (error.toString().contains('SocketException')) {
      print('SocketException detectada - intentando reconectar...');
      _scheduleReconnect();
    } else {
      onError?.call('Error en WebSocket: $error');
    }
  }

  /// Manejar desconexión
  void _handleDisconnection() {
    _isConnected = false;
    print('WebSocket desconectado - intentando reconectar...');
    _scheduleReconnect();
    onDisconnected?.call();
  }

  /// Enviar mensaje (si es necesario)
  void sendMessage(String message) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(message);
    }
  }

  /// Cambiar URL del WebSocket
  void setUrl(String url) {
    _url = url;
  }

  /// Obtener estado de conexión
  String getConnectionStatus() {
    if (_isConnected) {
      return 'Conectado a $_url';
    } else {
      return 'Desconectado';
    }
  }

  /// Verificar conectividad de red
  Future<bool> checkNetworkConnectivity() async {
    try {
      Uri.parse(_url);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Reconectar manualmente
  Future<void> reconnect() async {
    await disconnect();
    await Future.delayed(const Duration(seconds: 2));
    await connect();
  }

  /// Simular mensaje de tráfico para pruebas
  void simulateTrafficMessage() {
    final simulatedMessage = {
      "type": "traffic_update",
      "timestamp": DateTime.now().millisecondsSinceEpoch / 1000.0,
      "data": {
        "signal_id": "SEMAFORO_001",
        "signal_color": "red",
        "violation_type": "red_light",
        "timestamp": DateTime.now().toIso8601String(),
        "data": {
          "alert_type": "INFRACCION",
          "signal_id": "SEMAFORO_001",
          "signal_color": "red",
          "severity": 3,
        },
      },
    };

    final jsonString = json.encode(simulatedMessage);
    _handleMessage(jsonString);
  }

  /// Solicitar actualización de tráfico al servidor
  void requestTrafficUpdate() {
    final requestMessage = {
      "type": "request_traffic_update",
      "timestamp": DateTime.now().millisecondsSinceEpoch / 1000.0,
      "message": "Solicitando estado actual de semáforos",
    };

    final jsonString = json.encode(requestMessage);
    sendMessage(jsonString);
  }

  /// Programar reconexión automática con backoff exponencial
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('Máximo número de intentos de reconexión alcanzado');
      onError?.call(
        'No se pudo reconectar después de $_maxReconnectAttempts intentos',
      );
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectAttempts++;

    // Backoff exponencial: 2, 4, 8, 16, 32 segundos
    final delay = Duration(seconds: 2 * _reconnectAttempts);
    print(
      'Reconectando en ${delay.inSeconds} segundos (intento $_reconnectAttempts/$_maxReconnectAttempts)',
    );

    _reconnectTimer = Timer(delay, () async {
      try {
        await connect();
        if (_isConnected) {
          _reconnectAttempts = 0; // Resetear contador en conexión exitosa
          print('Reconexión exitosa');
        }
      } catch (e) {
        print('Error en reconexión: $e');
        _scheduleReconnect(); // Intentar de nuevo
      }
    });
  }
}
