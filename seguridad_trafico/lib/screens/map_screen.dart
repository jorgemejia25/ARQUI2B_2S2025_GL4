import 'package:flutter/material.dart';
import '../layouts/main_layout.dart';

/// Pantalla del mapa interactivo que simula las paradas en tiempo real.
///
/// Esta pantalla proporciona una vista interactiva del mapa donde los usuarios
/// pueden ver la ubicación de las paradas y el estado del tráfico en tiempo real.
class MapScreen extends StatelessWidget {
  /// Constructor de la pantalla del mapa.
  ///
  /// [key] - Clave opcional para el widget.
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Mapa Interactivo',
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 80, color: Color(0xFF1E3A8A)),
            SizedBox(height: 24),
            Text(
              'Mapa Interactivo',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Simulación de paradas\nen tiempo real',
              style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
