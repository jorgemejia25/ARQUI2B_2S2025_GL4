import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/websocket_message.dart';
import 'config_service.dart';

class BusStopWebSocketService {
  static BusStopWebSocketService? _instance;
  static BusStopWebSocketService get instance =>
      _instance ??= BusStopWebSocketService._();

  BusStopWebSocketService._();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  // Callbacks para manejar los mensajes
  Function(EtaUpdateMessage)? onEtaUpdate;
  Function(String)? onError;
  Function()? onConnected;
  Function()? onDisconnected;

  bool get isConnected => _isConnected;

  /// Obtener URL del WebSocket de paradas desde ConfigService
  String get _url {
    final configService = ConfigService.instance;
    return configService.getServiceUrls()['wsStops'] ??
        'ws://192.168.1.158:8001/ws/stops';
  }

  /// Conectar al WebSocket de paradas
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
    } catch (e) {
      _isConnected = false;
      onError?.call('Error conectando a WebSocket de paradas: $e');
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
      // Error silencioso
    }
  }

  /// Manejar mensajes recibidos
  void _handleMessage(dynamic message) {
    try {
      final Map<String, dynamic> jsonData = json.decode(message);

      final String messageType = jsonData['type'] as String? ?? 'unknown';

      // Manejar diferentes tipos de mensajes
      switch (messageType) {
        case 'stop_update':
          _handleStopUpdateMessage(jsonData);
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
      onError?.call('Error procesando mensaje de parada: $e');
    }
  }

  /// Manejar mensaje de actualización de parada
  void _handleStopUpdateMessage(Map<String, dynamic> jsonData) {
    try {
      final data = jsonData['data'] as Map<String, dynamic>;
      final eventType = data['event_type'] as String?;

      if (eventType == 'eta_update') {
        _handleEtaUpdateFromStopMessage(data);
      }
    } catch (e) {
      onError?.call('Error procesando mensaje de parada: $e');
    }
  }

  /// Manejar actualización de ETA desde mensaje de parada
  void _handleEtaUpdateFromStopMessage(Map<String, dynamic> data) {
    try {
      // Unificar IDs de paradas (algunos backends envían P2_2)
      String stopId = data['stop_id'] as String;
      if (stopId == 'P2_2') stopId = 'P2';
      final etaInfo = data['eta_info'] as Map<String, dynamic>;
      final alertData = data['data'] as Map<String, dynamic>;

      // Crear mensaje ETA compatible con el formato esperado
      final etaMessage = EtaUpdateMessage(
        type: 'eta_update',
        timestamp: DateTime.now().millisecondsSinceEpoch / 1000.0,
        data: EtaUpdateData(
          alertType: alertData['alert_type'] as String,
          stopId: stopId,
          tipoTransporte: etaInfo['tipo_transporte'] as String,
          tiempoSegundos: etaInfo['tiempo_segundos'] as int,
          origen: etaInfo['origen'] as String,
          severity: alertData['severity'] as int,
        ),
      );

      onEtaUpdate?.call(etaMessage);
    } catch (e) {
      onError?.call('Error procesando ETA desde parada: $e');
    }
  }

  /// Manejar mensaje de conexión establecida
  void _handleConnectionEstablishedMessage(Map<String, dynamic> jsonData) {
    onConnected?.call();
  }

  /// Manejar errores de WebSocket
  void _handleError(dynamic error) {
    _isConnected = false;

    // Manejar diferentes tipos de errores
    if (error.toString().contains('SocketException')) {
      _scheduleReconnect();
    } else {
      onError?.call('Error en WebSocket de paradas: $error');
    }
  }

  /// Manejar desconexión
  void _handleDisconnection() {
    _isConnected = false;
    _scheduleReconnect();
    onDisconnected?.call();
  }

  /// Reconectar al WebSocket
  Future<void> reconnect() async {
    await disconnect();
    await Future.delayed(const Duration(seconds: 2));
    await connect();
  }

  /// Simular mensaje de ETA para pruebas
  void simulateEtaMessage() {
    final simulatedMessage = EtaUpdateMessage(
      type: 'eta_update',
      timestamp: DateTime.now().millisecondsSinceEpoch / 1000.0,
      data: EtaUpdateData(
        alertType: 'ETA_UPDATE',
        stopId: 'P3',
        tipoTransporte: 'Transurbano',
        tiempoSegundos: 120,
        origen: 'Centro',
        severity: 1,
      ),
    );

    onEtaUpdate?.call(simulatedMessage);
  }

  /// Verificar conectividad de red
  Future<bool> checkNetworkConnectivity() async {
    try {
      // Aquí podrías implementar una verificación de ping o similar
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Programar reconexión automática con backoff exponencial
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      onError?.call(
        'No se pudo reconectar WebSocket de paradas después de $_maxReconnectAttempts intentos',
      );
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectAttempts++;

    // Backoff exponencial: 2, 4, 8, 16, 32 segundos
    final delay = Duration(seconds: 2 * _reconnectAttempts);

    _reconnectTimer = Timer(delay, () async {
      try {
        await connect();
        if (_isConnected) {
          _reconnectAttempts = 0; // Resetear contador en conexión exitosa
        }
      } catch (e) {
        _scheduleReconnect(); // Intentar de nuevo
      }
    });
  }
}
