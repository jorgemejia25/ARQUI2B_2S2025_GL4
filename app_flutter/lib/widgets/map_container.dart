import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import '../services/svg_traffic_service.dart';
import '../services/websocket_service.dart';
import '../services/bus_stop_service.dart';
import '../services/bus_stop_websocket_service.dart';
import '../models/websocket_message.dart';
import '../models/traffic_light.dart';
import '../models/bus_stop.dart';
import 'bus_stop_eta_widget.dart';
import 'eta_info_modal.dart';
import 'moving_urban_bus_widget.dart';
import 'moving_bus_widget.dart'; // re-import after enabling sensorControlled
import '../services/bus_position_service.dart'; // NUEVO
import '../services/bus_progress_service.dart'; // NUEVO progreso entre paradas
// import 'simple_sensor_controlled_metro_bus.dart'; // Reemplazado por MovingBusWidget sensorControlled

// ---------------------------------------------------------------------------
// CONFIGURACIÓN: DURACIÓN DE ANIMACIÓN ENTRE PARADAS (BUS METRO)
// ---------------------------------------------------------------------------
// Esta constante define el TIEMPO de animación (salto) de una parada a la
// siguiente cuando el bus rojo (metro) está en modo `sensorDiscreteStops`.
// Cambia este valor para acelerar o ralentizar el movimiento entre paradas.
// Ejemplos de edición rápida:
//   const Duration(milliseconds: 400)  // 0.4s más rápido
//   const Duration(milliseconds: 750)  // 0.75s más lento
//   const Duration(seconds: 1)         // 1.0s por parada
// NOTA: No necesitas modificar el widget; basta con cambiar aquí.
const Duration kMetroPerStopAnimationDuration = Duration(milliseconds: 2000); // Duración entre paradas (metro)

// Configuración similar para el BUS URBANO (morado) cuando adopte modo discreto.
// Edita este valor para cambiar cuánto dura cada salto entre paradas urbanas.
// Mantener separado permite ajustar independientemente ambas rutas.
const Duration kUrbanPerStopAnimationDuration = Duration(milliseconds: 2000); // Duración entre paradas (urbano)

class MapContainer extends StatefulWidget {
  const MapContainer({super.key});

  @override
  State<MapContainer> createState() => _MapContainerState();
}

class _MapContainerState extends State<MapContainer> {
  String _svgContent = '';
  bool _isLoading = true;
  bool _didInitialFit = false; // control para ajuste inicial una vez
  Timer? _simulationTimer;
  final WebSocketService _webSocketService = WebSocketService.instance;
  final BusStopWebSocketService _busStopWebSocketService =
      BusStopWebSocketService.instance;
  final BusStopService _busStopService = BusStopService.instance;
  StreamSubscription<Map<String, BusStopEtaInfo>>? _busStopsSubscription;

  // NUEVO: servicio de posiciones
  final BusPositionService _busPositionService = BusPositionService();
  StreamSubscription<BusPositionInfo>? _metroPosSub;
  StreamSubscription<BusPositionInfo>? _urbanPosSub;
  String? _metroPosText; // texto crudo de posición
  String? _urbanPosText; // texto crudo de posición

  // Controlador para el zoom del mapa
  final TransformationController _transformationController =
      TransformationController();

  // Dimensiones base del SVG (para calcular auto-fit)
  static const double _svgWidth = 628;
  // _svgHeight eliminado (no se usa tras cambio de layout)

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _setupWebSocket();
    _setupBusPositionPolling(); // NUEVO
    // Inicializar barras de progreso (evitar 'Calculando...')
    final progress = BusProgressService.instance;
    for (final stop in ['PM1','PM2','PU1','PU2']) {
      progress.updateStopProgress(
        stopName: stop,
        progress: 0.0,
        remainingDistanceMeters: 1000.0, // distancia completa inicial (aprox)
        etaSeconds: 0,
        autoResetOnFull: false,
      );
    }
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _busStopsSubscription?.cancel();
    _busStopService.stopEtaCleanup();
    _transformationController.dispose();
    _webSocketService.disconnect();
    _busStopWebSocketService.disconnect();
    // NUEVO: cancelar subs y detener servicio
    _metroPosSub?.cancel();
    _urbanPosSub?.cancel();
    _busPositionService.stop();
    super.dispose();
  }

  void _setupBusPositionPolling() {
    // Iniciar polling
    _busPositionService.start();
    _metroPosSub = _busPositionService.metroStream.listen((info) {
      setState(() {
        _metroPosText = info.positionRaw; // usar tal cual por ahora
      });
    });
    _urbanPosSub = _busPositionService.urbanStream.listen((info) {
      setState(() {
        _urbanPosText = info.positionRaw; // usar tal cual por ahora
      });
    });
  }

  Future<void> _initializeMap() async {
    // Inicializar el servicio de semáforos y paradas
    SvgTrafficService.initializeTrafficLights();
    SvgTrafficService.initializeBusStops();

    // Cargar el contenido del SVG
    final rawSvg = await SvgTrafficService.loadSvgContent();
    setState(() {
      _svgContent = rawSvg;
      _isLoading = false;
    });

    // El ajuste inicial se hará dentro del LayoutBuilder según el ancho disponible

    // Debug: verificar las paradas
    // SvgTrafficService.debugBusStops();

    // Iniciar simulación automática (opcional) - deshabilitado para pruebas
    // _startSimulation();
  }

  void _applyInitialFitWithWidth(double width) {
    if (_didInitialFit || width <= 0) return;
    double scale = (width / _svgWidth) * 0.98; // margen ligero
    scale = scale.clamp(0.5, 5.0);
    _transformationController.value = Matrix4.identity()..scale(scale);
    _didInitialFit = true;
  }

  void _refitToWidth() {
    final width = MediaQuery.of(context).size.width;
    double scale = (width / _svgWidth) * 0.98;
    scale = scale.clamp(0.5, 5.0);
    _transformationController.value = Matrix4.identity()..scale(scale);
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
    // Mapear el ID del semáforo del WebSocket al grupo correspondiente
    final groupId = _mapSignalIdToSvgId(message.data.signalId);

    if (groupId == null) {
      return;
    }

    // Mapear el color del WebSocket al estado del semáforo
    final trafficState = _mapColorToTrafficState(message.data.signalColor);

    if (trafficState == null) {
      return;
    }

    // Actualizar el grupo de semáforos en el servicio SVG
    SvgTrafficService.changeTrafficLightGroupState(groupId, trafficState);

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
      final updated = SvgTrafficService.getSvgWithUpdatedColors();
      _svgContent = updated;
    });
  }

  String? _mapSignalIdToSvgId(String signalId) {
    // Si el servidor ya está enviando IDs de grupo (SD, SI), usarlos directamente
    if (signalId == 'SD' || signalId == 'SI') {
      return signalId;
    }

    // El servidor está enviando IDs directos (S1, S2, etc.) en lugar de SEMAFORO_001
    // Verificar si ya es un ID válido del SVG y mapearlo al grupo correspondiente
    if (signalId.startsWith('S') && signalId.length <= 3) {
      // Mapear semáforo individual a su grupo correspondiente
      return _mapIndividualTrafficLightToGroup(signalId);
    }

    // Mapeo de IDs del WebSocket a grupos (para compatibilidad con formato antiguo)
    final Map<String, String> idMapping = {
      'SEMAFORO_001': 'SD', // S1 -> SD
      'SEMAFORO_002': 'SD', // S2 -> SD
      'SEMAFORO_003': 'SI', // S3 -> SI
      'SEMAFORO_004': 'SD', // S4 -> SD
      'SEMAFORO_005': 'SD', // S5 -> SD
      'SEMAFORO_006': 'SD', // S6 -> SD
      'SEMAFORO_007': 'SI', // S7 -> SI
      'SEMAFORO_008': 'SD', // S8 -> SD
      'SEMAFORO_009': 'SI', // S9 -> SI
      'SEMAFORO_010': 'SD', // S10 -> SD
    };

    return idMapping[signalId];
  }

  String? _mapIndividualTrafficLightToGroup(String trafficLightId) {
    // Grupo SD (Semáforo Dirección): S1, S2, S4, S5, S6, S8, S10
    if (['S1', 'S2', 'S4', 'S5', 'S6', 'S8', 'S10'].contains(trafficLightId)) {
      return 'SD';
    }
    // Grupo SI (Semáforo Intersección): S3, S7, S9
    if (['S3', 'S7', 'S9'].contains(trafficLightId)) {
      return 'SI';
    }
    return null;
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

    // Texto para overlay de posiciones (placeholder '--' si null)
    final metroText = _metroPosText ?? '--';
    final urbanText = _urbanPosText ?? '--';

    return Container(
      color: Colors.grey[100],
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _applyInitialFitWithWidth(constraints.maxWidth);
                return Stack(
                  children: [
                    InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 0.5,
                      maxScale: 5.0,
                      constrained: false,
                      boundaryMargin: const EdgeInsets.all(20),
                      child: Stack(
                        children: [
                          // Mapa base
                          SvgPicture.string(
                            _svgContent,
                            fit: BoxFit.contain,
                            allowDrawingOutsideViewBox: true,
                          ),
                          // Overlay de buses estáticos encima del mapa
                          SvgPicture.asset(
                            'assets/Map_buses_overlay.svg',
                            fit: BoxFit.contain,
                            allowDrawingOutsideViewBox: true,
                          ),
                          // Bus rojo (metro) original ahora controlado por sensor stream (1s por segmento)
                          MovingBusWidget(
                            sensorControlled: true,
                            sensorDiscreteStops: true, // modo saltos entre paradas
                            segmentDuration: kMetroPerStopAnimationDuration, // TIEMPO POR PARADA (editar constante arriba)
                            sensorStream: _busPositionService.metroStream,
                          ),
                          // Bus urbano morado animado
                          MovingUrbanBusWidget(
                            sensorControlled: true,
                            sensorDiscreteStops: true,
                            segmentDuration: kUrbanPerStopAnimationDuration, // duración entre paradas urbano
                            sensorStream: _busPositionService.urbanStream,
                            // Parámetros legacy ignorados en modo discreto pero mantenidos por compatibilidad
                            stopSeconds: 0.0,
                            maxSegmentSeconds: 0.9,
                          ),
                          const BusStopsEtaOverlay(),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Overlay NUEVO de posiciones
                          Container(
                            width: 220,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(color: const Color(0xFFE0E0E0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Posiciones (1s)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.directions_bus, size: 16, color: Colors.redAccent),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Metro: $metroText',
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.directions_bus_filled, size: 16, color: Colors.deepPurple),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Urbano: $urbanText',
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
                          FloatingActionButton(
                            heroTag: 'fabRefit',
                            onPressed: _refitToWidth,
                            backgroundColor: Colors.grey[700],
                            foregroundColor: Colors.white,
                            mini: true,
                            tooltip: 'Ajustar al ancho',
                            child: const Icon(Icons.fit_screen, size: 16),
                          ),
                        ],
                      ),
                    ),
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
                );
              },
            ),
          ),
          _BottomEtaPanel(busStopService: _busStopService),
        ],
      ),
    );
  }
}

class _BottomEtaPanel extends StatelessWidget {
  final BusStopService busStopService;
  const _BottomEtaPanel({required this.busStopService});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
        border: const Border(top: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 110,
            child: _ApproxProgressPanel(),
          ),
          SizedBox(
            height: 30,
            child: StreamBuilder<Map<String, BusStopEtaInfo>>(
              stream: busStopService.busStopsStream,
              builder: (context, snapshot) {
                final stopsMap = snapshot.data ?? {};
                if (stopsMap.isEmpty) {
                  return const SizedBox.shrink();
                }
                final stops = stopsMap.values.toList()
                  ..sort((a, b) => a.busStop.id.compareTo(b.busStop.id));
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: stops.length,
                  itemBuilder: (context, index) => _EtaChip(info: stops[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ApproxProgressPanel extends StatelessWidget {
  final List<String> _orderedStops = const ['PM1', 'PM2', 'PU1', 'PU2'];
  const _ApproxProgressPanel();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StopApproachProgress>>(
      stream: BusProgressService.instance.stream,
      initialData: BusProgressService.instance.currentValues,
      builder: (context, snapshot) {
        final data = snapshot.data ?? BusProgressService.instance.currentValues;
        final map = {for (final p in data) p.stopName: p};
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          itemCount: _orderedStops.length,
          itemBuilder: (context, index) {
            final name = _orderedStops[index];
            final prog = map[name];
            final progress = (prog?.progress ?? 0).clamp(0.0, 1.0);
            final dist = prog?.remainingDistanceMeters ?? 0;
            final eta = prog?.etaSeconds ?? 0;
            final etaStr = eta <= 0 ? '--' : _formatEta(eta);
            return Container(
              width: 150,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEEEEEE)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _ArrivalBadge(progress: progress),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      minHeight: 10,
                      value: progress == 0 ? 0.02 : progress, // pequeño indicador inicial
                      backgroundColor: const Color(0xFFF1F3F5),
                      valueColor: AlwaysStoppedAnimation<Color>(_barColor(name)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Dist: ${dist.toStringAsFixed(0)} m',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  Text(
                    'ETA: $etaStr',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatEta(double s) {
    if (s < 60) {
      return '${s.toStringAsFixed(1)}s';
    }
    final m = (s / 60).floor();
    final rem = (s % 60).round();
    return '${m}m ${rem}s';
  }

  Color _barColor(String stop) {
    switch (stop) {
      case 'PM1':
        return Colors.redAccent;
      case 'PM2':
        return Colors.red;
      case 'PU1':
        return Colors.deepPurple;
      case 'PU2':
        return Colors.purple;
      default:
        return Colors.blueGrey;
    }
  }
}

class _ArrivalBadge extends StatelessWidget {
  final double progress;
  const _ArrivalBadge({required this.progress});
  @override
  Widget build(BuildContext context) {
    final arrived = progress >= 0.999;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: arrived ? Colors.green[600] : Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        arrived ? 'Llegó' : '${(progress * 100).floor()}%',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: arrived ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}

class _EtaChip extends StatelessWidget {
  final BusStopEtaInfo info;
  const _EtaChip({required this.info});

  Color _statusColor(BusStopState state) {
    switch (state) {
      case BusStopState.active:
        return Colors.green;
      case BusStopState.busy:
        return Colors.red;
      case BusStopState.waiting:
        return Colors.orange;
      case BusStopState.inactive:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final latest = info.latestEta;
    final etaSeg = latest?.tiempoSegundos ?? 0;
    final minutos = (etaSeg / 60).floor();
    final segundos = etaSeg % 60;
    final etaStr = etaSeg == 0 ? '--' : '${minutos}m ${segundos}s';
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _statusColor(info.busStop.state),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  info.busStop.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'ETA',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
            Text(
              etaStr,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          if (latest != null)
            Text(
              latest.tipoTransporte,
              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
