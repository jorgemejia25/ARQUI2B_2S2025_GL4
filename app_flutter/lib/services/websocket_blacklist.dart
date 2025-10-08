// Servicio WebSocket para eventos de lista negra
// Basado en websocket_alerts.dart pero especializado para eventos de blacklist

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import '../models/blacklist_event.dart';
import '../models/blacklist_stats.dart';
import '../config/api_config.dart';

class WebSocketBlacklistService {
  static WebSocketBlacklistService? _instance;
  static WebSocketBlacklistService get instance =>
      _instance ??= WebSocketBlacklistService._();
  WebSocketBlacklistService._();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  final String _wsUrl = '${ApiConfig.wsBaseUrl}/ws/blacklist';
  final String _apiUrl = '${ApiConfig.baseUrl}/api/v1';

  // Buffer + stream para eventos en tiempo real
  final List<BlacklistEvent> _recentEvents = [];
  static const int _maxEventsBuffer = 100;
  final StreamController<List<BlacklistEvent>> _eventsController =
      StreamController<List<BlacklistEvent>>.broadcast();

  // Cache para eventos históricos
  final Map<String, BlacklistEventsResponse> _cache = {};

  // Callbacks opcionales
  Function(BlacklistEvent)? onEvent;
  Function(String)? onError;
  Function()? onConnected;
  Function()? onDisconnected;

  bool get isConnected => _isConnected;
  Stream<List<BlacklistEvent>> get eventsStream => _eventsController.stream;
  List<BlacklistEvent> get recentEvents => List.unmodifiable(_recentEvents);

  Future<void> connect() async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
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
      onError?.call('Error de conexión blacklist: $e');
    }
  }

  void _sendTestMessage() {
    try {
      _channel?.sink.add(
        '{"type":"test","message":"Hello from Flutter (blacklist)"}',
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

      // Procesar solo eventos de blacklist
      if (messageType == 'blacklist_event') {
        _handleBlacklistEventMessage(jsonData);
      }
    } catch (e) {
      onError?.call('Error procesando evento blacklist: $e');
    }
  }

  void _handleBlacklistEventMessage(Map<String, dynamic> jsonData) {
    try {
      final BlacklistEvent event = BlacklistEvent.fromWebSocketJson(jsonData);

      // Agregar al inicio de la lista (eventos más recientes primero)
      _recentEvents.insert(0, event);

      // Mantener tamaño del buffer
      if (_recentEvents.length > _maxEventsBuffer) {
        _recentEvents.removeLast();
      }

      onEvent?.call(event);
      _eventsController.add(List.unmodifiable(_recentEvents));
    } catch (e) {
      onError?.call('Error procesando evento blacklist: $e');
    }
  }

  /// Obtener eventos históricos del API con paginación
  Future<BlacklistEventsResponse> fetchHistoricalEvents({
    int limit = 50,
    int offset = 0,
    String? personFilter,
  }) async {
    try {
      // Crear cache key
      final cacheKey = '${limit}_${offset}_${personFilter ?? 'all'}';

      // Verificar cache (válido por 30 segundos)
      if (_cache.containsKey(cacheKey)) {
        return _cache[cacheKey]!;
      }

      // Construir URL con parámetros
      final uri = Uri.parse('$_apiUrl/blacklist-events').replace(
        queryParameters: {
          'limit': limit.toString(),
          'offset': offset.toString(),
          if (personFilter != null && personFilter.isNotEmpty)
            'person': personFilter,
        },
      );

      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final result = BlacklistEventsResponse.fromJson(jsonData);

        print(
          '[WebSocketBlacklist] Fetched ${result.events.length} events from API',
        );

        // Cachear resultado
        _cache[cacheKey] = result;

        // Limpiar cache después de 30 segundos
        Timer(const Duration(seconds: 30), () {
          _cache.remove(cacheKey);
        });

        return result;
      } else {
        print('[WebSocketBlacklist] API Error: ${response.statusCode}');
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      onError?.call('Error obteniendo eventos históricos: $e');
      rethrow;
    }
  }

  /// Obtener eventos de una persona específica
  Future<List<BlacklistEvent>> fetchEventsByPerson(
    String personName, {
    int limit = 10,
  }) async {
    try {
      final uri = Uri.parse(
        '$_apiUrl/blacklist-events/person/$personName',
      ).replace(queryParameters: {'limit': limit.toString()});

      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final eventsList = jsonData['events'] as List;

        return eventsList
            .map((e) => BlacklistEvent.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      onError?.call('Error obteniendo eventos de persona: $e');
      rethrow;
    }
  }

  /// Simular evento para pruebas
  void simulateEvent() {
    final simulated = {
      "type": "blacklist_event",
      "timestamp": DateTime.now().millisecondsSinceEpoch / 1000.0,
      "data": {
        "blacklist_event_id": DateTime.now().millisecondsSinceEpoch,
        "person_name": "PERSONA_PRUEBA",
        "confidence": 0.85,
        "distance": 0.15,
        "camera_location": "Cámara de Prueba",
      },
    };
    _handleMessage(json.encode(simulated));
  }

  Future<void> reconnect() async {
    await disconnect();
    await Future.delayed(const Duration(seconds: 2));
    await connect();
  }

  // Manejar errores del WebSocket
  void _handleError(dynamic error) {
    _isConnected = false;
    onError?.call('Error en WebSocket blacklist: $error');
  }

  // Manejar cierre/desconexión del WebSocket
  void _handleDisconnection() {
    _isConnected = false;
    onDisconnected?.call();
  }

  /// Limpiar cache
  void clearCache() {
    _cache.clear();
    print('[WebSocketBlacklist] Cache cleared');
  }

  /// Obtener estadísticas de personas más detectadas
  Future<List<BlacklistStats>> fetchTopDetections({int limit = 10}) async {
    try {
      final uri = Uri.parse(
        '$_apiUrl/blacklist-events/stats/top-detections',
      ).replace(queryParameters: {'limit': limit.toString()});

      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final statsList = jsonData['stats'] as List;

        print('[WebSocketBlacklist] Fetched ${statsList.length} person stats');

        return statsList
            .map((s) => BlacklistStats.fromJson(s as Map<String, dynamic>))
            .toList();
      } else {
        print('[WebSocketBlacklist] Stats API Error: ${response.statusCode}');
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      onError?.call('Error obteniendo estadísticas: $e');
      rethrow;
    }
  }

  /// Obtener estadísticas del servicio
  Map<String, dynamic> getStats() {
    return {
      'isConnected': _isConnected,
      'recentEventsCount': _recentEvents.length,
      'cacheSize': _cache.length,
      'wsUrl': _wsUrl,
      'apiUrl': _apiUrl,
    };
  }

  void dispose() {
    _eventsController.close();
  }
}
