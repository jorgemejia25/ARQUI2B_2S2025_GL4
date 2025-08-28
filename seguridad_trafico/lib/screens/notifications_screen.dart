import 'package:flutter/material.dart';
import '../layouts/main_layout.dart';

/// Pantalla de notificaciones que muestra alertas y notificaciones del sistema.
///
/// Esta pantalla permite a los usuarios ver y gestionar las notificaciones
/// relacionadas con el estado del tráfico y eventos importantes del sistema.
class NotificationsScreen extends StatelessWidget {
  /// Constructor de la pantalla de notificaciones.
  ///
  /// [key] - Clave opcional para el widget.
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Notificaciones',
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications, size: 80, color: Color(0xFF1E3A8A)),
            SizedBox(height: 24),
            Text(
              'Alertas y Notificaciones',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Mantente informado sobre\nel estado del tráfico',
              style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
