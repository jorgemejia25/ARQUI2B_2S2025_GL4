import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/dashboard_models.dart';
import '../config/app_theme.dart';

class GasChart extends StatelessWidget {
  final List<GasDataPoint> data;
  final String title;

  const GasChart({
    super.key,
    required this.data,
    this.title = 'Niveles de Gas (PPM)',
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState(
        icon: Icons.air_rounded,
        message: 'Sin datos de gas disponibles',
        color: AppTheme.neonGreen,
      );
    }

    final values = data.map((e) => e.ppm).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final padding = (maxValue - minValue) * 0.1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChartHeader(
          icon: Icons.air_rounded,
          title: title,
          count: data.length,
          color: AppTheme.neonGreen,
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (maxValue - minValue) / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppTheme.greyMedium.withOpacity(0.2),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: data.length > 20 ? 10 : 5,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < data.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            data[index].timestamp.substring(11, 16),
                            style: AppTheme.caption.copyWith(
                              fontSize: 9,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (data.length - 1).toDouble(),
              minY: minValue - padding,
              maxY: maxValue + padding,
              lineBarsData: [
                LineChartBarData(
                  spots: data.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value.ppm);
                  }).toList(),
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: AppTheme.neonGreen,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                          radius: 3,
                          color: AppTheme.neonGreen,
                          strokeWidth: 2,
                          strokeColor: AppTheme.backgroundCard,
                        ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.neonGreen.withOpacity(0.3),
                        AppTheme.neonGreen.withOpacity(0.05),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  shadow: Shadow(
                    color: AppTheme.neonGreen.withOpacity(0.5),
                    blurRadius: 8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required Color color,
  }) {
    return SizedBox(
      height: 250,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppTheme.greyMedium),
          const SizedBox(height: 12),
          Text(message, style: AppTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildChartHeader({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            boxShadow: AppTheme.neonShadow(color, blur: 10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Text(title, style: AppTheme.headingSmall),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Text(
            '$count datos',
            style: AppTheme.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class SeismicChart extends StatelessWidget {
  final List<SeismicDataPoint> data;
  final String title;

  const SeismicChart({
    super.key,
    required this.data,
    this.title = 'Actividad Sísmica (G)',
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState(
        icon: Icons.vibration_rounded,
        message: 'Sin datos sísmicos disponibles',
        color: AppTheme.neonYellow,
      );
    }

    final values = data.map((e) => e.intensityG).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final padding = (maxValue - minValue) * 0.1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChartHeader(
          icon: Icons.vibration_rounded,
          title: title,
          count: data.length,
          color: AppTheme.neonYellow,
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (maxValue - minValue) / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppTheme.greyMedium.withOpacity(0.2),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    getTitlesWidget: (value, meta) => Text(
                      value.toStringAsFixed(1),
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: data.length > 12 ? 2 : 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < data.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            data[index].timestamp.substring(11, 16),
                            style: AppTheme.caption.copyWith(
                              fontSize: 9,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (data.length - 1).toDouble(),
              minY: minValue - padding,
              maxY: maxValue + padding,
              lineBarsData: [
                LineChartBarData(
                  spots: data.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value.intensityG);
                  }).toList(),
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: AppTheme.neonYellow,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                          radius: 3,
                          color: AppTheme.neonYellow,
                          strokeWidth: 2,
                          strokeColor: AppTheme.backgroundCard,
                        ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.neonYellow.withOpacity(0.3),
                        AppTheme.neonYellow.withOpacity(0.05),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  shadow: Shadow(
                    color: AppTheme.neonYellow.withOpacity(0.5),
                    blurRadius: 8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required Color color,
  }) {
    return SizedBox(
      height: 250,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppTheme.greyMedium),
          const SizedBox(height: 12),
          Text(message, style: AppTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildChartHeader({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            boxShadow: AppTheme.neonShadow(color, blur: 10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Text(title, style: AppTheme.headingSmall),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Text(
            '$count datos',
            style: AppTheme.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class AlertsChart extends StatelessWidget {
  final List<AlertSummary> data;
  final String title;

  const AlertsChart({
    super.key,
    required this.data,
    this.title = 'Distribución de Alertas',
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: 300,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 48,
              color: AppTheme.greyMedium,
            ),
            const SizedBox(height: 12),
            Text('Sin alertas registradas', style: AppTheme.bodyMedium),
          ],
        ),
      );
    }

    final colors = [
      AppTheme.neonOrange,
      AppTheme.error,
      AppTheme.neonYellow,
      AppTheme.neonCyan,
      AppTheme.primaryPurple,
    ];

    final totalAlerts = data.fold(0, (sum, alert) => sum + alert.count);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.neonPink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                boxShadow: AppTheme.neonShadow(AppTheme.neonPink, blur: 10),
              ),
              child: Icon(
                Icons.pie_chart_rounded,
                color: AppTheme.neonPink,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(title, style: AppTheme.headingSmall),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryPurple.withOpacity(0.2),
                    AppTheme.primaryPurple.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(
                  color: AppTheme.primaryPurple.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'Total: $totalAlerts',
                style: AppTheme.caption.copyWith(
                  color: AppTheme.primaryPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceLarge),
        Center(
          child: SizedBox(
            width: 180,
            height: 180,
            child: PieChart(
              PieChartData(
                sections: data.asMap().entries.map((entry) {
                  final index = entry.key;
                  final alert = entry.value;
                  final color = colors[index % colors.length];
                  final percentage = (alert.count / totalAlerts * 100).round();

                  return PieChartSectionData(
                    color: color,
                    value: alert.count.toDouble(),
                    title: '$percentage%',
                    radius: 60,
                    titleStyle: AppTheme.bodySmall.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.backgroundDark,
                    ),
                    titlePositionPercentageOffset: 0.6,
                  );
                }).toList(),
                centerSpaceRadius: 50,
                sectionsSpace: 3,
                startDegreeOffset: -90,
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceLarge),
        ...data.asMap().entries.map((entry) {
          final index = entry.key;
          final alert = entry.value;
          final color = colors[index % colors.length];
          final percentage = (alert.count / totalAlerts * 100).round();

          return Container(
            margin: const EdgeInsets.only(bottom: AppTheme.spaceSmall),
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              color: AppTheme.backgroundElevated.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: AppTheme.neonShadow(color, blur: 8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.description,
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        alert.code,
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${alert.count}',
                      style: AppTheme.headingSmall.copyWith(
                        fontSize: 18,
                        color: color,
                      ),
                    ),
                    Text(
                      '$percentage%',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
