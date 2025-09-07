import 'package:flutter/material.dart';
import '../layouts/main_layout.dart';

/// ---- Modelo simple (local, sin API) ----
enum AlertType { redLight, panic, earthquake, fire, gas, bus, generic }
enum Severity { low, medium, high }

class NotificationItem {
  final String id;
  final AlertType type;
  final Severity severity;
  final String title;
  final String message;
  final DateTime timestamp;
  final String? location;

  NotificationItem({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.timestamp,
    this.location,
  });
}

/// ---- Screen ----
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<NotificationItem> _all = [];
  final Set<AlertType> _filters = {}; // vacío = mostrar todos
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _seed(); // carga inicial quemada
  }

  void _seed() {
    final now = DateTime.now();
    _all
      ..clear()
      ..addAll([
        NotificationItem(
          id: 'A-0001',
          type: AlertType.panic,
          severity: Severity.high,
          title: 'Botón de pánico',
          message: 'Parada TM2 reportó emergencia.',
          timestamp: now.subtract(const Duration(minutes: 1)),
          location: 'TM2',
        ),
        NotificationItem(
          id: 'A-0002',
          type: AlertType.redLight,
          severity: Severity.medium,
          title: 'Infracción de semáforo',
          message: 'Bus se pasó en rojo en Av. Reforma.',
          timestamp: now.subtract(const Duration(minutes: 5)),
          location: 'Reforma y 7a',
        ),
        NotificationItem(
          id: 'A-0003',
          type: AlertType.gas,
          severity: Severity.high,
          title: 'Gas/Humo elevado',
          message: 'Umbral superado en Sitio Histórico 1.',
          timestamp: now.subtract(const Duration(minutes: 12)),
          location: 'SH-1',
        ),
        NotificationItem(
          id: 'A-0004',
          type: AlertType.earthquake,
          severity: Severity.medium,
          title: 'Sismo detectado',
          message: 'Vibración anómala en zona A.',
          timestamp: now.subtract(const Duration(minutes: 20)),
          location: 'Zona A',
        ),
        NotificationItem(
          id: 'A-0005',
          type: AlertType.bus,
          severity: Severity.low,
          title: 'Bus detenido',
          message: 'Retraso inusual en la ruta TM.',
          timestamp: now.subtract(const Duration(minutes: 35)),
          location: 'TM-Parada 1',
        ),
      ]);
    setState(() => _loading = false);
  }

  Future<void> _refresh() async {
    // Simula llegada de una nueva alerta
    await Future.delayed(const Duration(milliseconds: 400));
    final now = DateTime.now();
    setState(() {
      _all.insert(
        0,
        NotificationItem(
          id: 'A-${now.microsecondsSinceEpoch}',
          type: AlertType.fire,
          severity: Severity.high,
          title: 'Incendio',
          message: 'Alarma por posible incendio en SH-2.',
          timestamp: now,
          location: 'SH-2',
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = _filters.isEmpty
        ? _all
        : _all.where((n) => _filters.contains(n.type)).toList();

    return MainLayout(
      title: 'Notificaciones',
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildFilters(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (list.isEmpty
                      ? _emptyState()
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _AlertCard(alert: list[i]),
                        )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No hay alertas recientes',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ),
      );

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
          chip(AlertType.redLight, 'Semáforo', Icons.traffic),
          chip(AlertType.panic, 'Pánico', Icons.campaign),
          chip(AlertType.earthquake, 'Sismo', Icons.vibration),
          chip(AlertType.fire, 'Incendio', Icons.local_fire_department),
          chip(AlertType.gas, 'Gas/Humo', Icons.co2),
          chip(AlertType.bus, 'Bus', Icons.bus_alert),
        ],
      ),
    );
  }
}

/// ---- Tarjeta de alerta ----
class _AlertCard extends StatelessWidget {
  final NotificationItem alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final icon = _iconFor(alert.type);
    final color = _colorFor(alert.severity);

    return Card(
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                alert.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _timeAgo(alert.timestamp),
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(alert.message),
            if (alert.location != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.place, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    alert.location!,
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
    );
  }

  static IconData _iconFor(AlertType t) {
    switch (t) {
      case AlertType.redLight: return Icons.traffic;
      case AlertType.panic: return Icons.campaign;
      case AlertType.earthquake: return Icons.vibration;
      case AlertType.fire: return Icons.local_fire_department;
      case AlertType.gas: return Icons.co2;
      case AlertType.bus: return Icons.bus_alert;
      default: return Icons.notification_important;
    }
  }

  static Color _colorFor(Severity s) {
    switch (s) {
      case Severity.low: return const Color(0xFF16A34A);    // verde
      case Severity.medium: return const Color(0xFFF59E0B); // ámbar
      case Severity.high: return const Color(0xFFDC2626);   // rojo
    }
  }

  static String _timeAgo(DateTime ts) {
    final d = DateTime.now().difference(ts);
    if (d.inSeconds < 60) return 'ahora';
    if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
    if (d.inHours < 24) return 'hace ${d.inHours} h';
    return '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';
    // sin paquetes externos
  }
}

class _SeverityPill extends StatelessWidget {
  final Severity severity;
  const _SeverityPill({required this.severity});

  @override
  Widget build(BuildContext context) {
    final text = {
      Severity.low: 'Baja',
      Severity.medium: 'Media',
      Severity.high: 'Alta',
    }[severity]!;
    final col = _AlertCard._colorFor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: col.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: col.withOpacity(0.5)),
      ),
      child: Text(text, style: TextStyle(color: col, fontWeight: FontWeight.w600)),
    );
  }
}
