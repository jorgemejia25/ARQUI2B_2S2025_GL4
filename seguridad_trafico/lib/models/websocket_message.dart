class WebSocketMessage {
  final String type;
  final double timestamp;
  final TrafficUpdateData data;

  WebSocketMessage({
    required this.type,
    required this.timestamp,
    required this.data,
  });

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: json['type'] as String,
      timestamp: (json['timestamp'] as num?)?.toDouble() ?? 0.0,
      data: TrafficUpdateData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'timestamp': timestamp, 'data': data.toJson()};
  }
}

class TrafficUpdateData {
  final String signalId;
  final String signalColor;
  final String violationType;
  final String timestamp;
  final AlertData alertData;

  TrafficUpdateData({
    required this.signalId,
    required this.signalColor,
    required this.violationType,
    required this.timestamp,
    required this.alertData,
  });

  factory TrafficUpdateData.fromJson(Map<String, dynamic> json) {
    return TrafficUpdateData(
      signalId: json['signal_id'] as String,
      signalColor: json['signal_color'] as String,
      violationType: json['violation_type'] as String,
      timestamp: json['timestamp'] as String,
      alertData: AlertData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'signal_id': signalId,
      'signal_color': signalColor,
      'violation_type': violationType,
      'timestamp': timestamp,
      'data': alertData.toJson(),
    };
  }
}

class AlertData {
  final String alertType;
  final String? signalId;
  final String? signalColor;
  final String? stopId;
  final String? tipoTransporte;
  final int? tiempoSegundos;
  final String? origen;
  final int severity;

  AlertData({
    required this.alertType,
    this.signalId,
    this.signalColor,
    this.stopId,
    this.tipoTransporte,
    this.tiempoSegundos,
    this.origen,
    required this.severity,
  });

  factory AlertData.fromJson(Map<String, dynamic> json) {
    return AlertData(
      alertType: json['alert_type'] as String,
      signalId: json['signal_id'] as String?,
      signalColor: json['signal_color'] as String?,
      stopId: json['stop_id'] as String?,
      tipoTransporte: json['tipo_transporte'] as String?,
      tiempoSegundos: json['tiempo_segundos'] as int?,
      origen: json['origen'] as String?,
      severity: json['severity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alert_type': alertType,
      if (signalId != null) 'signal_id': signalId,
      if (signalColor != null) 'signal_color': signalColor,
      if (stopId != null) 'stop_id': stopId,
      if (tipoTransporte != null) 'tipo_transporte': tipoTransporte,
      if (tiempoSegundos != null) 'tiempo_segundos': tiempoSegundos,
      if (origen != null) 'origen': origen,
      'severity': severity,
    };
  }
}

class EtaUpdateMessage {
  final String type;
  final double timestamp;
  final EtaUpdateData data;

  EtaUpdateMessage({
    required this.type,
    required this.timestamp,
    required this.data,
  });

  factory EtaUpdateMessage.fromJson(Map<String, dynamic> json) {
    return EtaUpdateMessage(
      type: json['type'] as String,
      timestamp: (json['timestamp'] as num?)?.toDouble() ?? 0.0,
      data: EtaUpdateData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'timestamp': timestamp, 'data': data.toJson()};
  }
}

class EtaUpdateData {
  final String alertType;
  final String stopId;
  final String tipoTransporte;
  final int tiempoSegundos;
  final String origen;
  final int severity;

  EtaUpdateData({
    required this.alertType,
    required this.stopId,
    required this.tipoTransporte,
    required this.tiempoSegundos,
    required this.origen,
    required this.severity,
  });

  factory EtaUpdateData.fromJson(Map<String, dynamic> json) {
    return EtaUpdateData(
      alertType: json['alert_type'] as String,
      stopId: json['stop_id'] as String,
      tipoTransporte: json['tipo_transporte'] as String,
      tiempoSegundos: json['tiempo_segundos'] as int,
      origen: json['origen'] as String,
      severity: json['severity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alert_type': alertType,
      'stop_id': stopId,
      'tipo_transporte': tipoTransporte,
      'tiempo_segundos': tiempoSegundos,
      'origen': origen,
      'severity': severity,
    };
  }

  // Método helper para formatear tiempo
  String get tiempoFormateado {
    final minutos = tiempoSegundos ~/ 60;
    final segundos = tiempoSegundos % 60;

    if (minutos > 0) {
      return '${minutos}m ${segundos}s';
    } else {
      return '${segundos}s';
    }
  }
}
