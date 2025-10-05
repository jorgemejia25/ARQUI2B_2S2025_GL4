import 'package:flutter/services.dart';
import '../models/traffic_light.dart';
import '../models/bus_stop.dart';

class SvgTrafficService {
  static String? _svgContent;
  static String? _originalSvgContent;
  static final Map<String, TrafficLight> _trafficLightGroups = {};
  static final Map<String, BusStop> _busStops = {};

  // Colores originales de cada parada
  static final Map<String, String> _originalBusStopColors = {
    'P1': '#51A248',
    'P2_2': '#51A248',
    'P3': '#4869A2',
    'P4': '#4869A2',
  };

  // Mapeo de grupos de semáforos
  // SD (Semáforo Dirección): S1, S2, S4, S5, S6, S8, S10
  // SI (Semáforo Intersección): S3, S7, S9
  static final Map<String, List<String>> _trafficLightGroupMapping = {
    'SD': ['S1', 'S2', 'S4', 'S5', 'S6', 'S8', 'S10'],
    'SI': ['S3', 'S7', 'S9'],
  };

  // Inicializar los grupos de semáforos
  static void initializeTrafficLights() {
    _trafficLightGroups['SD'] = TrafficLight(
      id: 'SD',
      state: TrafficLightState.off,
      svgId: 'SD',
    );

    _trafficLightGroups['SI'] = TrafficLight(
      id: 'SI',
      state: TrafficLightState.off,
      svgId: 'SI',
    );
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

    // Actualizar el color de cada grupo de semáforos
    _trafficLightGroups.forEach((groupId, trafficLight) {
      final newColor = trafficLight.hexColor;

      // Buscar y reemplazar todos los elementos con la clase del grupo
      final pattern = RegExp(
        '(class="$groupId"[^>]*fill=")[^"]*(")',
        multiLine: true,
      );

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

  static void changeTrafficLightGroupState(
    String groupId,
    TrafficLightState newState,
  ) {
    if (_trafficLightGroups.containsKey(groupId)) {
      _trafficLightGroups[groupId]!.changeState(newState);
    }
  }

  // Método para compatibilidad con el código existente que usa IDs individuales
  static void changeTrafficLightState(String id, TrafficLightState newState) {
    // Determinar a qué grupo pertenece el semáforo individual
    String? groupId = _getGroupForTrafficLight(id);
    if (groupId != null) {
      changeTrafficLightGroupState(groupId, newState);
    }
  }

  // Método auxiliar para obtener el grupo de un semáforo individual
  static String? _getGroupForTrafficLight(String trafficLightId) {
    for (String groupId in _trafficLightGroupMapping.keys) {
      if (_trafficLightGroupMapping[groupId]!.contains(trafficLightId)) {
        return groupId;
      }
    }
    return null;
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
    // Si es un grupo, devolver el estado del grupo
    if (_trafficLightGroups.containsKey(id)) {
      return _trafficLightGroups[id]?.state;
    }

    // Si es un semáforo individual, buscar su grupo
    String? groupId = _getGroupForTrafficLight(id);
    if (groupId != null) {
      return _trafficLightGroups[groupId]?.state;
    }

    return null;
  }

  static TrafficLightState? getTrafficLightGroupState(String groupId) {
    return _trafficLightGroups[groupId]?.state;
  }

  static BusStopState? getBusStopState(String id) {
    return _busStops[id]?.state;
  }

  static Map<String, TrafficLight> getAllTrafficLights() {
    return Map.from(_trafficLightGroups);
  }

  static Map<String, TrafficLight> getAllTrafficLightGroups() {
    return Map.from(_trafficLightGroups);
  }

  static Map<String, BusStop> getAllBusStops() {
    return Map.from(_busStops);
  }

  static Map<String, TrafficLightState> getAllTrafficLightStates() {
    final Map<String, TrafficLightState> states = {};
    _trafficLightGroups.forEach((groupId, trafficLight) {
      states[groupId] = trafficLight.state;
    });
    return states;
  }

  static Map<String, TrafficLightState> getAllTrafficLightGroupStates() {
    final Map<String, TrafficLightState> states = {};
    _trafficLightGroups.forEach((groupId, trafficLight) {
      states[groupId] = trafficLight.state;
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
    _trafficLightGroups.forEach((groupId, trafficLight) {
      trafficLight.changeState(newState);
    });
  }

  static void changeAllTrafficLightGroupsState(TrafficLightState newState) {
    _trafficLightGroups.forEach((groupId, trafficLight) {
      trafficLight.changeState(newState);
    });
  }

  static void changeAllBusStopsState(BusStopState newState) {
    _busStops.forEach((id, busStop) {
      busStop.changeState(newState);
    });
  }

  static void simulateTrafficSequence() {
    _trafficLightGroups.forEach((groupId, trafficLight) {
      trafficLight.toggleState();
    });
  }

  static void simulateBusStopSequence() {
    _busStops.forEach((id, busStop) {
      busStop.toggleActive();
    });
  }

  static void resetAllTrafficLights() {
    _trafficLightGroups.forEach((groupId, trafficLight) {
      trafficLight.changeState(TrafficLightState.off);
    });
  }

  static void resetAllTrafficLightGroups() {
    _trafficLightGroups.forEach((groupId, trafficLight) {
      trafficLight.changeState(TrafficLightState.off);
    });
  }

  static void resetAllBusStops() {
    _busStops.forEach((id, busStop) {
      busStop.reset();
    });
  }
}
