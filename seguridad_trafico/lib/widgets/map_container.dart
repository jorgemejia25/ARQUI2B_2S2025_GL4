import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import '../services/svg_traffic_service.dart';
import '../services/websocket_service.dart';
import '../services/bus_stop_service.dart';
import '../models/websocket_message.dart';
import '../models/traffic_light.dart';
import 'bus_stop_eta_widget.dart';

class MapContainer extends StatefulWidget {
  const MapContainer({super.key});

  @override
  State<MapContainer> createState() => _MapContainerState();
}

class _MapContainerState extends State<MapContainer> {
  String _svgContent = '';
  bool _isLoading = true;
  Timer? _simulationTimer;
  final WebSocketService _webSocketService = WebSocketService.instance;
  final BusStopService _busStopService = BusStopService.instance;
  StreamSubscription<Map<String, BusStopEtaInfo>>? _busStopsSubscription;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _setupWebSocket();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _busStopsSubscription?.cancel();
    _busStopService.stopEtaCleanup();
    _webSocketService.disconnect();
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

  void _setupWebSocket() {
    // Configurar callbacks del WebSocket
    _webSocketService.onTrafficUpdate = _handleTrafficUpdate;
    _webSocketService.onEtaUpdate = _handleEtaUpdate;
    _webSocketService.onError = _handleWebSocketError;
    _webSocketService.onConnected = _handleWebSocketConnected;
    _webSocketService.onDisconnected = _handleWebSocketDisconnected;

    // Configurar suscripción para actualizaciones de paradas
    _busStopsSubscription = _busStopService.busStopsStream.listen((busStops) {
      print('🚌 Actualización de paradas recibida');
      setState(() {
        // Forzar actualización de la UI cuando cambien las paradas
      });
    });

    // Iniciar limpieza automática de ETA
    _busStopService.startEtaCleanup();

    // Conectar al WebSocket
    _webSocketService.connect();
  }

  void _handleTrafficUpdate(WebSocketMessage message) {
    print(
      '🚦 Actualización de tráfico recibida: ${message.data.signalId} -> ${message.data.signalColor}',
    );

    // Mapear el ID del semáforo del WebSocket al ID del SVG
    final svgId = _mapSignalIdToSvgId(message.data.signalId);
    print('🔍 ID mapeado: ${message.data.signalId} -> $svgId');

    if (svgId == null) {
      print('⚠️ ID de semáforo no reconocido: ${message.data.signalId}');
      return;
    }

    // Mapear el color del WebSocket al estado del semáforo
    final trafficState = _mapColorToTrafficState(message.data.signalColor);
    print('🎨 Color mapeado: ${message.data.signalColor} -> $trafficState');

    if (trafficState == null) {
      print('⚠️ Color de semáforo no reconocido: ${message.data.signalColor}');
      return;
    }

    print('🔄 Actualizando semáforo $svgId a estado $trafficState');

    // Actualizar el semáforo en el servicio SVG
    print('📝 Cambiando estado del semáforo...');
    SvgTrafficService.changeTrafficLightState(svgId, trafficState);

    print('🖼️ Generando nuevo contenido SVG...');
    final newSvgContent = SvgTrafficService.getSvgWithUpdatedColors();

    print('🔄 Actualizando UI con nuevo SVG...');
    setState(() {
      _svgContent = newSvgContent;
    });

    print('✅ Actualización completa para semáforo $svgId');
  }

  void _handleWebSocketError(String error) {
    print('❌ Error en WebSocket: $error');
    // Aquí podrías mostrar un snackbar o notificación de error
  }

  void _handleWebSocketConnected() {
    print('✅ WebSocket conectado exitosamente');
    setState(() {
      // Actualizar la UI para mostrar el estado conectado
    });
  }

  void _handleWebSocketDisconnected() {
    print('🔌 WebSocket desconectado');
    setState(() {
      // Actualizar la UI para mostrar el estado desconectado
    });
  }

  void _handleEtaUpdate(EtaUpdateMessage message) {
    print(
      '🚌 ETA actualizado: ${message.data.stopId} - ${message.data.tipoTransporte} - ${message.data.tiempoFormateado} desde ${message.data.origen}',
    );

    // Actualizar el servicio de paradas de bus
    _busStopService.updateEta(message);

    // No necesitamos setState aquí porque el StreamController ya notifica los cambios
  }

  String? _mapSignalIdToSvgId(String signalId) {
    // El servidor está enviando IDs directos (S1, S2, etc.) en lugar de SEMAFORO_001
    // Verificar si ya es un ID válido del SVG
    if (signalId.startsWith('S') && signalId.length <= 3) {
      // Es un ID directo del SVG (S1, S2, S3, etc.)
      return signalId;
    }

    // Mapeo de IDs del WebSocket a IDs del SVG (para compatibilidad con formato antiguo)
    final Map<String, String> idMapping = {
      'SEMAFORO_001': 'S1',
      'SEMAFORO_002': 'S2',
      'SEMAFORO_003': 'S3',
      'SEMAFORO_004': 'S4',
      'SEMAFORO_005': 'S5',
      'SEMAFORO_006': 'S6',
      'SEMAFORO_007': 'S7',
      'SEMAFORO_008': 'S8',
      'SEMAFORO_009': 'S9',
      'SEMAFORO_010': 'S10',
    };

    return idMapping[signalId];
  }

  TrafficLightState? _mapColorToTrafficState(String color) {
    switch (color.toLowerCase()) {
      case 'red':
        return TrafficLightState.red;
      case 'yellow':
        return TrafficLightState.yellow;
      case 'green':
        return TrafficLightState.green;
      case 'off':
        return TrafficLightState.off;
      default:
        return null;
    }
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

          // Overlay de paradas de bus con ETA
          const BusStopsEtaOverlay(),

          // Indicador de estado del WebSocket
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _webSocketService.isConnected
                    ? Colors.green
                    : Colors.red,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _webSocketService.isConnected ? Icons.wifi : Icons.wifi_off,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _webSocketService.isConnected
                        ? 'Conectado'
                        : 'Desconectado',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
