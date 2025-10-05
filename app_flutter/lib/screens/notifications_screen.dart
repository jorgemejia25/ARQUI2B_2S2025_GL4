import 'package:flutter/material.dart';
import '../layouts/modern_layout.dart';
import '../widgets/alert_feed_fixed.dart';
import '../services/websocket_alerts.dart';
import '../config/app_theme.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: AppTheme.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: AppTheme.backgroundCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        margin: const EdgeInsets.all(AppTheme.spaceMedium),
      ),
    );
  }

  Future<void> _pullToRefresh() async {
    // Puedes pedir al backend un “page” de alertas recientes
    _ws.requestRecentAlerts(limit: 20);
    // Pequeño delay para que se note el indicador
    await Future.delayed(const Duration(milliseconds: 350));
  }

  @override
  Widget build(BuildContext context) {
    return ModernLayout(
      title: 'Notificaciones',
      currentRoute: '/notifications',
      child: Stack(
        children: [
          // Contenido principal con RefreshIndicator
          RefreshIndicator(
            onRefresh: _pullToRefresh,
            color: AppTheme.primaryPurple,
            backgroundColor: AppTheme.backgroundCard,
            child: const AlertsFeedFixed(),
          ),

          // FAB moderno para simular alertas
          Positioned(
            right: AppTheme.spaceMedium,
            bottom: AppTheme.spaceMedium,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.purpleGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryPurple.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                heroTag: 'fabSimAlert',
                onPressed: _ws.simulateAlertMessage,
                backgroundColor: Colors.transparent,
                elevation: 0,
                icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
                label: Text(
                  'Simular Alerta',
                  style: AppTheme.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
