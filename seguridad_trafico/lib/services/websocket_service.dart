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
  String _url = 'ws://192.168.1.181:8001/ws/traffic';

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
      print('🔌 Conectando a WebSocket: $_url');
      print('🔍 URI parseada: ${Uri.parse(_url)}');

      _channel = WebSocketChannel.connect(Uri.parse(_url));
      print('📡 Canal WebSocket creado');

      _isConnected = true;
      print('✅ Estado de conexión establecido como true');

      // Escuchar mensajes
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );
      print('👂 Suscripción a mensajes establecida');

      onConnected?.call();
      print('✅ WebSocket conectado exitosamente');

      // Enviar un mensaje de prueba para verificar la conexión
      _sendTestMessage();
    } catch (e) {
      print('❌ Error conectando WebSocket: $e');
      _isConnected = false;
      onError?.call('Error de conexión: $e');
    }
  }

  /// Enviar mensaje de prueba
  void _sendTestMessage() {
    try {
      print('🧪 Enviando mensaje de prueba...');
      final testMessage = '{"type": "test", "message": "Hello from Flutter"}';
      _channel?.sink.add(testMessage);
      print('📤 Mensaje de prueba enviado: $testMessage');
    } catch (e) {
      print('❌ Error enviando mensaje de prueba: $e');
    }
  }

  /// Desconectar del WebSocket
  Future<void> disconnect() async {
    try {
      await _subscription?.cancel();
      await _channel?.sink.close();
      _isConnected = false;
      onDisconnected?.call();
      print('🔌 WebSocket desconectado');
    } catch (e) {
      print('❌ Error desconectando WebSocket: $e');
    }
  }

  /// Manejar mensajes recibidos
  void _handleMessage(dynamic message) {
    try {
      print('📨 Mensaje recibido: $message');
      print('📨 Tipo de mensaje: ${message.runtimeType}');
      print('📨 Longitud del mensaje: ${message.toString().length}');

      final Map<String, dynamic> jsonData = json.decode(message);
      print('📨 JSON decodificado: $jsonData');

      final String messageType = jsonData['type'] as String? ?? 'unknown';
      print('📨 Tipo de mensaje identificado: $messageType');

      // Manejar diferentes tipos de mensajes
      switch (messageType) {
        case 'traffic_update':
          print('🚦 Procesando mensaje de tráfico...');
          _handleTrafficUpdateMessage(jsonData);
          break;
        case 'eta_update':
          print('🚌 Procesando mensaje de ETA...');
          _handleEtaUpdateMessage(jsonData);
          break;
        case 'connection_established':
          print('🔗 Procesando mensaje de conexión...');
          _handleConnectionEstablishedMessage(jsonData);
          break;
        case 'test':
          print('🧪 Mensaje de prueba recibido');
          break;
        default:
          print('⚠️ Tipo de mensaje no reconocido: $messageType');
          print('⚠️ Contenido completo: $jsonData');
      }
    } catch (e) {
      print('❌ Error procesando mensaje: $e');
      print('❌ Mensaje que causó el error: $message');
      onError?.call('Error procesando mensaje: $e');
    }
  }

  /// Manejar mensaje de actualización de tráfico
  void _handleTrafficUpdateMessage(Map<String, dynamic> jsonData) {
    try {
      print('🚦 Procesando mensaje de tráfico...');

      // Extraer datos directamente del formato del servidor
      final data = jsonData['data'] as Map<String, dynamic>;
      final signalId = data['signal_id'] as String;
      final signalColor = data['signal_color'] as String;

      print('🚦 Datos extraídos: $signalId -> $signalColor');

      // Procesar directamente sin usar el modelo WebSocketMessage
      _processTrafficUpdateDirect(signalId, signalColor, jsonData);
    } catch (e) {
      print('❌ Error procesando mensaje de tráfico: $e');
      print('❌ Datos del mensaje: $jsonData');
      onError?.call('Error procesando mensaje de tráfico: $e');
    }
  }

  /// Procesar actualización de tráfico directamente
  void _processTrafficUpdateDirect(
    String signalId,
    String signalColor,
    Map<String, dynamic> fullMessage,
  ) {
    print('🚦 Procesando actualización directa: $signalId -> $signalColor');

    // Extraer datos adicionales del mensaje completo
    final data = fullMessage['data'] as Map<String, dynamic>;
    final violationType = data['violation_type'] as String? ?? 'signal_update';
    final alertType = violationType == 'red_light'
        ? 'INFRACCION'
        : 'SIGNAL_UPDATE';
    final severity = violationType == 'red_light' ? 3 : 1;

    print(
      '📊 Datos del mensaje: violationType=$violationType, alertType=$alertType, severity=$severity',
    );

    // Mapear el ID del semáforo del WebSocket al ID del SVG
    final svgId = _mapSignalIdToSvgId(signalId);
    print('🔍 ID mapeado: $signalId -> $svgId');

    if (svgId == null) {
      print('⚠️ ID de semáforo no reconocido: $signalId');
      return;
    }

    // Mapear el color del WebSocket al estado del semáforo
    final trafficState = _mapColorToTrafficState(signalColor);
    print('🎨 Color mapeado: $signalColor -> $trafficState');

    if (trafficState == null) {
      print('⚠️ Color de semáforo no reconocido: $signalColor');
      return;
    }

    print(
      '🔄 Actualizando semáforo $svgId a estado $trafficState (severity: $severity)',
    );
    print('📞 Llamando callback onTrafficUpdate...');

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
    print('✅ Conexión WebSocket establecida: ${jsonData['message']}');
    // No necesitamos procesar este mensaje, solo confirmar la conexión
  }

  /// Manejar mensaje de actualización de ETA
  void _handleEtaUpdateMessage(Map<String, dynamic> jsonData) {
    try {
      print('🚌 Procesando mensaje de ETA...');

      final EtaUpdateMessage etaMessage = EtaUpdateMessage.fromJson(jsonData);
      print(
        '🚌 ETA procesado: ${etaMessage.data.stopId} - ${etaMessage.data.tipoTransporte} - ${etaMessage.data.tiempoFormateado}',
      );

      onEtaUpdate?.call(etaMessage);
    } catch (e) {
      print('❌ Error procesando mensaje de ETA: $e');
      print('❌ Datos del mensaje: $jsonData');
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
    print('❌ Error en WebSocket: $error');
    print('❌ Tipo de error: ${error.runtimeType}');
    print('❌ Stack trace: ${StackTrace.current}');
    _isConnected = false;
    onError?.call('Error en WebSocket: $error');
  }

  /// Manejar desconexión
  void _handleDisconnection() {
    print('🔌 WebSocket desconectado');
    _isConnected = false;
    onDisconnected?.call();
  }

  /// Enviar mensaje (si es necesario)
  void sendMessage(String message) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(message);
    } else {
      print('⚠️ No se puede enviar mensaje: WebSocket no conectado');
    }
  }

  /// Cambiar URL del WebSocket
  void setUrl(String url) {
    _url = url;
    print('🔧 URL del WebSocket actualizada: $_url');
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
      print('🌐 Verificando conectividad de red...');
      final uri = Uri.parse(_url);
      print('🌐 Host: ${uri.host}');
      print('🌐 Puerto: ${uri.port}');
      print('🌐 Esquema: ${uri.scheme}');
      return true;
    } catch (e) {
      print('❌ Error verificando conectividad: $e');
      return false;
    }
  }

  /// Reconectar manualmente
  Future<void> reconnect() async {
    print('🔄 Reconectando WebSocket...');
    await disconnect();
    await Future.delayed(const Duration(seconds: 2));
    await connect();
  }

  /// Simular mensaje de tráfico para pruebas
  void simulateTrafficMessage() {
    print('🧪 Simulando mensaje de tráfico...');
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
    print('🧪 Mensaje simulado: $jsonString');
    _handleMessage(jsonString);
  }

  /// Solicitar actualización de tráfico al servidor
  void requestTrafficUpdate() {
    print('📡 Solicitando actualización de tráfico...');
    final requestMessage = {
      "type": "request_traffic_update",
      "timestamp": DateTime.now().millisecondsSinceEpoch / 1000.0,
      "message": "Solicitando estado actual de semáforos",
    };

    final jsonString = json.encode(requestMessage);
    sendMessage(jsonString);
  }
}
