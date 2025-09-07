import 'package:flutter/material.dart';
import '../layouts/main_layout.dart';        // conserva tu layout
import '../widgets/alerts_feed.dart';
import '../services/websocket_alerts.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _ws = WebSocketAlertsService.instance;
  bool _connecting = false;

  @override
  void initState() {
    super.initState();

    // Conecta el WS si aún no está conectado (compartido con otras vistas).
    if (!_ws.isConnected && !_connecting) {
      _connecting = true;
      _ws
          .connect()
          .catchError((e) => _showSnack('Error de conexión: $e'))
          .whenComplete(() => _connecting = false);
    }

    // Opcional: manejar errores y toasts locales
    _ws.onError = (msg) => _showSnack(msg);
  }

  @override
  void dispose() {
    // Nota: si la app usa el mismo WS en otras vistas, quizá NO quieras desconectar aquí.
    // _ws.disconnect();
    super.dispose();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pullToRefresh() async {
    // Puedes pedir al backend un “page” de alertas recientes
    _ws.requestRecentAlerts(limit: 20);
    // Pequeño delay para que se note el indicador
    await Future.delayed(const Duration(milliseconds: 350));
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Notificaciones',
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _pullToRefresh,
            child: const AlertsFeed(),
          ),

          // FAB para forzar pruebas locales de UI (opcional en debug)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              heroTag: 'fabSimAlert',
              onPressed: _ws.simulateAlertMessage,
              icon: const Icon(Icons.bolt),
              label: const Text('Simular alerta'),
            ),
          ),
        ],
      ),
    );
  }
}
