import 'package:flutter/material.dart';
import '../widgets/map_container.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mapa de Tráfico',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue[800],
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.traffic, color: Colors.white),
            onPressed: () {
              // TODO: Implementar control de semáforos desde aquí
            },
            tooltip: 'Control de Semáforos',
          ),
          IconButton(
            icon: const Icon(Icons.directions_bus, color: Colors.white),
            onPressed: () {
              // TODO: Implementar control de paradas desde aquí
            },
            tooltip: 'Control de Paradas',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              // TODO: Implementar información del mapa
            },
            tooltip: 'Información del mapa',
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // TODO: Implementar configuración
            },
            tooltip: 'Configuración',
          ),
        ],
      ),
      body: const MapContainer(),
      bottomNavigationBar: BottomAppBar(
        color: Colors.blue[800],
        padding: EdgeInsets.zero,
        child: SafeArea(
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                _buildActionButton(
                  icon: Icons.my_location,
                  label: 'Mi Ubicación',
                  onPressed: () {
                    // TODO: Implementar ubicación actual
                  },
                ),
                _buildActionButton(
                  icon: Icons.search,
                  label: 'Buscar',
                  onPressed: () {
                    // TODO: Implementar búsqueda
                  },
                ),
                _buildActionButton(
                  icon: Icons.layers,
                  label: 'Capas',
                  onPressed: () {
                    // TODO: Implementar capas del mapa
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
