import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';
import '../models/weapon_event.dart';

/// Servicio WebSocket para recibir eventos de armas en tiempo real
class WebSocketWeaponsService {
  WebSocketWeaponsService._internal();
  static final WebSocketWeaponsService instance = WebSocketWeaponsService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  void Function(WeaponEvent event)? onEvent;
  void Function(String message)? onError;
  void Function()? onConnected;
  void Function()? onDisconnected;

  Future<void> connect() async {
    if (isConnected) return;
    try {
      final uri = Uri.parse('${ApiConfig.wsBaseUrl}/ws/weapons');
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;
      onConnected?.call();
  _subscription = _channel!.stream.listen((message) {
        try {
          final data = json.decode(message);
          if (data is Map<String, dynamic> && data['type'] == 'weapon_detection') {
            final payload = (data['data'] ?? data['payload']) as Map<String, dynamic>;
            final event = WeaponEvent.fromJson(payload);
            onEvent?.call(event);
          }
        } catch (e) {
          onError?.call('Error procesando WS: $e');
        }
      }, onError: (err) {
        onError?.call('WebSocket error: $err');
        disconnect();
      }, onDone: () {
        disconnect();
      });
    } catch (e) {
      onError?.call('No se pudo conectar WS: $e');
      rethrow;
    }
  }

  Future<void> reconnect() async {
    disconnect();
    await connect();
  }

  void disconnect() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    onDisconnected?.call();
  }
}
