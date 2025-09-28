class DashboardSummary {
  final List<AlertSummary> alertsSummary;
  final List<BusStatus> busesStatus;
  final List<GasMeasurement> latestGas;
  final List<SeismicMeasurement> latestSeismic;
  final String timestamp;

  DashboardSummary({
    required this.alertsSummary,
    required this.busesStatus,
    required this.latestGas,
    required this.latestSeismic,
    required this.timestamp,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      alertsSummary:
          (json['alerts_summary'] as List?)
              ?.map((e) => AlertSummary.fromJson(e))
              .toList() ??
          [],
      busesStatus:
          (json['buses_status'] as List?)
              ?.map((e) => BusStatus.fromJson(e))
              .toList() ??
          [],
      latestGas:
          (json['latest_gas'] as List?)
              ?.map((e) => GasMeasurement.fromJson(e))
              .toList() ??
          [],
      latestSeismic:
          (json['latest_seismic'] as List?)
              ?.map((e) => SeismicMeasurement.fromJson(e))
              .toList() ??
          [],
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
  final List<ChartDataPoint> data;

  GasChartData({required this.data});

  factory GasChartData.fromJson(Map<String, dynamic> json) {
    return GasChartData(
      data:
          (json['gas_by_hour'] as List?)
              ?.map(
                (e) => ChartDataPoint.fromJson({
                  'hour': e['hour'],
                  'value': e['avg_ppm'],
                }),
              )
              .toList() ??
          [],
    );
  }
}

class SeismicChartData {
  final List<ChartDataPoint> data;

  SeismicChartData({required this.data});

  factory SeismicChartData.fromJson(Map<String, dynamic> json) {
    return SeismicChartData(
      data:
          (json['seismic_by_hour'] as List?)
              ?.map(
                (e) => ChartDataPoint.fromJson({
                  'hour': e['hour'],
                  'value': e['avg_intensity'],
                }),
              )
              .toList() ??
          [],
    );
  }
}

class DashboardMetrics {
  final List<TableCount> tableCounts;
  final List<SeverityDistribution> severityDistribution;
  final List<HourlyActivity> hourlyActivity;

  DashboardMetrics({
    required this.tableCounts,
    required this.severityDistribution,
    required this.hourlyActivity,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      tableCounts:
          (json['table_counts'] as List?)
              ?.map((e) => TableCount.fromJson(e))
              .toList() ??
          [],
      severityDistribution:
          (json['severity_distribution'] as List?)
              ?.map((e) => SeverityDistribution.fromJson(e))
              .toList() ??
          [],
      hourlyActivity:
          (json['hourly_activity'] as List?)
              ?.map((e) => HourlyActivity.fromJson(e))
              .toList() ??
          [],
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
