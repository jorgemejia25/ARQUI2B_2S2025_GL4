import 'package:flutter/material.dart';
import '../services/websocket_alerts.dart';
import '../models/websocket_message.dart';

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
        const SizedBox(height: 8),
        _buildFilters(),
        Expanded(
          child: StreamBuilder<List<AlertData>>(
            stream: _ws.alertsStream,
            initialData: _ws.recentAlerts, // por si ya llegaron antes de montar
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
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) =>
                    _AlertCard(alert: list[list.length - 1 - i]),
                // opcional: invertido simple para mostrar las más recientes arriba
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    Widget chip(AlertType t, String label, IconData icon) {
      final selected = _filters.contains(t);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Text(label),
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
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          chip(AlertType.infraccion, 'Semáforo', Icons.traffic),
          chip(AlertType.panico, 'Pánico', Icons.campaign),
          chip(AlertType.seismicAlert, 'Sismo', Icons.vibration),
          chip(AlertType.gasAlert, 'Gas/Humo', Icons.co2),
          chip(AlertType.signalUpdate, 'Señales', Icons.sync_alt),
          // agrega más chips si sumas más tipos
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

    return Card(
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          ListTile(
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),
            title: Text(
              alert.title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A8A),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Evitar subtítulo duplicado si ya mostramos la ubicación ---
                Builder(
                  builder: (_) {
                    final subtitleText = alert.subtitle;
                    final loc = (location ?? '');
                    final bool showSubtitle =
                        subtitleText.isNotEmpty &&
                        !(loc.isNotEmpty &&
                            // si el subtítulo contiene el mismo texto que la ubicación, lo ocultamos
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
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(subtitleText),
                          )
                        : const SizedBox.shrink();
                  },
                ),

                if ((alert.tipoTransporte ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Transporte: ${alert.tipoTransporte!}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],

                if ((location ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.place,
                        size: 14,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        location!,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 8),
                _SeverityPill(severity: alert.severity),
              ],
            ),
          ),
          if (alert.timeAgo.isNotEmpty)
            Positioned(
              right: 10,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  alert.timeAgo,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ),
        ],
      ),
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
    // Mapea tu severidad 1..5 a colores (baja..alta)
    if (severity >= 5) return const Color(0xFF7F1D1D); // muy alto/burdeos
    if (severity == 4) return const Color(0xFFDC2626); // alto/rojo
    if (severity == 3) return const Color(0xFFF59E0B); // medio/ámbar
    if (severity == 2) return const Color(0xFF16A34A); // bajo/verde
    return const Color(0xFF0891B2); // info/cian
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No hay alertas recientes',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      ),
    );
  }
}
