import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/plate_event.dart';

class PlateEventService {
  static final PlateEventService instance = PlateEventService._();
  PlateEventService._();

  final String _apiUrl = '${ApiConfig.baseUrl}/api/v1/plate-events';

  /// Obtiene eventos de detección de placas desde el backend
  Future<List<PlateEvent>> fetchEvents({int limit = 50, int offset = 0}) async {
    try {
      final uri = Uri.parse('$_apiUrl?limit=$limit&offset=$offset');
      print('[PlateEventService] Fetching from $uri');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic jsonBody = json.decode(response.body);

        // El backend devuelve un objeto con clave "events"
        if (jsonBody is Map<String, dynamic>) {
          final List<dynamic> eventList = jsonBody['events'] ?? [];
          return eventList
              .map((item) => PlateEvent.fromJson(item as Map<String, dynamic>))
              .toList();
        }

        // Fallback: si el backend devuelve una lista directamente
        if (jsonBody is List<dynamic>) {
          return jsonBody
              .map((item) => PlateEvent.fromJson(item as Map<String, dynamic>))
              .toList();
        }

        throw Exception('Formato de respuesta no esperado del servidor');
      } else {
        throw Exception('Error al obtener eventos: ${response.statusCode}');
      }
    } catch (e) {
      print('[PlateEventService] Error: $e');
      rethrow;
    }
  }
}
