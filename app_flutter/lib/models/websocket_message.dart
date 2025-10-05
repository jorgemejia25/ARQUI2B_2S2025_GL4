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

  // en segundos (double)
  final double? ts;

  // Campos específicos para alertas sísmicas
  final double? seismicIntensity;
  final double? thresholdG;
  final bool? tieneSismo;

  AlertData({
    required this.alertType,
    this.signalId,
    this.signalColor,
    this.stopId,
    this.tipoTransporte,
    this.tiempoSegundos,
    this.origen,
    required this.severity,
    this.ts, // ➕
    this.seismicIntensity,
    this.thresholdG,
    this.tieneSismo,
  });

  factory AlertData.fromJson(Map<String, dynamic> json) {
    return AlertData(
      alertType: json['alert_type'] as String,
      signalId: json['signal_id'] as String?,
      signalColor: json['signal_color'] as String?,
      stopId: json['stop_id'] as String?,
      tipoTransporte: json['tipo_transporte'] as String?,
      tiempoSegundos: (json['tiempo_segundos'] as num?)?.toInt(),
      origen: json['origen'] as String?,
      severity: (json['severity'] as num).toInt(),
      ts: (json['ts'] as num?)?.toDouble(),
      seismicIntensity: (json['seismic_intensity'] as num?)?.toDouble(),
      thresholdG: (json['threshold_g'] as num?)?.toDouble(),
      tieneSismo: json['tiene_sismo'] as bool?,
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
      if (ts != null) 'ts': ts,
      if (seismicIntensity != null) 'seismic_intensity': seismicIntensity,
      if (thresholdG != null) 'threshold_g': thresholdG,
      if (tieneSismo != null) 'tiene_sismo': tieneSismo,
    };
  }
}

extension AlertDataTime on AlertData {
  /// "hace 15 s", "hace 3 m", "hace 2 h", o fecha corta si >24h
  String get timeAgo {
    if (ts == null) return '';
    final nowSec = DateTime.now().millisecondsSinceEpoch / 1000.0;
    double diff = nowSec - ts!;
    if (diff < 0) diff = 0; // por si el reloj viene raro

    if (diff < 60) {
      final s = diff.round();
      return 'hace ${s}s';
    }
    if (diff < 3600) {
      final m = (diff / 60).round();
      return 'hace ${m}m';
    }
    if (diff < 86400) {
      final h = (diff / 3600).round();
      return 'hace ${h}h';
    }
    // >24h: fecha corta
    final dt = DateTime.fromMillisecondsSinceEpoch((ts! * 1000).round());
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)} ${two(dt.hour)}:${two(dt.minute)}';
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

/// Tipos de alerta que puede enviar el backend.
enum AlertType {
  infraccion, // INFRACCION
  panico, // PANICO
  gasAlert, // GAS_ALERT
  seismicAlert, // SEISMIC_ALERT, SISMO
  signalUpdate, // SIGNAL_UPDATE (cuando venga como alerta genérica)
  unknown;

  static AlertType fromString(String? raw) {
    switch ((raw ?? '').toUpperCase()) {
      case 'INFRACCION':
        return AlertType.infraccion;
      case 'PANICO':
        return AlertType.panico;
      case 'GAS_ALERT':
        return AlertType.gasAlert;
      case 'SEISMIC_ALERT':
      case 'SISMO':
        return AlertType.seismicAlert;
      case 'SIGNAL_UPDATE':
        return AlertType.signalUpdate;
      default:
        return AlertType.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case AlertType.infraccion:
        return 'Infracción de tránsito';
      case AlertType.panico:
        return 'Botón de pánico';
      case AlertType.gasAlert:
        return 'Alerta de gas';
      case AlertType.seismicAlert:
        return 'Alerta sísmica';
      case AlertType.signalUpdate:
        return 'Actualización de señal';
      case AlertType.unknown:
        return 'Alerta';
    }
  }
}

/// Mensaje WS para type == "alert"
class AlertMessage {
  final String type; // "alert"
  final double timestamp; // epoch en segundos
  final AlertData data;

  AlertMessage({
    required this.type,
    required this.timestamp,
    required this.data,
  });

  factory AlertMessage.fromJson(Map<String, dynamic> json) {
    final rawData = (json['data'] as Map<String, dynamic>? ?? {});
    return AlertMessage(
      type: json['type'] as String? ?? 'alert',
      timestamp: (json['timestamp'] as num?)?.toDouble() ?? 0.0,
      data: AlertData.fromJson(rawData),
    );
  }

  /// Conveniencias para UI
  AlertType get alertTypeEnum => AlertType.fromString(data.alertType);

  String get title => alertTypeEnum.displayName;

  String get subtitle {
    if (data.signalId != null) return 'Semáforo: ${data.signalId}';
    if (data.stopId != null) return 'Parada: ${data.stopId}';
    if (data.origen != null && data.origen!.isNotEmpty)
      return 'Origen: ${data.origen}';
    return '';
  }
}

extension AlertDataView on AlertData {
  AlertType get kind => AlertType.fromString(alertType);

  String get title {
    switch (kind) {
      case AlertType.infraccion:
        return 'Infracción de tránsito';
      case AlertType.panico:
        return 'Botón de pánico';
      case AlertType.gasAlert:
        return 'Alerta de gas';
      case AlertType.seismicAlert:
        return 'Alerta sísmica';
      case AlertType.signalUpdate:
        return 'Actualización de señal';
      case AlertType.unknown:
        return 'Alerta';
    }
  }

  String get subtitle {
    if (signalId != null) return 'Semáforo: $signalId';
    if (stopId != null) return 'Parada: $stopId';
    if (origen != null && origen!.isNotEmpty) return 'Origen: $origen';
    return '';
  }
}
