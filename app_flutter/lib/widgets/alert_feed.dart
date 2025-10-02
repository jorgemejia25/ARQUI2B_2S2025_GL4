import 'package:flutter/material.dart';
import '../services/websocket_alerts.dart';
import '../models/websocket_message.dart';
import '../config/app_theme.dart';

/// Feed de alertas en tiempo real con filtros por tipo.
class AlertsFeed extends StatefulWidget {
  const AlertsFeed({super.key});

  @override
  State<AlertsFeed> createState() => _AlertsFeedState();
}

class _AlertsFeedState extends State<AlertsFeed> {
  final WebSocketAlertsService _ws = WebSocketAlertsService.instance;

  // Filtros activos. Si está vacío => muestra todos.
  final Set<AlertType> _filters = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppTheme.spaceMedium),
        _buildFilters(),
        const SizedBox(height: AppTheme.spaceMedium),
        Expanded(
          child: StreamBuilder<List<AlertData>>(
            stream: _ws.alertsStream,
            initialData: _ws.recentAlerts,
            builder: (context, snap) {
              final all = (snap.data ?? const <AlertData>[]);

              final list = _filters.isEmpty
                  ? all
                  : all.where((a) => _filters.contains(a.kind)).toList();

              if (list.isEmpty) {
                return const _EmptyState();
              }

              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceMedium,
                  AppTheme.spaceSmall,
                  AppTheme.spaceMedium,
                  AppTheme.spaceLarge,
                ),
                itemCount: list.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppTheme.spaceSmall),
                itemBuilder: (_, i) =>
                    _AlertCard(alert: list[list.length - 1 - i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    Widget chip(AlertType t, String label, IconData icon, Color color) {
      final selected = _filters.contains(t);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXSmall),
        child: Container(
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected
                ? null
                : AppTheme.backgroundElevated.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: selected
                  ? color.withOpacity(0.5)
                  : AppTheme.greyMedium.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: selected ? AppTheme.cardShadow : null,
          ),
          child: FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: selected ? Colors.white : color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTheme.bodySmall.copyWith(
                    color: selected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
            selected: selected,
            onSelected: (v) {
              setState(() {
                if (v) {
                  _filters.add(t);
                } else {
                  _filters.remove(t);
                }
              });
            },
            backgroundColor: Colors.transparent,
            selectedColor: Colors.transparent,
            checkmarkColor: Colors.white,
            side: BorderSide.none,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSmall),
      child: Row(
        children: [
          chip(
            AlertType.infraccion,
            'Semáforo',
            Icons.traffic,
            AppTheme.neonOrange,
          ),
          chip(AlertType.panico, 'Pánico', Icons.campaign, AppTheme.error),
          chip(
            AlertType.seismicAlert,
            'Sismo',
            Icons.vibration,
            AppTheme.neonYellow,
          ),
          chip(AlertType.gasAlert, 'Gas/Humo', Icons.co2, AppTheme.neonCyan),
          chip(
            AlertType.signalUpdate,
            'Señales',
            Icons.sync_alt,
            AppTheme.primaryPurple,
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de alerta que consume directamente AlertData (tu modelo unificado).
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
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }

  static IconData _iconFor(AlertType t) {
    switch (t) {
      case AlertType.infraccion:
        return Icons.traffic;
      case AlertType.panico:
        return Icons.campaign;
      case AlertType.seismicAlert:
        return Icons.vibration;
      case AlertType.gasAlert:
        return Icons.co2;
      case AlertType.signalUpdate:
        return Icons.sync_alt;
      case AlertType.unknown:
        return Icons.notification_important;
    }
  }

  static Color _colorFor(int severity) {
    // Mapea severidad 1..5 a colores neón
    if (severity >= 5) return AppTheme.error; // crítico/rojo
    if (severity == 4) return AppTheme.neonOrange; // alto/naranja
    if (severity == 3) return AppTheme.neonYellow; // medio/amarillo
    if (severity == 2) return AppTheme.neonGreen; // bajo/verde
    return AppTheme.neonCyan; // info/cian
  }
}

class _SeverityPill extends StatelessWidget {
  final int severity;
  const _SeverityPill({required this.severity});

  @override
  Widget build(BuildContext context) {
    final color = _AlertCard._colorFor(severity);
    final label = () {
      if (severity >= 5) return 'Crítica';
      if (severity == 4) return 'Alta';
      if (severity == 3) return 'Media';
      if (severity == 2) return 'Baja';
      return 'Info';
    }();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceSmall,
        vertical: AppTheme.spaceXSmall,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceLarge),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryPurple.withOpacity(0.1),
                    AppTheme.primaryPurple.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                border: Border.all(
                  color: AppTheme.primaryPurple.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 48,
                color: AppTheme.primaryPurpleLight,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            Text(
              'No hay alertas recientes',
              style: AppTheme.headingSmall.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              'Las alertas aparecerán aquí cuando se detecten eventos',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
