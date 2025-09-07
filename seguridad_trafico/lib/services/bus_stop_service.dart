import 'dart:async';
import '../models/websocket_message.dart';
import '../models/bus_stop.dart';
import 'svg_traffic_service.dart';

class BusStopService {
  static BusStopService? _instance;
  static BusStopService get instance => _instance ??= BusStopService._();

  BusStopService._() {
    _initializeBusStops();
  }

  // Mapa de paradas con su información de ETA
  final Map<String, BusStopEtaInfo> _busStopsEta = {};

  // Stream para notificar cambios en las paradas
  final StreamController<Map<String, BusStopEtaInfo>> _busStopsController =
      StreamController<Map<String, BusStopEtaInfo>>.broadcast();

  Stream<Map<String, BusStopEtaInfo>> get busStopsStream =>
      _busStopsController.stream;

  // Inicializar paradas con información básica
  void _initializeBusStops() {
    final busStops = [
      BusStop(
        id: 'P1',
        svgId: 'P1',
        displayName: 'Parada 1',
        location: 'Centro',
      ),
      BusStop(
        id: 'P2_2',
        svgId: 'P2_2',
        displayName: 'Parada 2',
        location: 'Norte',
      ),
      BusStop(id: 'P3', svgId: 'P3', displayName: 'Parada 3', location: 'Sur'),
      BusStop(id: 'P4', svgId: 'P4', displayName: 'Parada 4', location: 'Este'),
    ];

    for (final stop in busStops) {
      _busStopsEta[stop.id] = BusStopEtaInfo(busStop: stop, etaUpdates: []);
    }
  }

  // Actualizar ETA para una parada específica
  void updateEta(EtaUpdateMessage etaMessage) {
    final stopId = etaMessage.data.stopId;

    if (!_busStopsEta.containsKey(stopId)) {
      return;
    }

    // Crear nueva actualización de ETA
    final etaUpdate = EtaUpdate(
      tipoTransporte: etaMessage.data.tipoTransporte,
      tiempoSegundos: etaMessage.data.tiempoSegundos,
      origen: etaMessage.data.origen,
      timestamp: etaMessage.timestamp,
      severity: etaMessage.data.severity,
    );

    // Agregar la actualización a la parada
    _busStopsEta[stopId]!.etaUpdates.add(etaUpdate);

    // Mantener solo las últimas 5 actualizaciones por parada
    if (_busStopsEta[stopId]!.etaUpdates.length > 5) {
      _busStopsEta[stopId]!.etaUpdates.removeAt(0);
    }

    // Notificar cambios
    _busStopsController.add(Map.from(_busStopsEta));
  }

  // Actualizar ETA y cambiar color de parada en el SVG
  void updateEtaWithColorChange(EtaUpdateMessage etaMessage) {
    final stopId = etaMessage.data.stopId;
    final tipoTransporte = etaMessage.data.tipoTransporte;

    // Actualizar ETA
    updateEta(etaMessage);

    // Cambiar color de la parada en el SVG según el tipo de transporte
    _changeBusStopColorByTransport(stopId, tipoTransporte);
  }

  // Cambiar color de parada según tipo de transporte
  void _changeBusStopColorByTransport(String stopId, String tipoTransporte) {
    // Mapear stopId a los IDs usados en el SVG
    String svgId = stopId;
    if (stopId == 'P2_2') {
      svgId = 'P2'; // El SVG usa P2_2 pero nuestro servicio usa P2
    }

    // Cambiar estado en el servicio SVG
    SvgTrafficService.changeBusStopStateByTransport(svgId, tipoTransporte);

    // Cambiar estado en nuestro servicio local
    if (tipoTransporte.toLowerCase() == 'transmetro') {
      _busStopsEta[stopId]!.busStop.changeState(BusStopState.active); // Verde
    } else if (tipoTransporte.toLowerCase() == 'transurbano') {
      _busStopsEta[stopId]!.busStop.changeState(BusStopState.busy); // Azul
    } else {
      _busStopsEta[stopId]!.busStop.changeState(
        BusStopState.waiting,
      ); // Amarillo
    }
  }

  // Resetear color de parada a inactivo
  void resetBusStopColor(String stopId) {
    if (_busStopsEta.containsKey(stopId)) {
      _busStopsEta[stopId]!.busStop.changeState(BusStopState.inactive);
    }
  }

  // Obtener información de ETA para una parada específica
  BusStopEtaInfo? getBusStopEta(String stopId) {
    return _busStopsEta[stopId];
  }

  // Obtener todas las paradas con información de ETA
  Map<String, BusStopEtaInfo> getAllBusStopsEta() {
    return Map.from(_busStopsEta);
  }

  // Limpiar ETA expirados (más de 10 minutos)
  void cleanExpiredEta() {
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    const maxAge = 600.0; // 10 minutos en segundos

    bool hasChanges = false;

    for (final entry in _busStopsEta.entries) {
      final originalLength = entry.value.etaUpdates.length;
      entry.value.etaUpdates.removeWhere(
        (eta) => (now - eta.timestamp) > maxAge,
      );

      if (entry.value.etaUpdates.length != originalLength) {
        hasChanges = true;
      }
    }

    if (hasChanges) {
      _busStopsController.add(Map.from(_busStopsEta));
    }
  }

  // Iniciar limpieza automática de ETA expirados
  Timer? _cleanupTimer;
  void startEtaCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      cleanExpiredEta();
    });
  }

  // Detener limpieza automática
  void stopEtaCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }

  // Limpiar recursos
  void dispose() {
    stopEtaCleanup();
    _busStopsController.close();
  }
}

// Clase auxiliar para mantener información de ETA por parada
class BusStopEtaInfo {
  final BusStop busStop;
  final List<EtaUpdate> etaUpdates;

  BusStopEtaInfo({required this.busStop, required this.etaUpdates});

  // Obtener la actualización más reciente
  EtaUpdate? get latestEta {
    if (etaUpdates.isEmpty) return null;
    return etaUpdates.last;
  }

  // Verificar si hay actualizaciones activas
  bool get hasActiveEta => etaUpdates.isNotEmpty;

  // Obtener todas las actualizaciones ordenadas por tiempo (más reciente primero)
  List<EtaUpdate> get etaUpdatesSorted {
    final sorted = List<EtaUpdate>.from(etaUpdates);
    sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted;
  }
}

// Modelo para actualizaciones de ETA individuales
class EtaUpdate {
  final String tipoTransporte;
  final int tiempoSegundos;
  final String origen;
  final double timestamp;
  final int severity;

  EtaUpdate({
    required this.tipoTransporte,
    required this.tiempoSegundos,
    required this.origen,
    required this.timestamp,
    required this.severity,
  });

  // Formatear tiempo como en el modelo original
  String get tiempoFormateado {
    final minutos = tiempoSegundos ~/ 60;
    final segundos = tiempoSegundos % 60;

    if (minutos > 0) {
      return '${minutos}m ${segundos}s';
    } else {
      return '${segundos}s';
    }
  }

  // Verificar si la actualización ha expirado (más de 10 minutos)
  bool get isExpired {
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    return (now - timestamp) > 600.0; // 10 minutos
  }
}
