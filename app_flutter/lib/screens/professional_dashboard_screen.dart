import 'dart:async';
import 'package:flutter/material.dart';
import '../layouts/modern_layout.dart';
import '../services/advanced_dashboard_api_service.dart';
import '../widgets/dashboard_filters.dart';
import '../widgets/advanced_charts.dart';
import '../widgets/dashboard_components.dart';
import '../widgets/charts_carousel.dart';
import '../widgets/specialized_charts.dart';
import '../config/app_theme.dart';

/// Dashboard profesional con filtros avanzados y análisis en tiempo real
class ProfessionalDashboardScreen extends StatefulWidget {
  const ProfessionalDashboardScreen({super.key});

  @override
  State<ProfessionalDashboardScreen> createState() =>
      _ProfessionalDashboardScreenState();
}

class _ProfessionalDashboardScreenState
    extends State<ProfessionalDashboardScreen>
    with TickerProviderStateMixin {
  final _apiService = AdvancedDashboardApiService();

  // Estado
  bool _isLoading = true;
  bool _showFilters = false;
  String? _error;

  // Datos
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _analytics;
  Map<String, dynamic>? _timeline;
  Map<String, dynamic>? _comparison;
  Map<String, dynamic>? _realtimeStream;
  Map<String, dynamic>? _gasAnalytics;
  Map<String, dynamic>? _seismicAnalytics;
  Map<String, dynamic>? _systemHealth;

  // Filtros
  late DashboardFilters _filters;

  // Auto-refresh timer
  Timer? _refreshTimer;

  // Controlador de animación
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;

  @override
  void initState() {
    super.initState();
    // Establecer fechas por defecto que incluyan los datos disponibles
    _filters = DashboardFilters(
      startDate: DateTime(
        2025,
        10,
        1,
      ), // Fecha que incluye los datos disponibles
      endDate: DateTime(2025, 10, 3), // Fecha que incluye los datos disponibles
    );

    // Configurar animación de filtros
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );

    _loadAllData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _filterAnimationController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Actualizar datos en tiempo real cada 30 segundos
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadRealtimeData();
    });
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Future.wait([
        _loadSummary(),
        _loadAnalytics(),
        _loadTimeline(),
        _loadComparison(),
        _loadRealtimeData(),
        _loadGasAnalytics(),
        _loadSeismicAnalytics(),
        _loadSystemHealth(),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSummary() async {
    final data = await _apiService.getSummary();
    print('Summary data received: $data');
    if (mounted) {
      setState(() {
        _summary = data;
      });
    }
  }

  Future<void> _loadAnalytics() async {
    final data = await _apiService.getAdvancedAnalytics(filters: _filters);
    print('Analytics data received: $data');
    if (mounted) {
      setState(() {
        _analytics = data;
      });
    }
  }

  Future<void> _loadTimeline() async {
    final data = await _apiService.getTimelineChart(
      startDate: _filters.startDate,
      endDate: _filters.endDate,
      granularity: _filters.groupBy,
    );
    print('Timeline data received: $data');
    if (mounted) {
      setState(() {
        _timeline = data;
      });
    }
  }

  Future<void> _loadComparison() async {
    final data = await _apiService.getComparisonChart(
      metric: 'alerts',
      startDate: _filters.startDate,
      endDate: _filters.endDate,
      compareBy: 'type',
    );
    print('Comparison data received: $data');
    if (mounted) {
      setState(() {
        _comparison = data;
      });
    }
  }

  Future<void> _loadRealtimeData() async {
    final data = await _apiService.getRealtimeStream(minutes: 5);
    if (mounted) {
      setState(() {
        _realtimeStream = data;
      });
    }
  }

  Future<void> _loadGasAnalytics() async {
    final data = await _apiService.getGasAnalytics(
      startDate: _filters.startDate,
      endDate: _filters.endDate,
    );
    print('Gas analytics data received: $data');
    if (mounted) {
      setState(() {
        _gasAnalytics = data;
      });
    }
  }

  Future<void> _loadSeismicAnalytics() async {
    final data = await _apiService.getSeismicAnalytics(
      startDate: _filters.startDate,
      endDate: _filters.endDate,
    );
    print('Seismic analytics data received: $data');
    if (mounted) {
      setState(() {
        _seismicAnalytics = data;
      });
    }
  }

  Future<void> _loadSystemHealth() async {
    final data = await _apiService.getSystemHealthMetrics();
    print('System health data received: $data');
    if (mounted) {
      setState(() {
        _systemHealth = data;
      });
    }
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });

    if (_showFilters) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
    }
  }

  void _applyFilters(DashboardFilters newFilters) {
    setState(() {
      _filters = newFilters;
    });
    _loadAllData();
  }

  @override
  Widget build(BuildContext context) {
    return ModernLayout(
      title: 'Dashboard',
      currentRoute: '/dashboard',
      child: Stack(
        children: [
          // Contenido principal
          RefreshIndicator(
            onRefresh: _loadAllData,
            color: AppTheme.primaryPurple,
            backgroundColor: AppTheme.backgroundCard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Header con acciones
                  if (_isLoading)
                    _buildLoadingState()
                  else if (_error != null)
                    _buildErrorState()
                  else ...[
                    // KPIs principales
                    _buildKPISection(),

                    // Análisis en tiempo real
                    _buildRealtimeSection(),

                    // Carrusel de gráficas
                    _buildChartsCarousel(),

                    // Análisis avanzado
                    _buildAdvancedAnalyticsSection(),
                  ],

                  const SizedBox(height: AppTheme.spaceXLarge),
                ],
              ),
            ),
          ),

          // FloatingActionButton para filtros
          Positioned(
            right: AppTheme.spaceMedium,
            bottom: AppTheme.spaceMedium,
            child: Container(
              decoration: BoxDecoration(
                gradient: _filters.hasActiveFilters
                    ? AppTheme.purpleGradient
                    : LinearGradient(
                        colors: [
                          AppTheme.backgroundElevated,
                          AppTheme.backgroundElevated.withOpacity(0.8),
                        ],
                      ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: _filters.hasActiveFilters
                        ? AppTheme.primaryPurple.withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                heroTag: 'fabFilters',
                onPressed: _toggleFilters,
                backgroundColor: Colors.transparent,
                elevation: 0,
                icon: Stack(
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      color: _filters.hasActiveFilters
                          ? Colors.white
                          : AppTheme.textSecondary,
                    ),
                    if (_filters.hasActiveFilters)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppTheme.neonOrange,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 8,
                            minHeight: 8,
                          ),
                        ),
                      ),
                  ],
                ),
                label: Text(
                  'Filtros',
                  style: AppTheme.bodyMedium.copyWith(
                    color: _filters.hasActiveFilters
                        ? Colors.white
                        : AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          // Panel de filtros flotante
          if (_showFilters)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleFilters,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: FadeTransition(
                    opacity: _filterAnimation,
                    child: Center(
                      child: GestureDetector(
                        onTap:
                            () {}, // Prevenir que se cierre al tocar el panel
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.spaceLarge),
                            child: DashboardFiltersPanel(
                              filters: _filters,
                              onFiltersChanged: _applyFilters,
                              onClose: _toggleFilters,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKPISection() {
    if (_summary == null) return const SizedBox.shrink();

    final totalAlerts = _summary!['total_alerts'] ?? 0;
    final recent24h = _summary!['recent_alerts_24h'] ?? 0;
    final totalBuses = _summary!['total_buses'] ?? 0;
    final totalRoutes = _summary!['total_routes'] ?? 0;

    final kpis = [
      MetricCard(
        title: 'Total de Alertas',
        value: totalAlerts.toString(),
        subtitle: 'Todas las alertas',
        icon: Icons.notifications_active_rounded,
        color: AppTheme.neonOrange,
        trend:
            '+${((recent24h / (totalAlerts > 0 ? totalAlerts : 1)) * 100).toStringAsFixed(1)}%',
      ),
      MetricCard(
        title: 'Últimas 24h',
        value: recent24h.toString(),
        subtitle: 'Alertas recientes',
        icon: Icons.access_time_rounded,
        color: AppTheme.neonGreen,
        trend: 'Activas',
      ),
      MetricCard(
        title: 'Buses Monitoreados',
        value: totalBuses.toString(),
        subtitle: 'En operación',
        icon: Icons.directions_bus_rounded,
        color: AppTheme.neonCyan,
        trend: '100%',
      ),
      MetricCard(
        title: 'Rutas Activas',
        value: totalRoutes.toString(),
        subtitle: 'Configuradas',
        icon: Icons.route_rounded,
        color: AppTheme.primaryPurple,
        trend: 'Operativas',
      ),
    ];

    return Container(
      margin: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed_rounded, color: AppTheme.neonGreen, size: 20),
              const SizedBox(width: AppTheme.spaceSmall),
              Text(
                'Indicadores Clave (KPIs)',
                style: AppTheme.headingMedium.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLarge),
          DashboardComponents.buildMetricsGrid(metrics: kpis),
        ],
      ),
    );
  }

  Widget _buildRealtimeSection() {
    if (_realtimeStream == null) return const SizedBox.shrink();

    final recentAlerts = _realtimeStream!['recent_alerts'] as List? ?? [];
    final totalRecent = _realtimeStream!['total_recent'] ?? 0;

    return Container(
      margin: const EdgeInsets.all(AppTheme.spaceMedium),
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.neonGreen.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonGreen.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceSmall),
                decoration: BoxDecoration(
                  color: AppTheme.neonGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(color: AppTheme.neonGreen, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.neonGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.neonGreen,
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceSmall),
                    Text(
                      'EN VIVO',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.neonGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spaceMedium),
              Expanded(
                child: Text(
                  'Actividad en Tiempo Real',
                  style: AppTheme.headingMedium.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppTheme.spaceSmall),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceMedium,
                    vertical: AppTheme.spaceSmall,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.neonGreen.withOpacity(0.2),
                        AppTheme.neonGreen.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    '$totalRecent alertas recientes',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.neonGreen,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          if (recentAlerts.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceLarge),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recentAlerts.length > 5 ? 5 : recentAlerts.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppTheme.spaceMedium),
                itemBuilder: (context, index) {
                  final alert = recentAlerts[index] as Map<String, dynamic>;
                  return _buildRealtimeAlertCard(alert);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRealtimeAlertCard(Map<String, dynamic> alert) {
    final eventType =
        alert['code'] ??
        alert['alert_type'] ??
        alert['event_type'] ??
        'UNKNOWN';
    final severity = alert['severity'] as int? ?? 1;
    final location = alert['location'] as String? ?? 'Desconocido';
    final timeAgo = alert['time_ago'] as String? ?? '';

    Color getColorForType(String type) {
      switch (type) {
        case 'INFRACCION':
          return AppTheme.neonOrange;
        case 'PANICO':
          return AppTheme.neonPink;
        case 'SISMO':
          return AppTheme.neonYellow;
        case 'GAS':
          return AppTheme.neonGreen;
        default:
          return AppTheme.greyMedium;
      }
    }

    final color = getColorForType(eventType);

    return Container(
      width: 200,
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.backgroundElevated.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(_getIconForType(eventType), color: color, size: 16),
              ),
              const SizedBox(width: AppTheme.spaceSmall),
              Expanded(
                child: Text(
                  eventType,
                  style: AppTheme.bodySmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            location,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getSeverityColor(severity).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Nivel $severity',
                  style: AppTheme.caption.copyWith(
                    color: _getSeverityColor(severity),
                    fontSize: 9,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                timeAgo,
                style: AppTheme.caption.copyWith(
                  color: AppTheme.textTertiary,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'INFRACCION':
        return Icons.directions_car_rounded;
      case 'PANICO':
        return Icons.warning_amber_rounded;
      case 'SISMO':
        return Icons.vibration_rounded;
      case 'GAS':
        return Icons.air_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  Color _getSeverityColor(int severity) {
    switch (severity) {
      case 1:
        return AppTheme.neonGreen;
      case 2:
        return AppTheme.neonYellow;
      case 3:
        return AppTheme.neonOrange;
      case 4:
        return AppTheme.error;
      default:
        return AppTheme.greyMedium;
    }
  }

  Widget _buildChartsCarousel() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_rounded, color: AppTheme.neonCyan, size: 20),
              const SizedBox(width: AppTheme.spaceSmall),
              Text(
                'Análisis Avanzado de Datos',
                style: AppTheme.headingMedium.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLarge),
          ChartsCarousel(
            timelineData: _timeline,
            comparisonData: _comparison,
            gasData: _gasAnalytics,
            seismicData: _seismicAnalytics,
            systemHealthData: _systemHealth,
            summaryData: _summary,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsOverview() {
    final gasStats = _gasAnalytics?['statistics'];
    final seismicStats = _seismicAnalytics?['statistics'];

    return Container(
      margin: const EdgeInsets.all(AppTheme.spaceMedium),
      child: MetricsOverview(
        gasStats: gasStats,
        seismicStats: seismicStats,
        systemHealth: _systemHealth,
      ),
    );
  }

  Widget _buildAdvancedAnalyticsSection() {
    if (_analytics == null) return const SizedBox.shrink();

    final data = _analytics!['analytics'] as List? ?? [];
    final summary = _analytics!['summary'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: AppTheme.neonPink,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spaceSmall),
              Text(
                'Análisis Avanzado',
                style: AppTheme.headingMedium.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLarge),
          if (summary.isNotEmpty) _buildSummaryStats(summary),
          const SizedBox(height: AppTheme.spaceLarge),
          if (data.isNotEmpty)
            TimelineChart(
              data: List<Map<String, dynamic>>.from(data),
              title: 'Tendencias por Período',
              subtitle: 'Análisis detallado con filtros aplicados',
            )
          else
            _buildEmptyChart('No hay datos para los filtros seleccionados'),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(Map<String, dynamic> summary) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.backgroundElevated.withOpacity(0.5),
            AppTheme.backgroundCard,
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.greyMedium.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Total',
              summary['total_alerts']?.toString() ?? '0',
              Icons.format_list_numbered_rounded,
              AppTheme.primaryPurple,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.greyMedium.withOpacity(0.2),
          ),
          Expanded(
            child: _buildStatItem(
              'Prom. Severidad',
              (summary['avg_severity'] as num?)?.toStringAsFixed(1) ?? '0.0',
              Icons.trending_up_rounded,
              AppTheme.neonYellow,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.greyMedium.withOpacity(0.2),
          ),
          Expanded(
            child: _buildStatItem(
              'Máxima',
              summary['max_severity']?.toString() ?? '0',
              Icons.arrow_upward_rounded,
              AppTheme.neonOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: AppTheme.spaceXSmall),
            Text(
              value,
              style: AppTheme.headingMedium.copyWith(
                color: color,
                fontSize: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceXSmall),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildComparisonSection() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.compare_arrows_rounded,
                color: AppTheme.neonOrange,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spaceSmall),
              Text(
                'Análisis Comparativo',
                style: AppTheme.headingMedium.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLarge),
          // Gráfica de barras comparativa (más grande)
          Container(
            height: 400,
            margin: const EdgeInsets.only(bottom: AppTheme.spaceLarge),
            child: _comparison != null && _comparison!['comparison'] != null
                ? ComparisonBarChart(
                    data: List<Map<String, dynamic>>.from(
                      _comparison!['comparison'] as List,
                    ),
                    title: 'Por Tipo de Evento',
                    metric: 'alerts',
                  )
                : _buildEmptyChart('Sin datos de comparación'),
          ),

          // Gráfica de dona de distribución (más grande)
          Container(
            height: 400,
            child: _summary != null && _summary!['alerts_by_type'] != null
                ? DonutChart(
                    data: List<Map<String, dynamic>>.from(
                      _summary!['alerts_by_type'] as List,
                    ),
                    title: 'Distribución de Alertas por Tipo',
                  )
                : DonutChart(
                    data: [
                      {'event_type': 'Infracciones', 'count': 45},
                      {'event_type': 'Alertas de Pánico', 'count': 23},
                      {'event_type': 'Detección de Gas', 'count': 18},
                      {'event_type': 'Sismos', 'count': 12},
                      {'event_type': 'Otros', 'count': 8},
                    ],
                    title: 'Distribución de Alertas por Tipo',
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(String message) {
    return Container(
      height: 300,
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

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spaceXLarge),
        child: DashboardLoadingState(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppTheme.spaceLarge),
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        decoration: BoxDecoration(
          color: AppTheme.backgroundCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: AppTheme.error.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 48),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              'Error al cargar datos',
              style: AppTheme.headingMedium.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              _error ?? 'Error desconocido',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            ElevatedButton(
              onPressed: _loadAllData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
