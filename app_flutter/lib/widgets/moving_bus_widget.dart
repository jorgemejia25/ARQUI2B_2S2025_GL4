import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;

/// Widget que mueve y rota un SVG completo siguiendo el circuito del mapa
/// El SVG contiene un bus centrado, y este widget lo posiciona en el circuito
class MovingBusWidget extends StatefulWidget {
  final double maxSegmentSeconds; // duración máxima de un segmento de movimiento
  final double stopSeconds; // duración por parada
  final double? totalCycleSeconds; // opcional: fuerza duración total
  const MovingBusWidget({
    super.key,
    this.maxSegmentSeconds = 0.9,
    this.stopSeconds = 3.0,
    this.totalCycleSeconds,
  });

  @override
  State<MovingBusWidget> createState() => _MovingBusWidgetState();
}

class _MovingBusWidgetState extends State<MovingBusWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Paradas: PM1, S2, S1, PM2, S5 (índices según lista de posiciones)
  // PM2 se reintroduce explícitamente
  late final double _stopDuration = widget.stopSeconds; // segundos por parada
  late final double _totalCycleSeconds; // calculado

  // Lista de posiciones (incluye puntos intermedios para giros suaves)
  // Se añadió PM2 real (122, 996)
  // Posiciones como CENTRO del carril (no esquina superior izquierda)
  // Centro de carriles:
  //  Horizontal superior: y = (314+364)/2 = 339
  //  Horizontal inferior: y = (1035+985)/2 = 1010
  //  Vertical izquierdo: x = (39+89)/2 = 64
  //  Vertical derecho: x = (847+797)/2 = 822
  //  Paradas convertidas a coordenadas de centro aproximadas.
  final List<Offset> _positions = [
    const Offset(809, 339),  // 0 PM1 (centro del rect original 787,327 size 45x22)
    const Offset(562, 339),  // 1 S2 (centro rect 540,327)
    const Offset(358, 339),  // 2 S1 (centro rect 335,327)
    const Offset(173, 339),  // 3 acercándose esquina sup izq (aprox)
    const Offset(64, 339),   // 4 esquina sup izq (giro)
    const Offset(64, 500),   // 5 bajando
    const Offset(64, 800),   // 6 bajando
    const Offset(64, 950),   // 7 acercándose inf izq
    const Offset(64, 1010),  // 8 esquina inf izq (giro)
    const Offset(145, 1010), // 9 PM2 (centro rect 122,996)
    const Offset(300, 1010), // 10 avanzando
    const Offset(500, 1010), // 11 avanzando
    const Offset(700, 1010), // 12 avanzando
    const Offset(780, 1010), // 13 acercándose inf der
    const Offset(822, 1010), // 14 esquina inf der (giro)
    const Offset(822, 900),  // 15 subiendo
    const Offset(822, 800),  // 16 subiendo
    const Offset(822, 674),  // 17 S5 (centro rect 809,651 size 22x45 ≈ 820,673.5)
    const Offset(822, 500),  // 18 subiendo
    const Offset(822, 380),  // 19 subiendo
    const Offset(822, 339),  // 20 esquina sup der (giro)
    const Offset(809, 339),  // 21 regreso a PM1
  ];

  // Índices de paradas (se detiene 2s en cada una)
  final Set<int> _stopIndices = {0, 1, 2, 9, 17};

  // Orientaciones deseadas por nodo (dirección del siguiente tramo)
  // 0=derecha, π/2=abajo, π=izquierda, -π/2=arriba
  late final List<double> _orientations = [
    math.pi, // 0 PM1 → izquierda
    math.pi, // 1 S2 → izquierda
    math.pi, // 2 S1 → izquierda
    math.pi, // 3 hacia esquina sup izq
    math.pi / 2, // 4 baja
    math.pi / 2, // 5 baja
    math.pi / 2, // 6 baja
    math.pi / 2, // 7 baja
    0,          // 8 (giro anticipado: al final del tramo 7→8 ya rota a derecha)
    0,          // 9 PM2 → derecha
    0,          // 10 derecha
    0,          // 11 derecha
    0,          // 12 derecha
    0,          // 13 derecha
    -math.pi / 2, // 14 sube
    -math.pi / 2, // 15 sube
    -math.pi / 2, // 16 sube
    -math.pi / 2, // 17 S5 → sube
    -math.pi / 2, // 18 sube
    -math.pi / 2, // 19 sube
    math.pi,      // 20 esquina sup der → izquierda
    math.pi,      // 21 regreso (cierra ciclo)
  ];

  // Datos precomputados para movimiento proporcional a distancia
  late final List<double> _segmentLengths; // distancia entre posiciones consecutivas
  late final List<double> _segmentDurations; // segundos de movimiento por segmento
  late final double _movementTotalSeconds; // total de segundos en movimiento (sin paradas)

  @override
  void initState() {
    super.initState();
  _precomputeSegments();
    _controller = AnimationController(
      duration: Duration(milliseconds: (_totalCycleSeconds * 1000).round()),
      vsync: this,
    )..repeat();
  }

  void _precomputeSegments() {
    // Primero calculamos distancias
    _segmentLengths = [];
    for (int i = 0; i < _positions.length - 1; i++) {
      final d = (_positions[i + 1] - _positions[i]).distance;
      _segmentLengths.add(d);
    }

    // Velocidad base (px/s) suponiendo que queremos que cada segmento dure proporcional a su distancia
    // pero limitado a widget.maxSegmentSeconds.
    // Calculamos una velocidad candidate: speed = maxLength / maxSegmentSeconds para el segmento más largo si no hubiera ciclo.
    final double longest = _segmentLengths.reduce((a, b) => a > b ? a : b);
    final double speed = longest / widget.maxSegmentSeconds; // px/s

    // Duraciones iniciales por segmento según esta velocidad
    List<double> rawDurations = _segmentLengths.map((d) => d / speed).toList();
    // Aseguramos límite (por si redondeos)
    for (int i = 0; i < rawDurations.length; i++) {
      if (rawDurations[i] > widget.maxSegmentSeconds) {
        rawDurations[i] = widget.maxSegmentSeconds;
      }
    }
    _segmentDurations = rawDurations;
    _movementTotalSeconds = _segmentDurations.fold(0.0, (a, b) => a + b);

    final totalStopTime = _stopIndices.length * _stopDuration;
    final tentativeCycle = _movementTotalSeconds + totalStopTime;
    _totalCycleSeconds = widget.totalCycleSeconds ?? tentativeCycle;

    // Si se especificó totalCycleSeconds y es mayor a la suma actual, escalamos movimiento uniformemente
    if (widget.totalCycleSeconds != null && _totalCycleSeconds > tentativeCycle) {
      final extra = _totalCycleSeconds - tentativeCycle;
      final scale = (_movementTotalSeconds + extra) / _movementTotalSeconds;
      _segmentDurations = _segmentDurations.map((d) => d * scale).toList();
      _movementTotalSeconds = _segmentDurations.fold(0.0, (a, b) => a + b);
    }

    // (Lógica de duraciones movida arriba)
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Devuelve estado actual (posición + rotación) dado el tiempo en segundos
  ({Offset position, double rotation}) _sample(double tSeconds) {
    double timeCursor = 0.0;
    for (int i = 0; i < _positions.length - 1; i++) {
      final isStop = _stopIndices.contains(i);
      final movementTime = _segmentDurations[i];
      final stopTime = isStop ? _stopDuration : 0.0;

      // Fase de parada
      if (isStop) {
        if (tSeconds >= timeCursor && tSeconds < timeCursor + stopTime) {
          return (position: _positions[i], rotation: _orientations[i]);
        }
        timeCursor += stopTime;
      }

      // Fase de movimiento
      if (tSeconds >= timeCursor && tSeconds < timeCursor + movementTime) {
        final local = (tSeconds - timeCursor) / movementTime; // 0..1
        final p0 = _positions[i];
        final p1 = _positions[i + 1];
        final pos = Offset(
          p0.dx + (p1.dx - p0.dx) * local,
          p0.dy + (p1.dy - p0.dy) * local,
        );

        // Rotación: mantener orientación inicial y girar rápido en último 15%
        final rotStart = _orientations[i];
        final rotEnd = _orientations[i + 1];
        double rot;
        if (local < 0.85) {
          rot = rotStart;
        } else {
          final frac = (local - 0.85) / 0.15; // 0..1
          double diff = rotEnd - rotStart;
          if (diff > math.pi) diff -= 2 * math.pi; else if (diff < -math.pi) diff += 2 * math.pi;
            rot = rotStart + diff * frac;
        }
        return (position: pos, rotation: rot);
      }
      timeCursor += movementTime;
    }
    // Última parada (PM1 fin/inicio)
    return (position: _positions.last, rotation: _orientations.last);
  }

  Offset _getCurrentPosition(double progress) {
    final t = progress * _totalCycleSeconds;
    return _sample(t).position;
  }

  double _getCurrentRotation(double progress) {
    final t = progress * _totalCycleSeconds;
    return _sample(t).rotation;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final position = _getCurrentPosition(_controller.value);
        final rotation = _getCurrentRotation(_controller.value);

        const double busWidth = 45;
        const double busHeight = 22;
        return Positioned(
          left: position.dx - busWidth / 2,
            top: position.dy - busHeight / 2,
            child: Transform.rotate(
              angle: rotation,
              alignment: Alignment.center,
              child: SizedBox(
                width: busWidth,
                height: busHeight,
                child: SvgPicture.asset(
                  'assets/Single_bus_red_compact.svg',
                  width: busWidth,
                  height: busHeight,
                ),
              ),
            ),
          );
      },
    );
  }
}
