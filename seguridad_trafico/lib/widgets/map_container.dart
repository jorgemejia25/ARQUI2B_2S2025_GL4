import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import '../services/svg_traffic_service.dart';

class MapContainer extends StatefulWidget {
  const MapContainer({super.key});

  @override
  State<MapContainer> createState() => _MapContainerState();
}

class _MapContainerState extends State<MapContainer> {
  String _svgContent = '';
  bool _isLoading = true;
  Timer? _simulationTimer;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    // Inicializar el servicio de semáforos y paradas
    SvgTrafficService.initializeTrafficLights();
    SvgTrafficService.initializeBusStops();

    // Cargar el contenido del SVG
    final svgContent = await SvgTrafficService.loadSvgContent();

    setState(() {
      _svgContent = svgContent;
      _isLoading = false;
    });

    // Debug: verificar las paradas
    SvgTrafficService.debugBusStops();

    // Iniciar simulación automática (opcional) - deshabilitado para pruebas
    // _startSimulation();
  }

  // void _startSimulation() {
  //   _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
  //     if (mounted) {
  //       setState(() {
  //         SvgTrafficService.simulateTrafficSequence();
  //         _svgContent = SvgTrafficService.getSvgWithUpdatedColors();
  //       });
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[100],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Cargando mapa...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[100],
      child: Stack(
        children: [
          // SVG del mapa
          SvgPicture.string(
            _svgContent,
            fit: BoxFit.cover,
            allowDrawingOutsideViewBox: true,
          ),
        ],
      ),
    );
  }
}
