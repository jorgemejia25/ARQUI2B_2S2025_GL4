class DashboardSummary {
  final int totalAlerts;
  final int recentAlerts24h;
  final int totalBuses;
  final int totalRoutes;
  final List<AlertSummary> alertsByType;
  final LastAlert? lastAlert;
  final String timestamp;

  DashboardSummary({
    required this.totalAlerts,
    required this.recentAlerts24h,
    required this.totalBuses,
    required this.totalRoutes,
    required this.alertsByType,
    this.lastAlert,
    required this.timestamp,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalAlerts: json['total_alerts'] ?? 0,
      recentAlerts24h: json['recent_alerts_24h'] ?? 0,
      totalBuses: json['total_buses'] ?? 0,
      totalRoutes: json['total_routes'] ?? 0,
      alertsByType:
          (json['alerts_by_type'] as List?)
              ?.map((e) => AlertSummary.fromJson(e))
              .toList() ??
          [],
      lastAlert: json['last_alert'] != null
          ? LastAlert.fromJson(json['last_alert'])
          : null,
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class AlertSummary {
  final String code;
  final String description;
  final int count;

  AlertSummary({
    required this.code,
    required this.description,
    required this.count,
  });

  factory AlertSummary.fromJson(Map<String, dynamic> json) {
    return AlertSummary(
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class LastAlert {
  final int alertId;
  final String ts;
  final String code;
  final String description;
  final int severity;

  LastAlert({
    required this.alertId,
    required this.ts,
    required this.code,
    required this.description,
    required this.severity,
  });

  factory LastAlert.fromJson(Map<String, dynamic> json) {
    return LastAlert(
      alertId: json['alert_id'] ?? 0,
      ts: json['ts'] ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      severity: json['severity'] ?? 0,
    );
  }
}

class BusStatus {
  final String code;
  final String? ts;
  final double? speedKmh;
  final double? distanceToNextStopM;

  BusStatus({
    required this.code,
    this.ts,
    this.speedKmh,
    this.distanceToNextStopM,
  });

  factory BusStatus.fromJson(Map<String, dynamic> json) {
    return BusStatus(
      code: json['code'] ?? '',
      ts: json['ts'],
      speedKmh: json['speed_kmh']?.toDouble(),
      distanceToNextStopM: json['distance_to_next_stop_m']?.toDouble(),
    );
  }
}

class GasMeasurement {
  final double ppm;
  final String ts;

  GasMeasurement({required this.ppm, required this.ts});

  factory GasMeasurement.fromJson(Map<String, dynamic> json) {
    return GasMeasurement(
      ppm: json['ppm']?.toDouble() ?? 0.0,
      ts: json['ts'] ?? '',
    );
  }
}

class SeismicMeasurement {
  final double intensityG;
  final String ts;

  SeismicMeasurement({required this.intensityG, required this.ts});

  factory SeismicMeasurement.fromJson(Map<String, dynamic> json) {
    return SeismicMeasurement(
      intensityG: json['intensity_g']?.toDouble() ?? 0.0,
      ts: json['ts'] ?? '',
    );
  }
}

class ChartDataPoint {
  final String hour;
  final double value;

  ChartDataPoint({required this.hour, required this.value});

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      hour: json['hour'] ?? '',
      value: json['value']?.toDouble() ?? 0.0,
    );
  }
}

class GasChartData {
  final int hours;
  final List<GasDataPoint> data;
  final int count;

  GasChartData({required this.hours, required this.data, required this.count});

  factory GasChartData.fromJson(Map<String, dynamic> json) {
    return GasChartData(
      hours: json['hours'] ?? 24,
      data:
          (json['data'] as List?)
              ?.map((e) => GasDataPoint.fromJson(e))
              .toList() ??
          [],
      count: json['count'] ?? 0,
    );
  }
}

class GasDataPoint {
  final int id;
  final String timestamp;
  final double ppm;

  GasDataPoint({required this.id, required this.timestamp, required this.ppm});

  factory GasDataPoint.fromJson(Map<String, dynamic> json) {
    return GasDataPoint(
      id: json['id'] ?? 0,
      timestamp: json['timestamp'] ?? '',
      ppm: json['ppm']?.toDouble() ?? 0.0,
    );
  }
}

class SeismicChartData {
  final int hours;
  final List<SeismicDataPoint> data;
  final int count;

  SeismicChartData({
    required this.hours,
    required this.data,
    required this.count,
  });

  factory SeismicChartData.fromJson(Map<String, dynamic> json) {
    return SeismicChartData(
      hours: json['hours'] ?? 24,
      data:
          (json['data'] as List?)
              ?.map((e) => SeismicDataPoint.fromJson(e))
              .toList() ??
          [],
      count: json['count'] ?? 0,
    );
  }
}

class SeismicDataPoint {
  final int id;
  final String timestamp;
  final double intensityG;

  SeismicDataPoint({
    required this.id,
    required this.timestamp,
    required this.intensityG,
  });

  factory SeismicDataPoint.fromJson(Map<String, dynamic> json) {
    return SeismicDataPoint(
      id: json['id'] ?? 0,
      timestamp: json['timestamp'] ?? '',
      intensityG: json['intensity_g']?.toDouble() ?? 0.0,
    );
  }
}

class DashboardMetrics {
  final double avgSeverity;
  final List<HourlyAlert> alertsPerHour;
  final EventsByType eventsByType;
  final List<TopStop> topStopsWithAlerts;
  final String timestamp;

  DashboardMetrics({
    required this.avgSeverity,
    required this.alertsPerHour,
    required this.eventsByType,
    required this.topStopsWithAlerts,
    required this.timestamp,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      avgSeverity: json['avg_severity']?.toDouble() ?? 0.0,
      alertsPerHour:
          (json['alerts_per_hour'] as List?)
              ?.map((e) => HourlyAlert.fromJson(e))
              .toList() ??
          [],
      eventsByType: json['events_by_type'] != null
          ? EventsByType.fromJson(json['events_by_type'])
          : EventsByType(),
      topStopsWithAlerts:
          (json['top_stops_with_alerts'] as List?)
              ?.map((e) => TopStop.fromJson(e))
              .toList() ??
          [],
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class HourlyAlert {
  final int count;
  final String hour;

  HourlyAlert({required this.count, required this.hour});

  factory HourlyAlert.fromJson(Map<String, dynamic> json) {
    return HourlyAlert(count: json['count'] ?? 0, hour: json['hour'] ?? '');
  }
}

class EventsByType {
  final int trafficInfractions;
  final int panicEvents;
  final int seismicEvents;
  final int gasEvents;

  EventsByType({
    this.trafficInfractions = 0,
    this.panicEvents = 0,
    this.seismicEvents = 0,
    this.gasEvents = 0,
  });

  factory EventsByType.fromJson(Map<String, dynamic> json) {
    return EventsByType(
      trafficInfractions: json['traffic_infractions'] ?? 0,
      panicEvents: json['panic_events'] ?? 0,
      seismicEvents: json['seismic_events'] ?? 0,
      gasEvents: json['gas_events'] ?? 0,
    );
  }
}

class TopStop {
  final String stopName;
  final int alertCount;

  TopStop({required this.stopName, required this.alertCount});

  factory TopStop.fromJson(Map<String, dynamic> json) {
    return TopStop(
      stopName: json['stop_name'] ?? '',
      alertCount: json['alert_count'] ?? 0,
    );
  }
}

class TableCount {
  final String tableName;
  final int count;

  TableCount({required this.tableName, required this.count});

  factory TableCount.fromJson(Map<String, dynamic> json) {
    return TableCount(
      tableName: json['table_name'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class SeverityDistribution {
  final int severity;
  final int count;

  SeverityDistribution({required this.severity, required this.count});

  factory SeverityDistribution.fromJson(Map<String, dynamic> json) {
    return SeverityDistribution(
      severity: json['severity'] ?? 0,
      count: json['count'] ?? 0,
    );
  }
}

class HourlyActivity {
  final String hour;
  final int totalEvents;

  HourlyActivity({required this.hour, required this.totalEvents});

  factory HourlyActivity.fromJson(Map<String, dynamic> json) {
    return HourlyActivity(
      hour: json['hour'] ?? '',
      totalEvents: json['total_events'] ?? 0,
    );
  }
}

class DetailedBusStatus {
  final int busId;
  final String code;
  final String? routeName;
  final String? lastPositionTime;
  final double? speedKmh;
  final double? distanceToNextStopM;
  final String status;

  DetailedBusStatus({
    required this.busId,
    required this.code,
    this.routeName,
    this.lastPositionTime,
    this.speedKmh,
    this.distanceToNextStopM,
    required this.status,
  });

  factory DetailedBusStatus.fromJson(Map<String, dynamic> json) {
    return DetailedBusStatus(
      busId: json['bus_id'] ?? 0,
      code: json['code'] ?? '',
      routeName: json['route_name'],
      lastPositionTime: json['last_position_time'],
      speedKmh: json['speed_kmh']?.toDouble(),
      distanceToNextStopM: json['distance_to_next_stop_m']?.toDouble(),
      status: json['status'] ?? 'offline',
    );
  }
}
