/// Modelo para eventos de lista negra
/// Representa un evento de detección de persona en lista negra
class BlacklistEvent {
  final int id;
  final DateTime timestamp;
  final String personName;
  final double confidence;
  final double distance;
  final String? cameraLocation;

  const BlacklistEvent({
    required this.id,
    required this.timestamp,
    required this.personName,
    required this.confidence,
    required this.distance,
    this.cameraLocation,
  });

  /// Crear instancia desde JSON (API response)
  factory BlacklistEvent.fromJson(Map<String, dynamic> json) {
    return BlacklistEvent(
      id: json['blacklist_event_id'] as int,
      timestamp: DateTime.parse(json['ts'] as String),
      personName: json['person_name'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      distance: (json['distance'] as num).toDouble(),
      cameraLocation: json['camera_location'] as String?,
    );
  }

  /// Crear instancia desde JSON de WebSocket
  factory BlacklistEvent.fromWebSocketJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return BlacklistEvent(
      id: data['blacklist_event_id'] as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        ((json['timestamp'] as num).toDouble() * 1000).round(),
      ),
      personName: data['person_name'] as String,
      confidence: (data['confidence'] as num).toDouble(),
      distance: (data['distance'] as num).toDouble(),
      cameraLocation: data['camera_location'] as String?,
    );
  }

  /// Convertir a JSON para envío al API
  Map<String, dynamic> toJson() {
    return {
      'blacklist_event_id': id,
      'ts': timestamp.toIso8601String(),
      'person_name': personName,
      'confidence': confidence,
      'distance': distance,
      'camera_location': cameraLocation,
    };
  }

  /// Formatear timestamp para mostrar en UI
  String get formattedTimestamp {
    // Formato: DD/MM/YYYY HH:MM:SS
    final day = timestamp.day.toString().padLeft(2, '0');
    final month = timestamp.month.toString().padLeft(2, '0');
    final year = timestamp.year;
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final second = timestamp.second.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute:$second';
  }

  /// Formatear timestamp con tiempo relativo
  String get formattedTimestampWithRelative {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    String relativeTime;
    if (diff.inMinutes < 1) {
      relativeTime = 'Hace ${diff.inSeconds}s';
    } else if (diff.inHours < 1) {
      relativeTime = 'Hace ${diff.inMinutes}m';
    } else if (diff.inDays < 1) {
      relativeTime = 'Hace ${diff.inHours}h';
    } else {
      relativeTime = 'Hace ${diff.inDays}d';
    }

    return '$formattedTimestamp ($relativeTime)';
  }

  /// Formatear confianza como porcentaje
  String get confidencePercentage {
    return '${(confidence * 100).toStringAsFixed(1)}%';
  }

  /// Obtener color de confianza para UI
  String get confidenceColor {
    if (confidence >= 0.8) return 'high'; // Verde
    if (confidence >= 0.6) return 'medium'; // Amarillo
    return 'low'; // Rojo
  }

  /// Obtener texto de severidad
  String get severityText {
    if (confidence >= 0.8) return 'Alta';
    if (confidence >= 0.6) return 'Media';
    return 'Baja';
  }

  @override
  String toString() {
    return 'BlacklistEvent(id: $id, person: $personName, confidence: $confidencePercentage, time: $formattedTimestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BlacklistEvent &&
        other.id == id &&
        other.timestamp == timestamp &&
        other.personName == personName &&
        other.confidence == confidence &&
        other.distance == distance &&
        other.cameraLocation == cameraLocation;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        timestamp.hashCode ^
        personName.hashCode ^
        confidence.hashCode ^
        distance.hashCode ^
        cameraLocation.hashCode;
  }
}

/// Respuesta paginada de eventos de lista negra
class BlacklistEventsResponse {
  final List<BlacklistEvent> events;
  final int total;
  final int limit;
  final int offset;

  const BlacklistEventsResponse({
    required this.events,
    required this.total,
    required this.limit,
    required this.offset,
  });

  /// Crear desde JSON del API
  factory BlacklistEventsResponse.fromJson(Map<String, dynamic> json) {
    return BlacklistEventsResponse(
      events: (json['events'] as List)
          .map((e) => BlacklistEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      limit: json['limit'] as int,
      offset: json['offset'] as int,
    );
  }

  /// Verificar si hay más páginas disponibles
  bool get hasMorePages {
    return (offset + events.length) < total;
  }

  /// Obtener número de página actual (basado en 1)
  int get currentPage {
    return (offset ~/ limit) + 1;
  }

  /// Obtener total de páginas
  int get totalPages {
    return (total / limit).ceil();
  }
}
