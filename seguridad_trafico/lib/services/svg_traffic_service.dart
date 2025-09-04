import 'package:flutter/services.dart';
import '../models/traffic_light.dart';
import '../models/bus_stop.dart';

class SvgTrafficService {
  static String? _svgContent;
  static String? _originalSvgContent; // Mantener una copia del SVG original
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
    _originalSvgContent = _svgContent; // Guardar copia original
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

    // Actualizar el color de cada parada de autobús de forma más directa
    _busStops.forEach((id, busStop) {
      final newColor = busStop.hexColor;
      final svgId = busStop.svgId;
      final originalColor = _originalBusStopColors[svgId];

      if (originalColor != null) {
        print(
          'Processing $svgId: state=${busStop.state}, original=$originalColor, new=$newColor',
        );

        // Método directo: buscar la primera ocurrencia del color original después del ID de la parada
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

            updatedSvg = before + 'fill="$newColor"' + after;
            print('✅ Updated $svgId: $originalColor -> $newColor');
          } else {
            print('❌ Color $originalColor not found after $svgId');
          }
        } else {
          print('❌ SVG ID $svgId not found');
        }
      }
    });

    return updatedSvg;
  }

  // Cambiar el estado de un semáforo específico
  static void changeTrafficLightState(String id, TrafficLightState newState) {
    if (_trafficLights.containsKey(id)) {
      _trafficLights[id]!.changeState(newState);
    }
  }

  // Cambiar el estado de una parada específica
  static void changeBusStopState(String id, BusStopState newState) {
    if (_busStops.containsKey(id)) {
      _busStops[id]!.changeState(newState);
    }
  }

  // Obtener el estado de un semáforo
  static TrafficLightState? getTrafficLightState(String id) {
    return _trafficLights[id]?.state;
  }

  // Obtener el estado de una parada
  static BusStopState? getBusStopState(String id) {
    return _busStops[id]?.state;
  }

  // Obtener todos los semáforos
  static Map<String, TrafficLight> getAllTrafficLights() {
    return Map.from(_trafficLights);
  }

  // Obtener todas las paradas
  static Map<String, BusStop> getAllBusStops() {
    return Map.from(_busStops);
  }

  // Obtener el estado de todos los semáforos como mapa
  static Map<String, TrafficLightState> getAllTrafficLightStates() {
    final Map<String, TrafficLightState> states = {};
    _trafficLights.forEach((id, trafficLight) {
      states[id] = trafficLight.state;
    });
    return states;
  }

  // Obtener el estado de todas las paradas como mapa
  static Map<String, BusStopState> getAllBusStopStates() {
    final Map<String, BusStopState> states = {};
    _busStops.forEach((id, busStop) {
      states[id] = busStop.state;
    });
    return states;
  }

  // Cambiar el estado de todos los semáforos
  static void changeAllTrafficLightsState(TrafficLightState newState) {
    _trafficLights.forEach((id, trafficLight) {
      trafficLight.changeState(newState);
    });
  }

  // Cambiar el estado de todas las paradas
  static void changeAllBusStopsState(BusStopState newState) {
    _busStops.forEach((id, busStop) {
      busStop.changeState(newState);
    });
  }

  // Simular secuencia de semáforos
  static void simulateTrafficSequence() {
    _trafficLights.forEach((id, trafficLight) {
      trafficLight.toggleState();
    });
  }

  // Simular secuencia de paradas
  static void simulateBusStopSequence() {
    _busStops.forEach((id, busStop) {
      busStop.toggleActive();
    });
  }

  // Resetear todos los semáforos
  static void resetAllTrafficLights() {
    _trafficLights.forEach((id, trafficLight) {
      trafficLight.changeState(TrafficLightState.off);
    });
  }

  // Resetear todas las paradas
  static void resetAllBusStops() {
    _busStops.forEach((id, busStop) {
      busStop.reset();
    });
  }

  // Función de debug para verificar las paradas
  static void debugBusStops() {
    print('=== DEBUG BUS STOPS ===');
    print('Total bus stops: ${_busStops.length}');
    _busStops.forEach((id, busStop) {
      print(
        'BusStop $id: svgId=${busStop.svgId}, state=${busStop.state}, color=${busStop.hexColor}',
      );
      final originalColor = _originalBusStopColors[busStop.svgId];
      print('  Original color: $originalColor');
    });

    if (_originalSvgContent != null) {
      print('Original SVG analysis:');
      _originalBusStopColors.forEach((svgId, color) {
        final hasColor = _originalSvgContent!.contains('fill="$color"');
        final hasId = _originalSvgContent!.contains('id="$svgId"');
        print('  $svgId: id found=$hasId, color $color found=$hasColor');

        if (hasId) {
          final idIndex = _originalSvgContent!.indexOf('id="$svgId"');
          final afterId = _originalSvgContent!.substring(
            idIndex,
            idIndex + 200,
          );
          print('    Context: ${afterId.replaceAll('\n', ' ')}');
        }
      });
    }
  }

  // Función de prueba directa para P1
  static String testP1ColorChange() {
    if (_originalSvgContent == null) return 'No SVG loaded';

    print('=== TEST P1 COLOR CHANGE ===');
    final originalColor = '#51A248';
    final newColor = '#FF0000';

    String testSvg = _originalSvgContent!;
    print('Original SVG contains P1: ${testSvg.contains('id="P1"')}');
    print(
      'Original SVG contains green: ${testSvg.contains('fill="$originalColor"')}',
    );

    // Buscar P1 y cambiar su color
    final p1Index = testSvg.indexOf('id="P1"');
    if (p1Index != -1) {
      final afterP1 = testSvg.substring(p1Index);
      final colorIndex = afterP1.indexOf('fill="$originalColor"');

      if (colorIndex != -1) {
        final globalColorIndex = p1Index + colorIndex;
        final before = testSvg.substring(0, globalColorIndex);
        final after = testSvg.substring(
          globalColorIndex + 'fill="$originalColor"'.length,
        );

        testSvg = before + 'fill="$newColor"' + after;
        print('✅ Test successful: Changed P1 color');
        print(
          'Updated SVG contains red: ${testSvg.contains('fill="$newColor"')}',
        );
        return testSvg;
      } else {
        print('❌ Color not found after P1');
      }
    } else {
      print('❌ P1 not found');
    }

    return _originalSvgContent!;
  }
}
