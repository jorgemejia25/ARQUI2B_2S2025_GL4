import 'package:flutter/material.dart';
import '../layouts/main_layout.dart';

/// Pantalla de información que muestra detalles sobre la aplicación.
///
/// Esta pantalla proporciona información sobre la aplicación, incluyendo
/// versión, desarrolladores, términos de uso y política de privacidad.
class InfoScreen extends StatelessWidget {
  /// Constructor de la pantalla de información.
  ///
  /// [key] - Clave opcional para el widget.
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Información',
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info, size: 80, color: Color(0xFF1E3A8A)),
            SizedBox(height: 24),
            Text(
              'Información',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Información sobre\nla aplicación',
              style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
