import 'dart:async';
import 'package:flutter/material.dart';
import '../layouts/main_layout.dart';
import '../services/dashboard_api_service.dart';
import '../models/dashboard_models.dart';
import '../widgets/dashboard_charts.dart';

/// Pantalla del dashboard que muestra el panel de control principal.
///
/// Esta pantalla es el punto de entrada principal para la gestión del tráfico
/// y proporciona acceso a las funcionalidades principales del sistema.
class DashboardScreen extends StatefulWidget {
  /// Constructor de la pantalla del dashboard.
  ///
  /// [key] - Clave opcional para el widget.
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardApiService _apiService = DashboardApiService();
  Timer? _refreshTimer;

  DashboardSummary? _summary;
  GasChartData? _gasData;
  SeismicChartData? _seismicData;
  List<DetailedBusStatus>? _busesStatus;
  DashboardMetrics? _metrics;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    try {
      final futures = await Future.wait([
        _apiService.getSummary(),
        _apiService.getGasChartData(),
        _apiService.getSeismicChartData(),
        _apiService.getBusesStatus(),
        _apiService.getMetrics(),
      ]);

      if (mounted) {
        setState(() {
          _summary = futures[0] as DashboardSummary?;
          _gasData = futures[1] as GasChartData?;
          _seismicData = futures[2] as SeismicChartData?;
          _busesStatus = futures[3] as List<DetailedBusStatus>?;
          _metrics = futures[4] as DashboardMetrics?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Dashboard',
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
            )
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: const Color(0xFF1E3A8A),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Resumen general
                    _buildSummaryCards(),
                    const SizedBox(height: 24),

                    // Gráficas principales
                    _buildChartsSection(),
                    const SizedBox(height: 24),

                    // Estado de buses
                    _buildBusesSection(),
                    const SizedBox(height: 24),

                    // Métricas del sistema
                    _buildMetricsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    final summary = _summary;
    if (summary == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen del Sistema',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildSummaryCard(
              'Alertas Totales',
              summary.alertsSummary
                  .fold(0, (sum, alert) => sum + alert.count)
                  .toString(),
              Icons.warning_amber_rounded,
              const Color(0xFFF59E0B),
            ),
            _buildSummaryCard(
              'Buses Activos',
              summary.busesStatus.length.toString(),
              Icons.directions_bus_rounded,
              const Color(0xFF10B981),
            ),
            _buildSummaryCard(
              'Gas Actual',
              summary.latestGas.isNotEmpty
                  ? '${summary.latestGas.first.ppm.toStringAsFixed(1)} PPM'
                  : '0.0 PPM',
              Icons.air_rounded,
              const Color(0xFF3B82F6),
            ),
            _buildSummaryCard(
              'Actividad Sísmica',
              summary.latestSeismic.isNotEmpty
                  ? '${summary.latestSeismic.first.intensityG.toStringAsFixed(2)} G'
                  : '0.00 G',
              Icons.vibration_rounded,
              const Color(0xFFEF4444),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tendencias (Últimas 24h)',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.8,
          mainAxisSpacing: 16,
          children: [
            _buildChartCard(
              child: _gasData != null
                  ? GasChart(data: _gasData!.data)
                  : const Center(child: Text('Cargando datos de gas...')),
            ),
            _buildChartCard(
              child: _seismicData != null
                  ? SeismicChart(data: _seismicData!.data)
                  : const Center(child: Text('Cargando datos sísmicos...')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBusesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estado de Transporte',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          children: [
            _buildChartCard(
              child: _busesStatus != null
                  ? BusStatusChart(buses: _busesStatus!)
                  : const Center(child: Text('Cargando estado de buses...')),
            ),
            _buildChartCard(
              child: _summary != null
                  ? AlertsChart(data: _summary!.alertsSummary)
                  : const Center(child: Text('Cargando alertas...')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricsSection() {
    final metrics = _metrics;
    if (metrics == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Métricas del Sistema',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Registros por Tabla',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 12),
              ...metrics.tableCounts.map(
                (table) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        table.tableName
                            .replaceAll('Measurement', '')
                            .replaceAll('Event', ''),
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        '${table.count}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
