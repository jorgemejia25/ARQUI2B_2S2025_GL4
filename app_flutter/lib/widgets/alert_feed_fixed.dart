import 'package:flutter/material.dart';
import '../services/websocket_alerts.dart';
import '../models/websocket_message.dart';
import '../config/app_theme.dart';

/// Feed de alertas en tiempo real con filtros por tipo - Versión corregida
class AlertsFeedFixed extends StatefulWidget {
  const AlertsFeedFixed({super.key});

  @override
  State<AlertsFeedFixed> createState() => _AlertsFeedFixedState();
}

class _AlertsFeedFixedState extends State<AlertsFeedFixed> {
  final WebSocketAlertsService _ws = WebSocketAlertsService.instance;

  // Filtros activos. Si está vacío => muestra todos.
  final Set<AlertType> _filters = {};

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AlertData>>(
      stream: _ws.alertsStream,
      initialData: _ws.recentAlerts,
      builder: (context, snap) {
        final all = (snap.data ?? const <AlertData>[]);

        final list = _filters.isEmpty
            ? all
            : all.where((a) => _filters.contains(a.kind)).toList();

        return Column(
          children: [
            const SizedBox(height: AppTheme.spaceMedium),
            _buildFilters(),
            const SizedBox(height: AppTheme.spaceMedium),
            Expanded(
              child: list.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.spaceMedium,
                        AppTheme.spaceSmall,
                        AppTheme.spaceMedium,
                        AppTheme.spaceLarge,
                      ),
                      itemCount: list.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppTheme.spaceMedium),
                      itemBuilder: (context, index) =>
                          _AlertCard(alert: list[index]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Todos', null, _filters.isEmpty),
            const SizedBox(width: AppTheme.spaceSmall),
            _buildFilterChip(
              'Tráfico',
              AlertType.infraccion,
              _filters.contains(AlertType.infraccion),
            ),
            const SizedBox(width: AppTheme.spaceSmall),
            _buildFilterChip(
              'Pánico',
              AlertType.panico,
              _filters.contains(AlertType.panico),
            ),
            const SizedBox(width: AppTheme.spaceSmall),
            _buildFilterChip(
              'Sísmico',
              AlertType.seismicAlert,
              _filters.contains(AlertType.seismicAlert),
            ),
            const SizedBox(width: AppTheme.spaceSmall),
            _buildFilterChip(
              'Gas',
              AlertType.gasAlert,
              _filters.contains(AlertType.gasAlert),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, AlertType? type, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (type == null) {
            _filters.clear();
          } else {
            if (isSelected) {
              _filters.remove(type);
            } else {
              _filters.add(type);
            }
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMedium,
          vertical: AppTheme.spaceSmall,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.purpleGradient : null,
          color: isSelected
              ? null
              : AppTheme.backgroundElevated.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryPurple
                : AppTheme.greyMedium.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryPurple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTheme.bodyMedium.copyWith(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertData alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final icon = _iconFor(alert.kind);
    final color = _colorFor(alert.severity);

    // Ubicación preferida: origen > stopId > signalId
    final String? location = (alert.origen?.isNotEmpty ?? false)
        ? alert.origen
        : (alert.stopId ?? alert.signalId);

    return Container(
      decoration: AppTheme.glassDecoration.copyWith(
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono con contenedor sutil
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(color: color.withOpacity(0.3), width: 1),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: AppTheme.spaceMedium),
                // Contenido de la alerta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: AppTheme.headingSmall.copyWith(
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceSmall),

                      // Subtítulo si existe
                      Builder(
                        builder: (_) {
                          final subtitleText = alert.subtitle;
                          final loc = (location ?? '');
                          final bool showSubtitle =
                              subtitleText.isNotEmpty &&
                              !(loc.isNotEmpty &&
                                  (subtitleText.toLowerCase().contains(
                                        loc.toLowerCase(),
                                      ) ||
                                      subtitleText.toLowerCase().startsWith(
                                        'parada',
                                      ) ||
                                      subtitleText.toLowerCase().startsWith(
                                        'origen',
                                      )));

                          return showSubtitle
                              ? Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppTheme.spaceSmall,
                                  ),
                                  child: Text(
                                    subtitleText,
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink();
                        },
                      ),

                      // Información adicional
                      if ((alert.tipoTransporte ?? '').isNotEmpty) ...[
                        _buildInfoRow(
                          Icons.directions_bus_rounded,
                          'Transporte: ${alert.tipoTransporte!}',
                          AppTheme.neonCyan,
                        ),
                        const SizedBox(height: AppTheme.spaceXSmall),
                      ],

                      // Información sísmica
                      if (alert.seismicIntensity != null) ...[
                        _buildInfoRow(
                          Icons.vibration_rounded,
                          'Magnitud: ${alert.seismicIntensity!.toStringAsFixed(2)} G',
                          AppTheme.neonYellow,
                        ),
                        if (alert.thresholdG != null) ...[
                          const SizedBox(height: AppTheme.spaceXSmall),
                          _buildInfoRow(
                            Icons.trending_up_rounded,
                            'Umbral: ${alert.thresholdG!.toStringAsFixed(1)} G',
                            AppTheme.neonYellow.withOpacity(0.7),
                          ),
                        ],
                        const SizedBox(height: AppTheme.spaceXSmall),
                      ],

                      // Ubicación
                      if ((location ?? '').isNotEmpty) ...[
                        _buildInfoRow(
                          Icons.place_rounded,
                          location!,
                          AppTheme.primaryPurpleLight,
                        ),
                        const SizedBox(height: AppTheme.spaceSmall),
                      ],

                      // Severidad
                      _SeverityPill(severity: alert.severity),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Timestamp
          if (alert.timeAgo.isNotEmpty)
            Positioned(
              right: AppTheme.spaceMedium,
              top: AppTheme.spaceMedium,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceSmall,
                  vertical: AppTheme.spaceXSmall,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.greyDark.withOpacity(0.8),
                      AppTheme.greyDark.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(
                    color: AppTheme.greyMedium.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  alert.timeAgo,
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppTheme.spaceXSmall),
        Expanded(
          child: Text(
            text,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  IconData _iconFor(AlertType kind) {
    switch (kind) {
      case AlertType.infraccion:
        return Icons.directions_car_rounded;
      case AlertType.panico:
        return Icons.warning_amber_rounded;
      case AlertType.seismicAlert:
        return Icons.vibration_rounded;
      case AlertType.gasAlert:
        return Icons.air_rounded;
      case AlertType.signalUpdate:
        return Icons.traffic_rounded;
      case AlertType.robo:
        return Icons.warning_rounded;
      case AlertType.arma:
        return Icons.gavel_rounded;
      case AlertType.unknown:
        return Icons.help_rounded;
    }
  }

  Color _colorFor(int severity) {
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
}

class _SeverityPill extends StatelessWidget {
  final int severity;

  const _SeverityPill({required this.severity});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _getSeverityInfo(severity);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceSmall,
        vertical: AppTheme.spaceXSmall,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        label,
        style: AppTheme.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (String, Color) _getSeverityInfo(int severity) {
    switch (severity) {
      case 1:
        return ('Baja', AppTheme.neonGreen);
      case 2:
        return ('Media', AppTheme.neonYellow);
      case 3:
        return ('Alta', AppTheme.neonOrange);
      case 4:
        return ('Crítica', AppTheme.error);
      default:
        return ('Desconocida', AppTheme.greyMedium);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
                color: AppTheme.greyMedium.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              size: 64,
              color: AppTheme.greyMedium,
            ),
          ),
          const SizedBox(height: AppTheme.spaceLarge),
          Text(
            'No hay alertas disponibles',
            style: AppTheme.headingMedium.copyWith(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            'Las alertas aparecerán aquí cuando se detecten eventos',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
