import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/app_theme.dart';

/// Gráfica de línea de tiempo avanzada
class TimelineChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String title;
  final String subtitle;

  const TimelineChart({
    super.key,
    required this.data,
    required this.title,
    this.subtitle = '',
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState('Sin datos para mostrar');
    }

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
          Expanded(
            child: LineChart(
              _buildLineChartData(),
              duration: const Duration(milliseconds: 250),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.timeline_rounded,
              color: AppTheme.primaryPurple,
              size: 20,
            ),
            const SizedBox(width: AppTheme.spaceSmall),
            Expanded(
              child: Text(
                title,
                style: AppTheme.headingMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spaceXSmall),
          Text(
            subtitle,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ],
    );
  }

  LineChartData _buildLineChartData() {
    final spots = <FlSpot>[];
    for (var i = 0; i < data.length; i++) {
      // El backend puede devolver 'alert_count', 'total_alerts' o 'count'
      final count =
          (data[i]['alert_count'] ??
                  data[i]['total_alerts'] ??
                  data[i]['count'] ??
                  0)
              .toDouble();
      spots.add(FlSpot(i.toDouble(), count));
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 1,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: AppTheme.greyMedium.withOpacity(0.2), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < data.length) {
                // El backend puede devolver 'time_period' o 'period'
                final timePeriod =
                    data[value.toInt()]['time_period'] ??
                    data[value.toInt()]['period'] ??
                    '';

                // Mostrar etiqueta más descriptiva
                if (timePeriod.contains(' ')) {
                  final parts = timePeriod.split(' ');
                  final datePart = parts[0];
                  final timePart = parts[1];

                  // Si es agrupación por hora, mostrar solo la hora
                  if (timePart.endsWith(':00:00')) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        timePart.substring(0, 5), // HH:MM
                        style: AppTheme.caption,
                      ),
                    );
                  } else {
                    // Si es agrupación por día, mostrar la fecha
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(datePart, style: AppTheme.caption),
                    );
                  }
                } else {
                  // Si no hay espacio, mostrar tal como está
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(timePeriod, style: AppTheme.caption),
                  );
                }
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) =>
                Text(value.toInt().toString(), style: AppTheme.caption),
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
      maxY: spots.isNotEmpty
          ? spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2
          : 10,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: AppTheme.primaryPurple,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: AppTheme.primaryPurple,
                strokeWidth: 2,
                strokeColor: AppTheme.backgroundCard,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryPurple.withOpacity(0.3),
                AppTheme.primaryPurple.withOpacity(0.0),
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
              return LineTooltipItem(
                '${spot.y.toInt()} alertas',
                AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildExampleChart() {
    // Datos de ejemplo para demostrar la funcionalidad
    final exampleData = [
      {
        'time_period': '2024-01-15 08:00:00',
        'alert_count': 12,
        'event_type': 'INFRACCION',
      },
      {
        'time_period': '2024-01-15 09:00:00',
        'alert_count': 8,
        'event_type': 'INFRACCION',
      },
      {
        'time_period': '2024-01-15 10:00:00',
        'alert_count': 15,
        'event_type': 'INFRACCION',
      },
      {
        'time_period': '2024-01-15 11:00:00',
        'alert_count': 6,
        'event_type': 'INFRACCION',
      },
      {
        'time_period': '2024-01-15 12:00:00',
        'alert_count': 20,
        'event_type': 'INFRACCION',
      },
      {
        'time_period': '2024-01-15 13:00:00',
        'alert_count': 14,
        'event_type': 'INFRACCION',
      },
      {
        'time_period': '2024-01-15 14:00:00',
        'alert_count': 9,
        'event_type': 'INFRACCION',
      },
      {
        'time_period': '2024-01-15 15:00:00',
        'alert_count': 11,
        'event_type': 'INFRACCION',
      },
    ];

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
          Expanded(
            child: LineChart(
              _buildLineChartDataFromExample(exampleData),
              duration: const Duration(milliseconds: 250),
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceMedium,
              vertical: AppTheme.spaceSmall,
            ),
            decoration: BoxDecoration(
              color: AppTheme.neonYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(color: AppTheme.neonYellow.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, color: AppTheme.neonYellow, size: 16),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(
                  'Datos de ejemplo - Conecte sensores para ver datos reales',
                  style: AppTheme.caption.copyWith(color: AppTheme.neonYellow),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildLineChartDataFromExample(
    List<Map<String, dynamic>> exampleData,
  ) {
    final spots = <FlSpot>[];
    for (var i = 0; i < exampleData.length; i++) {
      final count = (exampleData[i]['alert_count'] ?? 0).toDouble();
      spots.add(FlSpot(i.toDouble(), count));
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 1,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: AppTheme.greyMedium.withOpacity(0.2), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < exampleData.length) {
                final timePeriod =
                    exampleData[value.toInt()]['time_period'] as String;
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
            reservedSize: 40,
            getTitlesWidget: (value, meta) =>
                Text(value.toInt().toString(), style: AppTheme.caption),
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (exampleData.length - 1).toDouble(),
      minY: 0,
      maxY: spots.isNotEmpty
          ? spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2
          : 10,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: AppTheme.primaryPurple,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: AppTheme.primaryPurple,
                strokeWidth: 2,
                strokeColor: AppTheme.backgroundCard,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryPurple.withOpacity(0.3),
                AppTheme.primaryPurple.withOpacity(0.0),
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
              return LineTooltipItem(
                '${spot.y.toInt()} alertas',
                AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 48, color: AppTheme.greyMedium),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(message, style: AppTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

/// Gráfica de barras para comparación
class ComparisonBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String title;
  final String metric;

  const ComparisonBarChart({
    super.key,
    required this.data,
    required this.title,
    required this.metric,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      // Mostrar datos de ejemplo cuando no hay datos reales
      return _buildExampleBarChart();
    }

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
          Expanded(
            child: BarChart(
              _buildBarChartData(),
              swapAnimationDuration: const Duration(milliseconds: 250),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.bar_chart_rounded, color: AppTheme.neonCyan, size: 20),
        const SizedBox(width: AppTheme.spaceSmall),
        Expanded(
          child: Text(
            title,
            style: AppTheme.headingMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  BarChartData _buildBarChartData() {
    final barGroups = <BarChartGroupData>[];
    final colors = [
      AppTheme.primaryPurple,
      AppTheme.neonCyan,
      AppTheme.neonOrange,
      AppTheme.neonGreen,
    ];

    for (var i = 0; i < data.length && i < 10; i++) {
      final value = _getMetricValue(data[i]);
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: value,
              color: colors[i % colors.length],
              width: 16,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
              gradient: LinearGradient(
                colors: [
                  colors[i % colors.length],
                  colors[i % colors.length].withOpacity(0.7),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ],
        ),
      );
    }

    final maxValue = barGroups.isNotEmpty
        ? barGroups.map((g) => g.barRods[0].toY).reduce((a, b) => a > b ? a : b)
        : 10.0;

    return BarChartData(
      maxY: maxValue * 1.2,
      barGroups: barGroups,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxValue / 5,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: AppTheme.greyMedium.withOpacity(0.2), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < data.length) {
                final label = _getLabel(data[value.toInt()]);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    label,
                    style: AppTheme.caption,
                    overflow: TextOverflow.ellipsis,
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
            reservedSize: 40,
            getTitlesWidget: (value, meta) =>
                Text(value.toInt().toString(), style: AppTheme.caption),
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
            return BarTooltipItem(
              '${rod.toY.toInt()}',
              AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary),
            );
          },
        ),
      ),
    );
  }

  double _getMetricValue(Map<String, dynamic> item) {
    // El backend devuelve 'value' para las comparaciones
    if (item.containsKey('value')) {
      return (item['value'] ?? 0).toDouble();
    } else if (item.containsKey('alert_count')) {
      return (item['alert_count'] ?? 0).toDouble();
    } else if (item.containsKey('avg_severity')) {
      return (item['avg_severity'] ?? 0).toDouble();
    } else if (item.containsKey('alerts_per_day')) {
      return (item['alerts_per_day'] ?? 0).toDouble();
    }
    return 0;
  }

  String _getLabel(Map<String, dynamic> item) {
    // El backend devuelve 'label' para las comparaciones
    if (item.containsKey('label')) {
      final label = item['label'] as String;
      return label.length > 12 ? '${label.substring(0, 12)}...' : label;
    } else if (item.containsKey('code')) {
      return item['code'] as String;
    } else if (item.containsKey('event_type')) {
      return item['event_type'] as String;
    } else if (item.containsKey('severity_level')) {
      return 'Nivel ${item['severity_level']}';
    } else if (item.containsKey('location')) {
      final location = item['location'] as String;
      return location.length > 8 ? '${location.substring(0, 8)}...' : location;
    }
    return 'N/A';
  }

  Widget _buildExampleBarChart() {
    // Datos de ejemplo para demostrar la funcionalidad
    final exampleData = [
      {'label': 'Infracciones', 'value': 45, 'category': 'INFRACCION'},
      {'label': 'Alertas de Pánico', 'value': 23, 'category': 'PANICO'},
      {'label': 'Detección de Gas', 'value': 18, 'category': 'GAS'},
      {'label': 'Sismos', 'value': 12, 'category': 'SISMO'},
      {'label': 'Otros Eventos', 'value': 8, 'category': 'OTROS'},
    ];

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
          Expanded(
            child: BarChart(
              _buildBarChartDataFromExample(exampleData),
              swapAnimationDuration: const Duration(milliseconds: 250),
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceMedium,
              vertical: AppTheme.spaceSmall,
            ),
            decoration: BoxDecoration(
              color: AppTheme.neonYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(color: AppTheme.neonYellow.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, color: AppTheme.neonYellow, size: 16),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(
                  'Datos de ejemplo - Conecte sensores para ver datos reales',
                  style: AppTheme.caption.copyWith(color: AppTheme.neonYellow),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BarChartData _buildBarChartDataFromExample(
    List<Map<String, dynamic>> exampleData,
  ) {
    final barGroups = <BarChartGroupData>[];
    final colors = [
      AppTheme.primaryPurple,
      AppTheme.neonCyan,
      AppTheme.neonOrange,
      AppTheme.neonGreen,
    ];

    for (var i = 0; i < exampleData.length; i++) {
      final value = (exampleData[i]['value'] ?? 0).toDouble();
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: value,
              color: colors[i % colors.length],
              width: 16,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
              gradient: LinearGradient(
                colors: [
                  colors[i % colors.length],
                  colors[i % colors.length].withOpacity(0.7),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ],
        ),
      );
    }

    final maxValue = barGroups.isNotEmpty
        ? barGroups.map((g) => g.barRods[0].toY).reduce((a, b) => a > b ? a : b)
        : 10.0;

    return BarChartData(
      maxY: maxValue * 1.2,
      barGroups: barGroups,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxValue / 5,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: AppTheme.greyMedium.withOpacity(0.2), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < exampleData.length) {
                final label = exampleData[value.toInt()]['label'] as String;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    label,
                    style: AppTheme.caption,
                    overflow: TextOverflow.ellipsis,
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
            reservedSize: 40,
            getTitlesWidget: (value, meta) =>
                Text(value.toInt().toString(), style: AppTheme.caption),
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
            return BarTooltipItem(
              '${rod.toY.toInt()}',
              AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 48, color: AppTheme.greyMedium),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(message, style: AppTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

/// Gráfica de dona (pie chart)
class DonutChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String title;

  const DonutChart({super.key, required this.data, required this.title});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState('Sin datos disponibles');
    }

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
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    _buildPieChartData(),
                    swapAnimationDuration: const Duration(milliseconds: 250),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceLarge),
                Expanded(child: _buildLegend()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.donut_large_rounded, color: AppTheme.neonPink, size: 20),
        const SizedBox(width: AppTheme.spaceSmall),
        Expanded(
          child: Text(
            title,
            style: AppTheme.headingMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  PieChartData _buildPieChartData() {
    final colors = [
      AppTheme.primaryPurple,
      AppTheme.neonCyan,
      AppTheme.neonOrange,
      AppTheme.neonGreen,
      AppTheme.neonPink,
      AppTheme.neonYellow,
    ];

    final sections = <PieChartSectionData>[];
    final total = data.fold<double>(
      0,
      (sum, item) =>
          sum + ((item['count'] ?? item['value'] ?? 0) as num).toDouble(),
    );

    for (var i = 0; i < data.length && i < 6; i++) {
      final value = ((data[i]['count'] ?? data[i]['value'] ?? 0) as num)
          .toDouble();
      final percentage = (value / total * 100).toStringAsFixed(1);

      sections.add(
        PieChartSectionData(
          value: value,
          title: '$percentage%',
          color: colors[i % colors.length],
          radius: 60,
          titleStyle: AppTheme.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return PieChartData(
      sections: sections,
      sectionsSpace: 2,
      centerSpaceRadius: 40,
      pieTouchData: PieTouchData(touchCallback: (event, response) {}),
    );
  }

  Widget _buildLegend() {
    final colors = [
      AppTheme.primaryPurple,
      AppTheme.neonCyan,
      AppTheme.neonOrange,
      AppTheme.neonGreen,
      AppTheme.neonPink,
      AppTheme.neonYellow,
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.take(6).toList().asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final label =
            item['code'] ??
            item['event_type'] ??
            item['label'] ??
            'Item ${index + 1}';
        final value = (item['count'] ?? item['value'] ?? 0).toString();

        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spaceSmall),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colors[index % colors.length],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppTheme.spaceSmall),
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                value,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(String message) {
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.donut_large, size: 48, color: AppTheme.greyMedium),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(message, style: AppTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
