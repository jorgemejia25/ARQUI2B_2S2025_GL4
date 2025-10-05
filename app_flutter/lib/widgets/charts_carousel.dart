import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'advanced_charts.dart';
import 'specialized_charts.dart';

/// Carrusel de gráficas con swiper
class ChartsCarousel extends StatefulWidget {
  final Map<String, dynamic>? timelineData;
  final Map<String, dynamic>? comparisonData;
  final Map<String, dynamic>? gasData;
  final Map<String, dynamic>? seismicData;
  final Map<String, dynamic>? systemHealthData;
  final Map<String, dynamic>? summaryData;

  const ChartsCarousel({
    super.key,
    this.timelineData,
    this.comparisonData,
    this.gasData,
    this.seismicData,
    this.systemHealthData,
    this.summaryData,
  });

  @override
  State<ChartsCarousel> createState() => _ChartsCarouselState();
}

class _ChartsCarouselState extends State<ChartsCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final charts = _buildCharts();

    return Column(
      children: [
        // Indicadores de página
        _buildPageIndicators(charts.length),
        const SizedBox(height: AppTheme.spaceMedium),

        // Carrusel de gráficas
        SizedBox(
          height: 400,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: charts.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceMedium,
                ),
                child: charts[index],
              );
            },
          ),
        ),

        const SizedBox(height: AppTheme.spaceMedium),

        // Controles de navegación
        _buildNavigationControls(charts.length),
      ],
    );
  }

  Widget _buildPageIndicators(int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? AppTheme.primaryPurple
                : AppTheme.greyMedium.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildNavigationControls(int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _currentPage > 0
              ? () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                )
              : null,
          icon: Icon(
            Icons.chevron_left_rounded,
            color: _currentPage > 0
                ? AppTheme.primaryPurple
                : AppTheme.greyMedium,
          ),
        ),
        const SizedBox(width: AppTheme.spaceLarge),
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
            '${_currentPage + 1} de $totalPages',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
          ),
        ),
        const SizedBox(width: AppTheme.spaceLarge),
        IconButton(
          onPressed: _currentPage < totalPages - 1
              ? () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                )
              : null,
          icon: Icon(
            Icons.chevron_right_rounded,
            color: _currentPage < totalPages - 1
                ? AppTheme.primaryPurple
                : AppTheme.greyMedium,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCharts() {
    final charts = <Widget>[];

    // 1. Análisis Temporal
    if (widget.timelineData != null &&
        widget.timelineData!['timeline'] != null) {
      final timelineData = widget.timelineData!['timeline'] as List;
      if (timelineData.isNotEmpty) {
        charts.add(
          TimelineChart(
            data: List<Map<String, dynamic>>.from(timelineData),
            title: 'Análisis Temporal de Alertas',
            subtitle: 'Evolución de alertas por hora',
          ),
        );
      }
    }

    // 2. Análisis Comparativo
    if (widget.comparisonData != null &&
        widget.comparisonData!['comparison'] != null) {
      final comparisonData = widget.comparisonData!['comparison'] as List;
      if (comparisonData.isNotEmpty) {
        charts.add(
          ComparisonBarChart(
            data: List<Map<String, dynamic>>.from(comparisonData),
            title: 'Comparación por Tipo de Evento',
            metric: 'alerts',
          ),
        );
      }
    }

    // 3. Distribución por Tipo
    if (widget.summaryData != null &&
        widget.summaryData!['alerts_by_type'] != null) {
      final alertsByType = widget.summaryData!['alerts_by_type'] as List;
      if (alertsByType.isNotEmpty) {
        charts.add(
          DonutChart(
            data: List<Map<String, dynamic>>.from(alertsByType),
            title: 'Distribución de Alertas por Tipo',
          ),
        );
      }
    }

    // 4. Análisis de Gas
    if (widget.gasData != null && widget.gasData!['timeline'] != null) {
      final gasTimeline = widget.gasData!['timeline'] as List;
      if (gasTimeline.isNotEmpty) {
        final thresholdPpm =
            widget.gasData!['threshold_ppm'] as double? ?? 300.0;
        charts.add(
          GasAnalyticsChart(
            data: List<Map<String, dynamic>>.from(gasTimeline),
            title: 'Análisis de Concentración de Gas',
            thresholdPpm: thresholdPpm,
          ),
        );
      }
    }

    // 5. Análisis Sísmico
    if (widget.seismicData != null &&
        widget.seismicData!['measurements'] != null) {
      final seismicMeasurements = widget.seismicData!['measurements'] as List;
      if (seismicMeasurements.isNotEmpty) {
        final thresholdIntensity =
            widget.seismicData!['threshold_intensity'] as double? ?? 2.0;
        charts.add(
          SeismicAnalyticsChart(
            data: List<Map<String, dynamic>>.from(seismicMeasurements),
            title: 'Análisis de Actividad Sísmica',
            thresholdIntensity: thresholdIntensity,
          ),
        );
      }
    }

    // 6. Salud del Sistema
    if (widget.systemHealthData != null &&
        widget.systemHealthData!.isNotEmpty) {
      charts.add(
        SystemHealthChart(
          data: widget.systemHealthData!,
          title: 'Estado de Salud del Sistema',
        ),
      );
    }

    // Si no hay gráficas, mostrar un mensaje
    if (charts.isEmpty) {
      charts.add(
        Container(
          height: 350,
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
                Icon(
                  Icons.bar_chart_rounded,
                  size: 48,
                  color: AppTheme.greyMedium,
                ),
                const SizedBox(height: AppTheme.spaceMedium),
                Text(
                  'No hay datos disponibles para mostrar gráficas',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return charts;
  }
}

/// Widget compacto para mostrar múltiples métricas en una vista
class MetricsOverview extends StatelessWidget {
  final Map<String, dynamic>? gasStats;
  final Map<String, dynamic>? seismicStats;
  final Map<String, dynamic>? systemHealth;

  const MetricsOverview({
    super.key,
    this.gasStats,
    this.seismicStats,
    this.systemHealth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
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
          Row(
            children: [
              Icon(Icons.analytics_rounded, color: AppTheme.neonCyan, size: 20),
              const SizedBox(width: AppTheme.spaceSmall),
              Text(
                'Resumen de Métricas',
                style: AppTheme.headingMedium.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLarge),

          Row(
            children: [
              // Estadísticas de Gas
              Expanded(
                child: _buildMetricCard(
                  'Gas',
                  Icons.air_rounded,
                  AppTheme.neonGreen,
                  [
                    'Mediciones: ${gasStats?['total_measurements'] ?? 0}',
                    'Promedio: ${(gasStats?['avg_ppm'] ?? 0).toStringAsFixed(1)}ppm',
                    'Máximo: ${gasStats?['max_ppm'] ?? 0}ppm',
                    'Lecturas altas: ${gasStats?['high_readings'] ?? 0}',
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spaceMedium),

              // Estadísticas Sísmicas
              Expanded(
                child: _buildMetricCard(
                  'Sísmicas',
                  Icons.vibration_rounded,
                  AppTheme.neonYellow,
                  [
                    'Eventos: ${seismicStats?['total_measurements'] ?? 0}',
                    'Promedio: ${(seismicStats?['avg_intensity'] ?? 0).toStringAsFixed(1)}g',
                    'Máximo: ${seismicStats?['max_intensity'] ?? 0}g',
                    'Significativos: ${seismicStats?['significant_events'] ?? 0}',
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spaceMedium),

              // Salud del Sistema
              Expanded(
                child: _buildMetricCard(
                  'Sistema',
                  Icons.health_and_safety_rounded,
                  AppTheme.neonCyan,
                  [
                    'Buses: ${systemHealth?['bus_statistics']?['total_buses'] ?? 0}',
                    'Rutas: ${(systemHealth?['route_coverage'] as List?)?.length ?? 0}',
                    'Con alertas: ${systemHealth?['bus_statistics']?['buses_with_alerts'] ?? 0}',
                    'Patrones: ${(systemHealth?['hourly_alert_pattern'] as List?)?.length ?? 0}',
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    IconData icon,
    Color color,
    List<String> metrics,
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
          ...metrics
              .map(
                (metric) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    metric,
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






