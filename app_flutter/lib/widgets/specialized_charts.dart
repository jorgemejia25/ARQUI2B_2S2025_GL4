import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/app_theme.dart';

/// Gráfica especializada para análisis de gas
class GasAnalyticsChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String title;
  final double thresholdPpm;

  const GasAnalyticsChart({
    super.key,
    required this.data,
    required this.title,
    this.thresholdPpm = 300.0,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState('Sin datos de gas para mostrar');
    }

    return Container(
      height: 350,
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.greyMedium.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: AppTheme.spaceLarge),
          Expanded(child: LineChart(_buildLineChartData())),
          const SizedBox(height: AppTheme.spaceMedium),
          _buildThresholdIndicator(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spaceSmall),
          decoration: BoxDecoration(
            color: AppTheme.neonGreen.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(Icons.air_rounded, color: AppTheme.neonGreen, size: 20),
        ),
        const SizedBox(width: AppTheme.spaceSmall),
        Expanded(
          child: Text(
            title,
            style: AppTheme.headingMedium.copyWith(color: AppTheme.textPrimary),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMedium,
            vertical: AppTheme.spaceSmall,
          ),
          decoration: BoxDecoration(
            color: AppTheme.backgroundElevated,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Text(
            '${data.length} mediciones',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }

  LineChartData _buildLineChartData() {
    final spots = <FlSpot>[];
    for (var i = 0; i < data.length; i++) {
      final ppm = (data[i]['avg_ppm'] ?? 0).toDouble();
      spots.add(FlSpot(i.toDouble(), ppm));
    }

    final maxPpm = spots.isNotEmpty
        ? spots.map((s) => s.y).reduce((a, b) => a > b ? a : b)
        : thresholdPpm;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (maxPpm / 5).ceilToDouble(),
        getDrawingHorizontalLine: (value) {
          if ((value % thresholdPpm).abs() < 1) {
            return FlLine(
              color: AppTheme.neonOrange,
              strokeWidth: 2,
              dashArray: [5, 5],
            );
          }
          return FlLine(
            color: AppTheme.greyMedium.withOpacity(0.2),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < data.length) {
                final timePeriod = data[value.toInt()]['time_period'] as String;
                final parts = timePeriod.split(' ');
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    parts.length > 1 ? parts[1].substring(0, 5) : parts[0],
                    style: AppTheme.caption,
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            getTitlesWidget: (value, meta) =>
                Text('${value.toInt()}ppm', style: AppTheme.caption),
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (data.length - 1).toDouble(),
      minY: 0,
      maxY: maxPpm * 1.2,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: AppTheme.neonGreen,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              final isHigh = spot.y > thresholdPpm;
              return FlDotCirclePainter(
                radius: isHigh ? 5 : 4,
                color: isHigh ? AppTheme.neonOrange : AppTheme.neonGreen,
                strokeWidth: 2,
                strokeColor: AppTheme.backgroundCard,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppTheme.neonGreen.withOpacity(0.3),
                AppTheme.neonGreen.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: AppTheme.backgroundElevated,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final isHigh = spot.y > thresholdPpm;
              return LineTooltipItem(
                '${spot.y.toInt()}ppm ${isHigh ? '(ALTO)' : ''}',
                AppTheme.bodySmall.copyWith(
                  color: isHigh ? AppTheme.neonOrange : AppTheme.textPrimary,
                  fontWeight: isHigh ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildThresholdIndicator() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.neonOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: AppTheme.neonOrange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppTheme.neonOrange,
            size: 16,
          ),
          const SizedBox(width: AppTheme.spaceSmall),
          Text(
            'Umbral de alerta: ${thresholdPpm.toInt()}ppm',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.neonOrange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.greyMedium.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.air_rounded, size: 48, color: AppTheme.greyMedium),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              message,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gráfica especializada para análisis sísmico
class SeismicAnalyticsChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String title;
  final double thresholdIntensity;

  const SeismicAnalyticsChart({
    super.key,
    required this.data,
    required this.title,
    this.thresholdIntensity = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState('Sin datos sísmicos para mostrar');
    }

    return Container(
      height: 350,
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.greyMedium.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: AppTheme.spaceLarge),
          Expanded(child: BarChart(_buildBarChartData())),
          const SizedBox(height: AppTheme.spaceMedium),
          _buildIntensityLegend(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spaceSmall),
          decoration: BoxDecoration(
            color: AppTheme.neonYellow.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(
            Icons.vibration_rounded,
            color: AppTheme.neonYellow,
            size: 20,
          ),
        ),
        const SizedBox(width: AppTheme.spaceSmall),
        Expanded(
          child: Text(
            title,
            style: AppTheme.headingMedium.copyWith(color: AppTheme.textPrimary),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMedium,
            vertical: AppTheme.spaceSmall,
          ),
          decoration: BoxDecoration(
            color: AppTheme.backgroundElevated,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Text(
            '${data.length} eventos',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }

  BarChartData _buildBarChartData() {
    final barGroups = <BarChartGroupData>[];
    final maxIntensity = data.isNotEmpty
        ? data
              .map((d) => (d['intensity_g'] ?? 0).toDouble())
              .reduce((a, b) => a > b ? a : b)
        : thresholdIntensity;

    for (var i = 0; i < data.length; i++) {
      final intensity = (data[i]['intensity_g'] ?? 0).toDouble();
      final isHigh = intensity > thresholdIntensity;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: intensity,
              color: isHigh ? AppTheme.neonOrange : AppTheme.neonYellow,
              width: 20,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
              gradient: LinearGradient(
                colors: [
                  isHigh ? AppTheme.neonOrange : AppTheme.neonYellow,
                  (isHigh ? AppTheme.neonOrange : AppTheme.neonYellow)
                      .withOpacity(0.7),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ],
        ),
      );
    }

    return BarChartData(
      maxY: maxIntensity * 1.3,
      barGroups: barGroups,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (maxIntensity / 5).ceilToDouble(),
        getDrawingHorizontalLine: (value) {
          if ((value % thresholdIntensity).abs() < 0.1) {
            return FlLine(
              color: AppTheme.neonOrange,
              strokeWidth: 2,
              dashArray: [5, 5],
            );
          }
          return FlLine(
            color: AppTheme.greyMedium.withOpacity(0.2),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < data.length) {
                final ts = data[value.toInt()]['ts'] as String;
                final timePart = ts.split(' ')[1].substring(0, 5);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(timePart, style: AppTheme.caption),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            getTitlesWidget: (value, meta) =>
                Text('${value.toStringAsFixed(1)}g', style: AppTheme.caption),
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          tooltipBgColor: AppTheme.backgroundElevated,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final intensity = rod.toY;
            final isHigh = intensity > thresholdIntensity;
            return BarTooltipItem(
              '${intensity.toStringAsFixed(1)}g ${isHigh ? '(ALTO)' : ''}',
              AppTheme.bodySmall.copyWith(
                color: isHigh ? AppTheme.neonOrange : AppTheme.textPrimary,
                fontWeight: isHigh ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIntensityLegend() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.neonYellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: AppTheme.neonYellow.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.vibration_rounded, color: AppTheme.neonYellow, size: 16),
          const SizedBox(width: AppTheme.spaceSmall),
          Text(
            'Intensidad significativa: >${thresholdIntensity}g',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.neonYellow,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.greyMedium.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.vibration_rounded, size: 48, color: AppTheme.greyMedium),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              message,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gráfica de salud del sistema
class SystemHealthChart extends StatelessWidget {
  final Map<String, dynamic> data;
  final String title;

  const SystemHealthChart({super.key, required this.data, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.greyMedium.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: AppTheme.spaceLarge),
          Expanded(child: _buildHealthMetrics()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spaceSmall),
          decoration: BoxDecoration(
            color: AppTheme.neonCyan.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(
            Icons.health_and_safety_rounded,
            color: AppTheme.neonCyan,
            size: 20,
          ),
        ),
        const SizedBox(width: AppTheme.spaceSmall),
        Text(
          title,
          style: AppTheme.headingMedium.copyWith(color: AppTheme.textPrimary),
        ),
      ],
    );
  }

  Widget _buildHealthMetrics() {
    final busStats = data['bus_statistics'] as Map<String, dynamic>? ?? {};
    final routeCoverage = data['route_coverage'] as List? ?? [];
    final hourlyPattern = data['hourly_alert_pattern'] as List? ?? [];

    return Column(
      children: [
        // Estadísticas de buses
        _buildMetricCard(
          'Estado de Buses',
          Icons.directions_bus_rounded,
          AppTheme.neonCyan,
          [
            'Total: ${busStats['total_buses'] ?? 0}',
            'Con alertas: ${busStats['buses_with_alerts'] ?? 0}',
          ],
        ),
        const SizedBox(height: AppTheme.spaceMedium),

        // Cobertura de rutas
        _buildMetricCard(
          'Cobertura de Rutas',
          Icons.route_rounded,
          AppTheme.neonGreen,
          routeCoverage.map((route) {
            final routeName = route['route_name'] ?? 'Desconocida';
            final stopsCount = route['stops_count'] ?? 0;
            final busesCount = route['buses_count'] ?? 0;
            return '$routeName: $stopsCount paradas, $busesCount buses';
          }).toList(),
        ),
        const SizedBox(height: AppTheme.spaceMedium),

        // Patrón de alertas por hora
        _buildMetricCard(
          'Patrón de Alertas',
          Icons.schedule_rounded,
          AppTheme.neonOrange,
          hourlyPattern.map((hour) {
            final hourTime = hour['hour'] ?? '00';
            final count = hour['alert_count'] ?? 0;
            return '${hourTime}:00 - $count alertas';
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    IconData icon,
    Color color,
    List<String> items,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: AppTheme.spaceSmall),
              Text(
                title,
                style: AppTheme.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          ...items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    item,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }
}







