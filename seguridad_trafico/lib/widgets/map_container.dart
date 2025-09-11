import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import '../services/svg_traffic_service.dart';
import '../services/websocket_service.dart';
import '../services/bus_stop_service.dart';
import '../services/bus_stop_websocket_service.dart';
import '../models/websocket_message.dart';
import '../models/traffic_light.dart';
import 'bus_stop_eta_widget.dart';
import 'eta_info_modal.dart';

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
  final BusStopWebSocketService _busStopWebSocketService =
      BusStopWebSocketService.instance;
  final BusStopService _busStopService = BusStopService.instance;
  StreamSubscription<Map<String, BusStopEtaInfo>>? _busStopsSubscription;

  // Controlador para el zoom del mapa
  final TransformationController _transformationController =
      TransformationController();

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
    _transformationController.dispose();
    _webSocketService.disconnect();
    _busStopWebSocketService.disconnect();
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
    // SvgTrafficService.debugBusStops();

    // Iniciar simulación automática (opcional) - deshabilitado para pruebas
    // _startSimulation();
  }

  void _setupWebSocket() {
    // Configurar callbacks del WebSocket de tráfico
    _webSocketService.onTrafficUpdate = _handleTrafficUpdate;
    _webSocketService.onError = _handleWebSocketError;
    _webSocketService.onConnected = _handleWebSocketConnected;
    _webSocketService.onDisconnected = _handleWebSocketDisconnected;

    // Configurar callbacks del WebSocket de paradas
    _busStopWebSocketService.onEtaUpdate = (msg) {
      // Log para depurar recepción de ETA
      // ignore: avoid_print
      print(
        'ETA recibido: stop=${msg.data.stopId}, tipo=${msg.data.tipoTransporte}, t=${msg.data.tiempoSegundos}s, origen=${msg.data.origen}',
      );
      _handleEtaUpdate(msg);
    };
    _busStopWebSocketService.onError = _handleBusStopWebSocketError;
    _busStopWebSocketService.onConnected = _handleBusStopWebSocketConnected;
    _busStopWebSocketService.onDisconnected =
        _handleBusStopWebSocketDisconnected;

    // Configurar suscripción para actualizaciones de paradas
    _busStopsSubscription = _busStopService.busStopsStream.listen((busStops) {
      setState(() {
        // Forzar actualización de la UI cuando cambien las paradas
      });
    });

    // Iniciar limpieza automática de ETA
    _busStopService.startEtaCleanup();

    // Conectar a ambos WebSockets
    _webSocketService.connect();
    _busStopWebSocketService.connect();
  }

  void _handleTrafficUpdate(WebSocketMessage message) {
    // Mapear el ID del semáforo del WebSocket al ID del SVG
    final svgId = _mapSignalIdToSvgId(message.data.signalId);

    if (svgId == null) {
      return;
    }

    // Mapear el color del WebSocket al estado del semáforo
    final trafficState = _mapColorToTrafficState(message.data.signalColor);

    if (trafficState == null) {
      return;
    }

    // Actualizar el semáforo en el servicio SVG
    SvgTrafficService.changeTrafficLightState(svgId, trafficState);

    final newSvgContent = SvgTrafficService.getSvgWithUpdatedColors();

    setState(() {
      _svgContent = newSvgContent;
    });
  }

  void _handleWebSocketError(String error) {
    // Aquí podrías mostrar un snackbar o notificación de error
  }

  void _handleWebSocketConnected() {
    setState(() {
      // Actualizar la UI para mostrar el estado conectado
    });
  }

  void _handleWebSocketDisconnected() {
    setState(() {
      // Actualizar la UI para mostrar el estado desconectado
    });
  }

  void _handleBusStopWebSocketError(String error) {
    // Manejar errores del WebSocket de paradas
  }

  void _handleBusStopWebSocketConnected() {
    setState(() {
      // Actualizar la UI para mostrar el estado conectado
    });
  }

  void _handleBusStopWebSocketDisconnected() {
    setState(() {
      // Actualizar la UI para mostrar el estado desconectado
    });
  }

  void _handleEtaUpdate(EtaUpdateMessage message) {
    // Actualizar el servicio de paradas de bus con cambio de color
    _busStopService.updateEtaWithColorChange(message);

    // Actualizar el SVG con los nuevos colores de paradas
    setState(() {
      _svgContent = SvgTrafficService.getSvgWithUpdatedColors();
    });
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

  // Métodos para controlar el zoom del mapa
  void _zoomIn() {
    const double zoomFactor = 1.2; // Factor de zoom (20% más)
    final Matrix4 currentMatrix = _transformationController.value;

    // Obtener la escala actual
    final double currentScale = currentMatrix.getMaxScaleOnAxis();

    // Calcular nueva escala (máximo 5.0)
    final double newScale = (currentScale * zoomFactor).clamp(0.5, 5.0);

    if (newScale != currentScale) {
      // Calcular la nueva matriz de transformación
      final double scaleChange = newScale / currentScale;
      final Matrix4 newMatrix = currentMatrix.clone()..scale(scaleChange);

      _transformationController.value = newMatrix;
    }
  }

  void _zoomOut() {
    const double zoomFactor = 0.8; // Factor de zoom (20% menos)
    final Matrix4 currentMatrix = _transformationController.value;

    // Obtener la escala actual
    final double currentScale = currentMatrix.getMaxScaleOnAxis();

    // Calcular nueva escala (mínimo 0.5)
    final double newScale = (currentScale * zoomFactor).clamp(0.5, 5.0);

    if (newScale != currentScale) {
      // Calcular la nueva matriz de transformación
      final double scaleChange = newScale / currentScale;
      final Matrix4 newMatrix = currentMatrix.clone()..scale(scaleChange);

      _transformationController.value = newMatrix;
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
          // SVG del mapa con InteractiveViewer
          InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 5.0,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(20),
            child: Stack(
              children: [
                // SVG del mapa
                SvgPicture.string(
                  _svgContent,
                  fit: BoxFit.contain,
                  allowDrawingOutsideViewBox: true,
                ),

                // Overlay de paradas de bus con ETA
                const BusStopsEtaOverlay(),
              ],
            ),
          ),

          // Botones de control de zoom
          Positioned(
            top: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón Zoom In (+)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: FloatingActionButton(
                    heroTag: 'fabZoomIn',
                    onPressed: _zoomIn,
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    mini: true,
                    tooltip: 'Zoom In',
                    child: const Icon(Icons.add, size: 20),
                  ),
                ),

                // Botón Zoom Out (-)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: FloatingActionButton(
                    heroTag: 'fabZoomOut',
                    onPressed: _zoomOut,
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    mini: true,
                    tooltip: 'Zoom Out',
                    child: const Icon(Icons.remove, size: 20),
                  ),
                ),

                // Botón Reset Zoom (opcional)
                FloatingActionButton(
                  heroTag: 'fabResetZoom',
                  onPressed: () {
                    _transformationController.value = Matrix4.identity();
                  },
                  backgroundColor: Colors.grey[700],
                  foregroundColor: Colors.white,
                  mini: true,
                  tooltip: 'Reset Zoom',
                  child: const Icon(Icons.center_focus_strong, size: 16),
                ),
              ],
            ),
          ),

          // Botón flotante para mostrar información de ETA
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton.extended(
              heroTag: 'fabEtaInfo',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const EtaInfoModal(),
                );
              },
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              icon: const Icon(Icons.info_outline),
              label: const Text('Paradas'),
              tooltip: 'Ver información de paradas y ETA',
            ),
          ),
        ],
      ),
    );
  }
}
