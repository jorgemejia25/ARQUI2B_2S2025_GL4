import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/bus_position_service.dart'; // NUEVO para sensor stream
import 'dart:async';
import '../services/bus_progress_service.dart'; // progreso compartido

/// Bus urbano morado que recorre las paradas azules (PU1, S4, S3, PU2, S3, S4) en bucle.
/// Dirección:
///  - Carril superior: Izquierda -> Derecha (PU1 -> S4 -> S3)
///  - Giro en U después de sobrepasar S3 baja al carril inferior
///  - Carril inferior: Derecha -> Izquierda (PU2 -> S3 -> S4)
///  - Giro en U después de sobrepasar S4 sube al carril superior
/// Paradas (2s): PU1, S4 (arriba), S3 (arriba), PU2, S3 (abajo), S4 (abajo)
class MovingUrbanBusWidget extends StatefulWidget {
  final double maxSegmentSeconds; // modo automático
  final double stopSeconds; // modo automático
  final double? totalCycleSeconds; // modo automático
  final Stream<BusPositionInfo>? sensorStream; // NUEVO
  final bool sensorControlled; // NUEVO: pausar en parada según sensor
  final bool sensorDiscreteStops; // NUEVO: saltos discretos entre paradas
  final Duration segmentDuration; // duración del salto discreto
  const MovingUrbanBusWidget({
    super.key,
    this.maxSegmentSeconds = 0.9,
    this.stopSeconds = 3.0,
    this.totalCycleSeconds,
    this.sensorStream,
    this.sensorControlled = false,
    this.sensorDiscreteStops = false,
    this.segmentDuration = const Duration(milliseconds: 500),
  });

  @override
  State<MovingUrbanBusWidget> createState() => _MovingUrbanBusWidgetState();
}

class _MovingUrbanBusWidgetState extends State<MovingUrbanBusWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  StreamSubscription<BusPositionInfo>? _sensorSub;
  bool get _isDiscrete => widget.sensorControlled && widget.sensorDiscreteStops;
  bool _paused = false; // cuando llega a parada objetivo
  int? _currentStopIndex; // índice de la parada actual (en stops oficiales)
  int? _desiredStopIndex; // próxima parada objetivo
  Offset? _overridePos; // posición override en modo discreto
  double? _overrideRot; // rotación override en modo discreto
  List<Offset> _activePath = [];
  List<double> _activeSegLens = [];
  double _activeTotalLen = 0.0;

  // ---------------------------
  // MAPEO DE PORCENTAJES (Urbano)
  // Loop conceptual para barra PU1: PU1(100) -> S4↑(15) -> S3↑(30) -> PU2(50) -> S3↓(65) -> S4↓(80) -> PU1(100)
  final List<int> _loopPU1 = [0, 2, 4, 12, 13, 15, 0];
  final List<double> _pctPU1 = [100, 15, 30, 50, 65, 80, 100];
  // Loop conceptual para barra PU2: PU2(100) -> S3↓(15) -> S4↓(30) -> PU1(50) -> S4↑(65) -> S3↑(80) -> PU2(100)
  final List<int> _loopPU2 = [12, 13, 15, 0, 2, 4, 12];
  final List<double> _pctPU2 = [100, 15, 30, 50, 65, 80, 100];

  (double? from, double? to, bool reset) _segmentPct(
    int fromIdx,
    int toIdx,
    List<int> loopIdx,
    List<double> loopPct,
  ) {
    for (int i = 0; i < loopIdx.length - 1; i++) {
      if (loopIdx[i] == fromIdx && loopIdx[i + 1] == toIdx) {
        final bool r = i == 0; // primer tramo: reinicia a 0 durante movimiento
        final startVal = r ? 0.0 : loopPct[i];
        return (startVal, loopPct[i + 1], r);
      }
    }
    return (null, null, false);
  }

  void _emitStaticCheckpoint(int stopIdx) {
    final pos1 = _loopPU1.indexOf(stopIdx);
    if (pos1 != -1) {
      BusProgressService.instance.updateStopProgress(
        stopName: 'PU1',
        progress: (_pctPU1[pos1] / 100.0).clamp(0.0, 1.0),
        remainingDistanceMeters: _remainingFromPercent(_pctPU1[pos1]),
        etaSeconds: 0,
        autoResetOnFull: false,
      );
    }
    final pos2 = _loopPU2.indexOf(stopIdx);
    if (pos2 != -1) {
      BusProgressService.instance.updateStopProgress(
        stopName: 'PU2',
        progress: (_pctPU2[pos2] / 100.0).clamp(0.0, 1.0),
        remainingDistanceMeters: _remainingFromPercent(_pctPU2[pos2]),
        etaSeconds: 0,
        autoResetOnFull: false,
      );
    }
  }

  double _remainingFromPercent(double pct) {
    // Cada 100% = destino alcanzado => 0m restantes
    // Por enunciado: 1000m entre paradas principales, 1% = 10m avanzados, remaining = (100 - pct)*10
    return (100.0 - pct) * 10.0;
  }

  // Mapear nombres de sensores urbanos al índice de parada en _path
  // Secuencia urbana: PU1, S4, S3, PU2, S3, S4 (loop)
  final Map<String, int> _urbanSensorIndex = {
    'PU1': 0, // arriba izquierda
    'S4': 2,  // S4 arriba
    'S3': 4,  // S3 arriba (primera aparición)
    'PU2': 12,
    // Segunda S3 (abajo) -> índice 13
    // Segunda S4 (abajo) -> índice 15
  };

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
    if (_isDiscrete) {
      _controller = AnimationController(
        duration: widget.segmentDuration,
        vsync: this,
      );
      _controller.addListener(_discreteTick);
    } else {
      _controller = AnimationController(
        duration: Duration(milliseconds: (totalCycleSeconds * 1000).round()),
        vsync: this,
      )..repeat();
    }
    if (widget.sensorControlled && widget.sensorStream != null) {
      _sensorSub = widget.sensorStream!.listen((info) {
        final raw = info.positionRaw?.trim();
        if (raw != null) {
          _handleSensor(raw);
        }
      });
    }
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
    _sensorSub?.cancel();
    if (_isDiscrete) {
      _controller.removeListener(_discreteTick);
    }
    _controller.dispose();
    super.dispose();
  }

  void _handleSensor(String sensor) {
    if (!_isDiscrete) return; // Por ahora sólo implementamos modo discreto
    // Resolver duplicados: segunda aparición de S3 y S4 cuando ya pasamos por PU2
    int? baseIndex = _urbanSensorIndex[sensor];
    if (sensor == 'S3') {
      // Si ya estuvimos en PU2 (12) y en S3 inferior (13) permitir saltar a 13
      if (_currentStopIndex != null && _currentStopIndex! >= 12) {
        baseIndex = 13; // S3 inferior
      }
    } else if (sensor == 'S4') {
      if (_currentStopIndex != null && _currentStopIndex! >= 13) {
        baseIndex = 15; // S4 inferior
      }
    }
    final idx = baseIndex;
    if (idx == null) return;
    if (_currentStopIndex == null) {
      _currentStopIndex = idx;
      _overridePos = _path[idx];
      _overrideRot = _orientations[idx];
      _paused = true;
      _emitStaticCheckpoint(idx);
      setState(() {});
      return;
    }
    if (_currentStopIndex == idx) return; // sin cambio
    _desiredStopIndex = idx;
    _buildActivePath(_currentStopIndex!, idx);
    _paused = false;
    _controller.duration = widget.segmentDuration;
    _controller.reset();
    _controller.forward();
  }

  void _buildActivePath(int fromIdx, int toIdx) {
    _activePath = [];
    int i = fromIdx;
    _activePath.add(_path[i]);
    while (i != toIdx) {
      i = (i + 1) % _path.length;
      _activePath.add(_path[i]);
    }
    _activeSegLens = [];
    _activeTotalLen = 0.0;
    for (int j = 0; j < _activePath.length - 1; j++) {
      final d = (_activePath[j + 1] - _activePath[j]).distance;
      _activeSegLens.add(d);
      _activeTotalLen += d;
    }
  }

  void _discreteTick() {
    if (_paused || _activePath.length < 2) return;
    final t = _controller.value; // 0..1
    final targetDist = t * _activeTotalLen;
    double acc = 0.0;
    Offset pos = _activePath.first;
    double rot = _overrideRot ?? 0;
    for (int j = 0; j < _activeSegLens.length; j++) {
      final segLen = _activeSegLens[j];
      if (targetDist <= acc + segLen || j == _activeSegLens.length - 1) {
        final local = segLen == 0 ? 0 : (targetDist - acc) / segLen;
        final p0 = _activePath[j];
        final p1 = _activePath[j + 1];
        pos = Offset(
          p0.dx + (p1.dx - p0.dx) * local,
          p0.dy + (p1.dy - p0.dy) * local,
        );
        rot = math.atan2(p1.dy - p0.dy, p1.dx - p0.dx);
        break;
      }
      acc += segLen;
    }
    _overridePos = pos;
    _overrideRot = rot;
    _emitInterpolated(pos);
    if (_controller.status == AnimationStatus.completed) {
      _paused = true;
      _currentStopIndex = _desiredStopIndex;
      _activePath.clear();
      _activeSegLens.clear();
      if (_currentStopIndex != null) _emitStaticCheckpoint(_currentStopIndex!);
      setState(() {});
    } else {
      setState(() {});
    }
  }
  void _emitInterpolated(Offset pos) {
    if (_currentStopIndex == null || _desiredStopIndex == null) return;
    final fromIdx = _currentStopIndex!;
    final toIdx = _desiredStopIndex!;
    // Distancia local para interpolación lineal simple
    // (distancia total ya implícita en _controller.value; no necesitamos distAlong)
    // Ya calculamos pos real; usamos _controller.value para factor directo
    final local = _controller.value; // 0..1 del salto total
    final (pFrom1, pTo1, _) = _segmentPct(fromIdx, toIdx, _loopPU1, _pctPU1);
    final (pFrom2, pTo2, _) = _segmentPct(fromIdx, toIdx, _loopPU2, _pctPU2);
    if (pFrom1 != null && pTo1 != null) {
      final pct = (pFrom1 + (pTo1 - pFrom1) * local).clamp(0.0, 100.0);
      BusProgressService.instance.updateStopProgress(
        stopName: 'PU1',
        progress: pct / 100.0,
        remainingDistanceMeters: _remainingFromPercent(pct),
        etaSeconds: (widget.segmentDuration.inMilliseconds / 1000.0) * (1 - local),
        autoResetOnFull: false,
      );
    }
    if (pFrom2 != null && pTo2 != null) {
      final pct2 = (pFrom2 + (pTo2 - pFrom2) * local).clamp(0.0, 100.0);
      BusProgressService.instance.updateStopProgress(
        stopName: 'PU2',
        progress: pct2 / 100.0,
        remainingDistanceMeters: _remainingFromPercent(pct2),
        etaSeconds: (widget.segmentDuration.inMilliseconds / 1000.0) * (1 - local),
        autoResetOnFull: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDiscrete) {
      final pos = _overridePos ?? _path.first;
      final rot = _overrideRot ?? 0.0;
      return Positioned(
        left: pos.dx - busW / 2,
        top: pos.dy - busH / 2,
        child: Transform.rotate(
          angle: rot,
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
    }
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
