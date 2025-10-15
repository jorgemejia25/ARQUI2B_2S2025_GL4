/// Modelo para eventos de detección de placas
/// Representa un evento de detección de vehículo con placa reconocida

class PlateEvent {
  final int id;
  final DateTime timestamp;
  final String plateText;
  final double confidence;
  final String cameraLocation;
  final String? imageBase64;

  const PlateEvent({
    required this.id,
    required this.timestamp,
    required this.plateText,
    required this.confidence,
    required this.cameraLocation,
    this.imageBase64,
  });

  factory PlateEvent.fromJson(Map<String, dynamic> json) {
    return PlateEvent(
      id: json['plate_event_id'] as int,
      timestamp: DateTime.parse(json['ts'] as String),
      plateText: json['plate_text'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      cameraLocation: json['camera_location'] as String? ?? 'Desconocida',
      imageBase64: json['image_base64'] as String?,
    );
  }

  String get formattedTimestamp {
    final d = timestamp;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
  }

  String get confidencePercentage => '${(confidence * 100).toStringAsFixed(1)}%';

  String get severityText {
    if (confidence >= 0.8) return 'Alta';
    if (confidence >= 0.6) return 'Media';
    return 'Baja';
  }

  String get confidenceColor {
    if (confidence >= 0.8) return 'high';
    if (confidence >= 0.6) return 'medium';
    return 'low';
  }

  @override
  String toString() =>
      'PlateEvent(id: $id, plate: $plateText, conf: $confidencePercentage)';
}
