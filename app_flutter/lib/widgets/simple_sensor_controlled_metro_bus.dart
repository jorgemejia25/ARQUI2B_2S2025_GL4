import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/bus_position_service.dart';

/// Widget sencillo:
/// - Tiene una ruta predefinida (lista de puntos) para el bus METRO.
/// - Cada punto se asocia con un nombre de sensor (PM1, S2, S1, PM2, S5).
/// - La animación avanza continuamente de punto a punto en un loop.
/// - Si el nombre del sensor "actual" (el último recibido por stream) coincide
///   con el sensor del punto donde estamos parados, la animación se PAUSA.
/// - Cuando llega un NUEVO sensor distinto, se reanuda y avanza hasta el siguiente punto.
/// - Cada segmento debe durar exactamente 1 segundo sin importar la distancia.
class SimpleSensorControlledMetroBus extends StatefulWidget {
  final Stream<BusPositionInfo> sensorStream; // stream de posiciones (solo nombres)
  final double busWidth; // tamaño del ícono
  final double busHeight;

  const SimpleSensorControlledMetroBus({
    super.key,
    required this.sensorStream,
    this.busWidth = 28,
    this.busHeight = 28,
  });

  @override
  State<SimpleSensorControlledMetroBus> createState() => _SimpleSensorControlledMetroBusState();
}

class _SimpleSensorControlledMetroBusState extends State<SimpleSensorControlledMetroBus>
    with SingleTickerProviderStateMixin {
  // Waypoints (usar las coordenadas absolutas conocidas del circuito)
  // Orden según METRO_SEQUENCE: PM1 -> S2 -> S1 -> PM2 -> S5 -> (loop)
  // NOTA: Ajusta si tus coordenadas reales difieren; estos son placeholders si se perdieron.
  final List<Offset> _points = const [
    Offset(787, 388), // PM1
    Offset(579, 392), // S2
    Offset(460, 392), // S1
    Offset(270, 390), // PM2
    Offset(809, 651), // S5 (coordenada dada, revisar si corresponde al layout)
  ];

  final List<String> _sensorNames = const ["PM1", "S2", "S1", "PM2", "S5"];

  late AnimationController _controller;
  int _currentIndex = 0; // índice del punto actual
  String? _lastSensor; // último sensor recibido del backend
  String? _pausedAtSensor; // sensor en el que estamos pausados

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
      ..addStatusListener(_handleStatus)
      ..addListener(() {
        setState(() {}); // para repintar durante el movimiento
      });

    // Suscribirse al stream de sensores
    widget.sensorStream.listen((info) {
      final sensor = info.positionRaw;
      if (sensor == null) return;
      _onNewSensor(sensor.trim());
    });

    // Iniciar en pausa hasta que llegue primer sensor que coincida con punto inicial
    _controller.stop();
  }

  void _onNewSensor(String sensor) {
    // Si estamos pausados en un sensor y llega el MISMO, no hacer nada.
    if (_pausedAtSensor != null && _pausedAtSensor == sensor) {
      return;
    }

    // Guardar último sensor
    _lastSensor = sensor;

    // Si el sensor recibido es exactamente el sensor del punto ACTUAL, pausar (snap si en movimiento)
    final currentSensorName = _sensorNames[_currentIndex];
    if (sensor == currentSensorName) {
      // Pausar inmediatamente en el punto.
      _controller.stop();
      _controller.value = 0; // nos aseguramos que el tween segmento empieza
      _pausedAtSensor = sensor;
      setState(() {});
      return;
    }

    // Si es diferente al sensor actual, reanudar movimiento hacia el siguiente punto
    // solo si no estamos ya moviéndonos hacia ese siguiente.
    if (!_controller.isAnimating) {
      _advanceToNextPoint();
    }
  }

  void _advanceToNextPoint() {
    _pausedAtSensor = null; // ya no estamos pausados
    _controller.reset();
    _controller.forward();
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // Llegamos al siguiente punto
      _currentIndex = (_currentIndex + 1) % _points.length;
      // Si el nuevo punto coincide con el último sensor recibido, debemos pausar.
      final currentSensorName = _sensorNames[_currentIndex];
      if (_lastSensor == currentSensorName) {
        _controller.stop();
        _controller.value = 0;
        _pausedAtSensor = currentSensorName;
        setState(() {});
      } else {
        // Continuar inmediatamente con el siguiente segmento (porque no hay coincidencia)
        _controller.reset();
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Punto de inicio y fin del segmento actual
    final start = _points[_currentIndex];
    final next = _points[(_currentIndex + 1) % _points.length];
    final t = _controller.value; // 0..1
    final dx = start.dx + (next.dx - start.dx) * t;
    final dy = start.dy + (next.dy - start.dy) * t;

    // Rotación simple basada en dirección del segmento
    final angle = math.atan2(next.dy - start.dy, next.dx - start.dx);

    return Positioned(
      left: dx - widget.busWidth / 2,
      top: dy - widget.busHeight / 2,
      child: Transform.rotate(
        angle: angle,
        child: SizedBox(
          width: widget.busWidth,
            height: widget.busHeight,
            child: SvgPicture.asset(
              'assets/Single_bus_red.svg',
              fit: BoxFit.contain,
            ),
        ),
      ),
    );
  }
}
