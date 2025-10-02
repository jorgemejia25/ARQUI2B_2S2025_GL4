import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Componentes específicos para el dashboard con diseño shadcn
class DashboardComponents {
  /// Header del dashboard con título y acciones
  static Widget buildDashboardHeader({
    required String title,
    String? subtitle,
    List<Widget>? actions,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.greyMedium.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.headingLarge.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppTheme.spaceXSmall),
                  Text(
                    subtitle,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actions != null) ...actions,
        ],
      ),
    );
  }

  /// Grid de métricas principales
  static Widget buildMetricsGrid({required List<MetricCard> metrics}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: AppTheme.spaceSmall,
        mainAxisSpacing: AppTheme.spaceSmall,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) => MetricCardWidget(metric: metrics[index]),
    );
  }

  /// Sección de gráficas
  static Widget buildChartsSection({
    required List<Widget> charts,
    String title = 'Análisis en Tiempo Real',
  }) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spaceMedium),
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.greyMedium.withOpacity(0.2),
          width: 1,
        ),
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
          Text(
            title,
            style: AppTheme.headingMedium.copyWith(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: AppTheme.spaceLarge),
          ...charts.map(
            (chart) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spaceMedium),
              child: chart,
            ),
          ),
        ],
      ),
    );
  }

  /// Sección de alertas
  static Widget buildAlertsSection({
    required Widget alertChart,
    String title = 'Distribución de Alertas',
  }) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spaceMedium),
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.greyMedium.withOpacity(0.2),
          width: 1,
        ),
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
          Text(
            title,
            style: AppTheme.headingMedium.copyWith(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: AppTheme.spaceLarge),
          alertChart,
        ],
      ),
    );
  }

  /// Sección de métricas detalladas
  static Widget buildDetailedMetrics({
    required List<MetricRow> metrics,
    String title = 'Métricas del Sistema',
  }) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spaceMedium),
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.greyMedium.withOpacity(0.2),
          width: 1,
        ),
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
          Text(
            title,
            style: AppTheme.headingMedium.copyWith(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: AppTheme.spaceLarge),
          ...metrics.map(
            (metric) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spaceSmall),
              child: MetricRowWidget(metric: metric),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modelo para tarjetas de métricas
class MetricCard {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final String? trend;

  const MetricCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.trend,
  });
}

/// Widget para tarjetas de métricas
class MetricCardWidget extends StatelessWidget {
  final MetricCard metric;

  const MetricCardWidget({super.key, required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceSmall),
      decoration: BoxDecoration(
        color: AppTheme.backgroundElevated.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: metric.color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceSmall),
                decoration: BoxDecoration(
                  color: metric.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(metric.icon, color: metric.color, size: 20),
              ),
              const Spacer(),
              if (metric.trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceSmall,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.neonGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    metric.trend!,
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.neonGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            metric.value,
            style: AppTheme.headingMedium.copyWith(
              color: AppTheme.textPrimary,
              fontSize: 24,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          Text(
            metric.title,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          if (metric.subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              metric.subtitle!,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textTertiary,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ],
      ),
    );
  }
}

/// Modelo para filas de métricas
class MetricRow {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const MetricRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

/// Widget para filas de métricas
class MetricRowWidget extends StatelessWidget {
  final MetricRow metric;

  const MetricRowWidget({super.key, required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.backgroundElevated.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: metric.color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceSmall),
            decoration: BoxDecoration(
              color: metric.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(metric.icon, color: metric.color, size: 20),
          ),
          const SizedBox(width: AppTheme.spaceMedium),
          Expanded(
            child: Text(
              metric.label,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceSmall,
              vertical: AppTheme.spaceXSmall,
            ),
            decoration: BoxDecoration(
              color: metric.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(
                color: metric.color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              metric.value,
              style: AppTheme.bodyMedium.copyWith(
                color: metric.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de estado de carga mejorado
class DashboardLoadingState extends StatelessWidget {
  const DashboardLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceXLarge),
            decoration: BoxDecoration(
              color: AppTheme.backgroundCard,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: AppTheme.primaryPurple.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: CircularProgressIndicator(
              color: AppTheme.primaryPurple,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: AppTheme.spaceLarge),
          Text(
            'Cargando datos del sistema...',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
