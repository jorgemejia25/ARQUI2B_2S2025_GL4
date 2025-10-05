import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Bus urbano morado que recorre las paradas azules (PU1, S4, S3, PU2, S3, S4) en bucle.
/// Dirección:
///  - Carril superior: Izquierda -> Derecha (PU1 -> S4 -> S3)
///  - Giro en U después de sobrepasar S3 baja al carril inferior
///  - Carril inferior: Derecha -> Izquierda (PU2 -> S3 -> S4)
///  - Giro en U después de sobrepasar S4 sube al carril superior
/// Paradas (2s): PU1, S4 (arriba), S3 (arriba), PU2, S3 (abajo), S4 (abajo)
class MovingUrbanBusWidget extends StatefulWidget {
  final double maxSegmentSeconds;
  final double stopSeconds;
  final double? totalCycleSeconds; // opcional, si no se da se calcula
  const MovingUrbanBusWidget({
    super.key,
    this.maxSegmentSeconds = 0.9,
    this.stopSeconds = 3.0,
    this.totalCycleSeconds,
  });

  @override
  State<MovingUrbanBusWidget> createState() => _MovingUrbanBusWidgetState();
}

class _MovingUrbanBusWidgetState extends State<MovingUrbanBusWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Dimensiones del bus compacto
  static const double busW = 45;
  static const double busH = 22;

  // Coordenadas de paradas originales (rect top-left):
  // PU1: (627,649)  S4: (548,649)  S3: (330,649)
  // PU2: (253,674)  S3 abajo: (330,674)  S4 abajo: (548,674)
  // Convertimos a centros del carril: usamos centro vertical de cada rect.
  // Para el carril superior Y_base_sup = 649 + 11 = 660 (aprox medio del rect 22 alto)
  // Para el carril inferior Y_base_inf = 674 + 11 = 685
  // Ajuste fino: si se requiere, se puede parametrizar.
  static const double yTop = 660; // línea de movimiento superior
  static const double yBottom = 685; // línea de movimiento inferior

  // Convertimos X al centro sumando busW/2 (22.5) a la coordenada original del rect.
  double _centerX(double left) => left + busW / 2;

  // Nueva ruta con U-turns precisos en X=110 y X=770 (centros), añadiendo parada PU2 en carril inferior.
  // Se agregan nodos intermedios horizontales y verticales para suavizar rotación y evitar posiciones extrañas.
  late final List<Offset> _path = [
    // Carril superior → derecha
    Offset(_centerX(627), yTop), // 0 PU1 (stop)
    Offset(_centerX(600), yTop), // 1 transición
    Offset(_centerX(548), yTop), // 2 S4 (stop)
    Offset(_centerX(480), yTop), // 3
    Offset(_centerX(330), yTop), // 4 S3 (stop)
    Offset(_centerX(200), yTop), // 5 transición
    Offset(_centerX(140), yTop), // 6 transición final
    Offset(_centerX(88), yTop),  // 7 extremo antes U-turn izquierda (centro≈110)
    // Descenso U-turn izquierda
    Offset(_centerX(88), yTop + 8),             // 8 curva
    Offset(_centerX(88), (yTop + yBottom) / 2), // 9 curva media
    Offset(_centerX(88), yBottom - 8),          // 10 curva
    Offset(_centerX(88), yBottom),              // 11 carril inferior alcanzado
    // Carril inferior ← izquierda
    Offset(_centerX(253), yBottom), // 12 PU2 (stop)
    Offset(_centerX(330), yBottom), // 13 S3 inferior (stop)
    Offset(_centerX(400), yBottom), // 14
    Offset(_centerX(548), yBottom), // 15 S4 inferior (stop)
    Offset(_centerX(620), yBottom), // 16 transición
    Offset(_centerX(690), yBottom), // 17 transición
    Offset(_centerX(748), yBottom), // 18 extremo antes U-turn derecha (centro≈770)
    // Ascenso U-turn derecha
    Offset(_centerX(748), yBottom - 8),         // 19 curva
    Offset(_centerX(748), (yTop + yBottom) / 2),// 20 curva media
    Offset(_centerX(748), yTop + 8),            // 21 curva
    Offset(_centerX(748), yTop),                // 22 carril superior recuperado
    Offset(_centerX(627), yTop), // 23 PU1 (stop final loop)
  ];

  final Set<int> _stopIndices = {0, 2, 4, 12, 13, 15, 23};

  // Orientaciones: izquierda (pi), derecha (0), arriba (-pi/2), abajo (pi/2)
  late final List<double> _orientations = [
    math.pi, // 0 PU1 (moviendo a la izquierda sobre carril superior)
    math.pi, // 1
    math.pi, // 2 S4
    math.pi, // 3
    math.pi, // 4 S3
    math.pi, // 5
    math.pi, // 6
    math.pi, // 7 extremo antes U-turn izq
    math.pi / 2, // 8 bajando (no usado fuera de curva)
    math.pi / 2, // 9
    math.pi / 2, //10
    0,          // 11 fin U-turn ya apuntando a la derecha (carril inferior)
    0, //12 PU2 →
    0, //13 S3 inferior
    0, //14
    0, //15 S4 inferior
    0, //16
    0, //17
    0, //18 extremo antes U-turn der
    -math.pi / 2, //19 subiendo (no usado fuera de curva)
    -math.pi / 2, //20
    -math.pi / 2, //21
    math.pi,      //22 fin U-turn ya apuntando a la izquierda (carril superior)
    math.pi, //23 PU1 ←
  ];

  // Tiempos
  late final double stopDuration = widget.stopSeconds; // por parada
  late final double totalCycleSeconds; // se calculará
  late final double _movementSeconds; // total movimiento
  late final List<double> _segmentLengths;
  late final List<double> _segmentDurations;

  @override
  void initState() {
    super.initState();
    _precompute();
    _controller = AnimationController(
      duration: Duration(milliseconds: (totalCycleSeconds * 1000).round()),
      vsync: this,
    )..repeat();
  }

  void _precompute() {
    _segmentLengths = [];
    for (int i = 0; i < _path.length - 1; i++) {
      _segmentLengths.add((_path[i + 1] - _path[i]).distance);
    }
    final longest = _segmentLengths.reduce((a, b) => a > b ? a : b);
    final speed = longest / widget.maxSegmentSeconds; // px/s
    _segmentDurations = _segmentLengths.map((d) {
      final dur = d / speed;
      return dur > widget.maxSegmentSeconds ? widget.maxSegmentSeconds : dur;
    }).toList();
    _movementSeconds = _segmentDurations.fold(0.0, (a, b) => a + b);
    final totalStopTime = _stopIndices.length * stopDuration;
    final tentative = _movementSeconds + totalStopTime;
    totalCycleSeconds = widget.totalCycleSeconds ?? tentative;
    if (widget.totalCycleSeconds != null && totalCycleSeconds > tentative) {
      final extra = totalCycleSeconds - tentative;
      final scale = (_movementSeconds + extra) / _movementSeconds;
      _segmentDurations = _segmentDurations.map((d) => d * scale).toList();
      _movementSeconds = _segmentDurations.fold(0.0, (a, b) => a + b);
    }
  }

  ({Offset pos, double rot}) _sample(double t) {
    double cursor = 0;
    for (int i = 0; i < _path.length - 1; i++) {
      final isStop = _stopIndices.contains(i);
      final stopTime = isStop ? stopDuration : 0.0;
      if (isStop) {
        if (t >= cursor && t < cursor + stopTime) {
          return (pos: _path[i], rot: _orientations[i]);
        }
        cursor += stopTime;
      }
      final moveTime = _segmentDurations[i];
      if (t >= cursor && t < cursor + moveTime) {
        final local = (t - cursor) / moveTime;
        final p0 = _path[i];
        final p1 = _path[i + 1];
        final interp = Offset(
          p0.dx + (p1.dx - p0.dx) * local,
          p0.dy + (p1.dy - p0.dy) * local,
        );

        // Rangos de U-turn: izquierda (7->11) y derecha (18->22)
        double rot;
        bool inLeftUTurn = i >= 7 && i < 11; // segmentos 7-8,8-9,9-10,10-11
        bool inRightUTurn = i >= 18 && i < 22; // 18-19,19-20,20-21,21-22

        if (inLeftUTurn || inRightUTurn) {
          // Calcular progreso acumulado dentro del conjunto de segmentos de la curva.
            int start = inLeftUTurn ? 7 : 18;
            int endExclusive = inLeftUTurn ? 11 : 22; // último índice de inicio de segmento dentro del giro
            // Tiempo total de la curva
            double curveTotal = 0;
            for (int k = start; k < endExclusive; k++) {
              curveTotal += _segmentDurations[k];
            }
            // Tiempo transcurrido antes del segmento actual dentro de la curva
            double curveElapsed = 0;
            for (int k = start; k < i; k++) {
              curveElapsed += _segmentDurations[k];
            }
            curveElapsed += _segmentDurations[i] * local;
            double curveProgress = (curveElapsed / curveTotal).clamp(0.0, 1.0);

            // Rotaciones objetivo corregidas según sentido real:
            // U-turn izquierda: de π (←) a 0 (→) al pasar al carril inferior.
            // U-turn derecha: de 0 (→) a π (←) al regresar al carril superior.
            double startRot = inLeftUTurn ? math.pi : 0.0;
            double endRot = inLeftUTurn ? 0.0 : math.pi; // normalizado
            // Interpolación lineal teniendo en cuenta envoltura (ya son distancias ≤ π)
            double diff = endRot - startRot;
            if (diff > math.pi) diff -= 2 * math.pi; else if (diff < -math.pi) diff += 2 * math.pi;
            rot = startRot + diff * curveProgress;
        } else {
          // Fuera de U-turn: mantener orientación inicial del segmento y rotar sólo al final (comportamiento anterior)
          final r0 = _orientations[i];
          final r1 = _orientations[i + 1];
          if (local < 0.85) {
            rot = r0;
          } else {
            final f = (local - 0.85) / 0.15;
            double diff = r1 - r0;
            if (diff > math.pi) diff -= 2 * math.pi; else if (diff < -math.pi) diff += 2 * math.pi;
            rot = r0 + diff * f;
          }
        }
        return (pos: interp, rot: rot);
      }
      cursor += moveTime;
    }
  return (pos: _path.last, rot: _orientations.last);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
  final t = _controller.value * totalCycleSeconds;
        final sample = _sample(t);
        return Positioned(
          left: sample.pos.dx - busW / 2,
          top: sample.pos.dy - busH / 2,
          child: Transform.rotate(
            angle: sample.rot,
            alignment: Alignment.center,
            child: SizedBox(
              width: busW,
              height: busH,
              child: SvgPicture.asset(
                'assets/Single_bus_purple_compact.svg',
                width: busW,
                height: busH,
              ),
            ),
          ),
        );
      },
    );
  }
}
