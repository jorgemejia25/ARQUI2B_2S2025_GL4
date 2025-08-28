import 'package:flutter/material.dart';
import '../layouts/main_layout.dart';

/// Pantalla del dashboard que muestra el panel de control principal.
///
/// Esta pantalla es el punto de entrada principal para la gestión del tráfico
/// y proporciona acceso a las funcionalidades principales del sistema.
class DashboardScreen extends StatelessWidget {
  /// Constructor de la pantalla del dashboard.
  ///
  /// [key] - Clave opcional para el widget.
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Dashboard',
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard, size: 80, color: Color(0xFF1E3A8A)),
            SizedBox(height: 24),
            Text(
              'Panel de Control',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Aquí podrás gestionar el tráfico\ny monitorear el sistema',
              style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
