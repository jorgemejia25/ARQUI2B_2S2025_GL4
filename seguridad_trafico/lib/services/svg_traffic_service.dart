import 'package:flutter/services.dart';
import '../models/traffic_light.dart';
import '../models/bus_stop.dart';

class SvgTrafficService {
  static String? _svgContent;
  static String? _originalSvgContent;
  static final Map<String, TrafficLight> _trafficLights = {};
  static final Map<String, BusStop> _busStops = {};

  // Colores originales de cada parada
  static final Map<String, String> _originalBusStopColors = {
    'P1': '#51A248',
    'P2_2': '#51A248',
    'P3': '#4869A2',
    'P4': '#4869A2',
  };

  // Inicializar los semáforos con sus IDs del SVG
  static void initializeTrafficLights() {
    for (int i = 1; i <= 10; i++) {
      _trafficLights['S$i'] = TrafficLight(
        id: 'S$i',
        state: TrafficLightState.off,
        svgId: 'S$i',
      );
    }
  }

  // Inicializar las paradas de autobús con sus IDs del SVG
  static void initializeBusStops() {
    _busStops['P1'] = BusStop(
      id: 'P1',
      state: BusStopState.inactive,
      svgId: 'P1',
      displayName: 'Parada 1',
      location: 'Centro Norte',
    );

    _busStops['P2'] = BusStop(
      id: 'P2',
      state: BusStopState.inactive,
      svgId: 'P2_2',
      displayName: 'Parada 2',
      location: 'Centro Sur',
    );

    _busStops['P3'] = BusStop(
      id: 'P3',
      state: BusStopState.inactive,
      svgId: 'P3',
      displayName: 'Parada 3',
      location: 'Este',
    );

    _busStops['P4'] = BusStop(
      id: 'P4',
      state: BusStopState.inactive,
      svgId: 'P4',
      displayName: 'Parada 4',
      location: 'Oeste',
    );
  }

  // Cargar el contenido del SVG
  static Future<String> loadSvgContent() async {
    if (_svgContent != null) return _svgContent!;

    _svgContent = await rootBundle.loadString('assets/Map.svg');
    _originalSvgContent = _svgContent;
    return _svgContent!;
  }

  // Obtener el SVG con los colores actualizados de semáforos y paradas
  static String getSvgWithUpdatedColors() {
    if (_originalSvgContent == null) return '';

    String updatedSvg =
        _originalSvgContent!; // Empezar siempre desde el original

    // Actualizar el color de cada semáforo
    _trafficLights.forEach((id, trafficLight) {
      final newColor = trafficLight.hexColor;

      // Buscar y reemplazar solo el atributo fill del semáforo específico
      final pattern = RegExp('(id="$id"[^>]*fill=")[^"]*(")', multiLine: true);

      updatedSvg = updatedSvg.replaceAllMapped(pattern, (match) {
        return '${match.group(1)}$newColor${match.group(2)}';
      });
    });

    _busStops.forEach((id, busStop) {
      final newColor = busStop.hexColor;
      final svgId = busStop.svgId;
      final originalColor = _originalBusStopColors[svgId];

      if (originalColor != null) {
        final svgIdIndex = updatedSvg.indexOf('id="$svgId"');
        if (svgIdIndex != -1) {
          final afterIdSvg = updatedSvg.substring(svgIdIndex);
          final colorIndex = afterIdSvg.indexOf('fill="$originalColor"');

          if (colorIndex != -1) {
            final globalColorIndex = svgIdIndex + colorIndex;
            final before = updatedSvg.substring(0, globalColorIndex);
            final after = updatedSvg.substring(
              globalColorIndex + 'fill="$originalColor"'.length,
            );

            updatedSvg = '${before}fill="$newColor"$after';
          }
        }
      }
    });

    return updatedSvg;
  }

  static void changeTrafficLightState(String id, TrafficLightState newState) {
    if (_trafficLights.containsKey(id)) {
      _trafficLights[id]!.changeState(newState);
    }
  }

  static void changeBusStopState(String id, BusStopState newState) {
    if (_busStops.containsKey(id)) {
      _busStops[id]!.changeState(newState);
    }
  }

  static void changeBusStopStateByTransport(String id, String tipoTransporte) {
    if (!_busStops.containsKey(id)) return;

    BusStopState newState;

    if (tipoTransporte.toLowerCase() == 'transmetro') {
      newState = BusStopState.active; // Verde para Transmetro
    } else if (tipoTransporte.toLowerCase() == 'transurbano') {
      newState = BusStopState.busy;
    } else {
      newState = BusStopState.waiting;
    }

    _busStops[id]!.changeState(newState);
  }

  static void resetBusStopState(String id) {
    if (_busStops.containsKey(id)) {
      _busStops[id]!.changeState(BusStopState.inactive);
    }
  }

  static TrafficLightState? getTrafficLightState(String id) {
    return _trafficLights[id]?.state;
  }

  static BusStopState? getBusStopState(String id) {
    return _busStops[id]?.state;
  }

  static Map<String, TrafficLight> getAllTrafficLights() {
    return Map.from(_trafficLights);
  }

  static Map<String, BusStop> getAllBusStops() {
    return Map.from(_busStops);
  }

  static Map<String, TrafficLightState> getAllTrafficLightStates() {
    final Map<String, TrafficLightState> states = {};
    _trafficLights.forEach((id, trafficLight) {
      states[id] = trafficLight.state;
    });
    return states;
  }

  static Map<String, BusStopState> getAllBusStopStates() {
    final Map<String, BusStopState> states = {};
    _busStops.forEach((id, busStop) {
      states[id] = busStop.state;
    });
    return states;
  }

  static void changeAllTrafficLightsState(TrafficLightState newState) {
    _trafficLights.forEach((id, trafficLight) {
      trafficLight.changeState(newState);
    });
  }

  static void changeAllBusStopsState(BusStopState newState) {
    _busStops.forEach((id, busStop) {
      busStop.changeState(newState);
    });
  }

  static void simulateTrafficSequence() {
    _trafficLights.forEach((id, trafficLight) {
      trafficLight.toggleState();
    });
  }

  static void simulateBusStopSequence() {
    _busStops.forEach((id, busStop) {
      busStop.toggleActive();
    });
  }

  static void resetAllTrafficLights() {
    _trafficLights.forEach((id, trafficLight) {
      trafficLight.changeState(TrafficLightState.off);
    });
  }

  static void resetAllBusStops() {
    _busStops.forEach((id, busStop) {
      busStop.reset();
    });
  }
}
