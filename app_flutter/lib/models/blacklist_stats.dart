/// Modelo para estadísticas de personas en la blacklist
class BlacklistStats {
  final String personName;
  final int totalDetections;
  final double avgConfidence;
  final DateTime lastDetection;
  final DateTime firstDetection;

  const BlacklistStats({
    required this.personName,
    required this.totalDetections,
    required this.avgConfidence,
    required this.lastDetection,
    required this.firstDetection,
  });

  /// Crear instancia desde JSON (API response)
  factory BlacklistStats.fromJson(Map<String, dynamic> json) {
    return BlacklistStats(
      personName: json['person_name'] as String,
      totalDetections: json['total_detections'] as int,
      avgConfidence: (json['avg_confidence'] as num).toDouble(),
      lastDetection: DateTime.parse(json['last_detection'] as String),
      firstDetection: DateTime.parse(json['first_detection'] as String),
    );
  }

  /// Formatear última detección
  String get formattedLastDetection {
    final now = DateTime.now();
    final diff = now.difference(lastDetection);

    if (diff.inMinutes < 1) {
      return 'Hace ${diff.inSeconds}s';
    } else if (diff.inHours < 1) {
      return 'Hace ${diff.inMinutes}m';
    } else if (diff.inDays < 1) {
      return 'Hace ${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return 'Hace ${diff.inDays}d';
    } else {
      final day = lastDetection.day.toString().padLeft(2, '0');
      final month = lastDetection.month.toString().padLeft(2, '0');
      return '$day/$month/${lastDetection.year}';
    }
  }

  /// Formatear confianza promedio como porcentaje
  String get avgConfidencePercentage {
    return '${(avgConfidence * 100).toStringAsFixed(1)}%';
  }

  @override
  String toString() {
    return 'BlacklistStats(person: $personName, detections: $totalDetections, avgConf: $avgConfidencePercentage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BlacklistStats && other.personName == personName;
  }

  @override
  int get hashCode => personName.hashCode;
}
