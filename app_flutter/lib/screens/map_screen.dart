import 'package:flutter/material.dart';
import '../widgets/map_container.dart';
import '../layouts/modern_layout.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  Widget build(BuildContext context) {
    return ModernLayout(
      title: 'Mapa',
      currentRoute: '/map',
      child: const MapContainer(),
    );
  }
}
