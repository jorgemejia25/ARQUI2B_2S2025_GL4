import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import '../services/bus_position_service.dart'; // NUEVO para sensorStream
import '../services/bus_progress_service.dart'; // NUEVO para progreso
import 'dart:async'; // StreamSubscription

/// Widget que mueve y rota un SVG completo siguiendo el circuito del mapa
/// El SVG contiene un bus centrado, y este widget lo posiciona en el circuito
class MovingBusWidget extends StatefulWidget {
  final double maxSegmentSeconds; // (legacy) ignorado ahora porque hacemos 1s fijo
  final double stopSeconds; // (legacy) tiempo de parada fijo cuando coincidencia sensor (usamos 0 para control externo)
  final double? totalCycleSeconds; // sin uso en modo controlado
  final Stream<BusPositionInfo>? sensorStream; // NUEVO: stream de sensores para pausar
  final bool sensorControlled; // activa modo pausa por sensor actual
  final Duration segmentDuration; // En modo discreto: duración total del salto parada->parada. En continuo: duración de cada segmento interno.
  final bool sensorDiscreteStops; // NUEVO: sólo anima de una parada a la siguiente cuando cambia el sensor
  const MovingBusWidget({
    super.key,
    this.maxSegmentSeconds = 0.9,
    this.stopSeconds = 0.0,
    this.totalCycleSeconds,
    this.sensorStream,
    this.sensorControlled = false,
    this.segmentDuration = const Duration(milliseconds: 500),
    this.sensorDiscreteStops = false,
  });

  @override
  State<MovingBusWidget> createState() => _MovingBusWidgetState();
}

class _MovingBusWidgetState extends State<MovingBusWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Paradas: PM1, S2, S1, PM2, S5 (índices según lista de posiciones)
  // PM2 se reintroduce explícitamente
  late final double _stopDuration = widget.stopSeconds; // segundos por parada (ahora 0 en modo controlado)
  late double _totalCycleSeconds; // calculado (legacy)

  // NUEVO control por sensor
  final Map<String, int> _sensorIndexMap = {
    "PM1": 0,
    "S2": 1,
    "S1": 2,
    "PM2": 9, // índice de la parada PM2 dentro de _positions
    "S5": 17, // índice de la parada S5 dentro de _positions
  };
  // String? _lastSensor; // ya no necesitamos almacenarlo explícitamente
  bool _paused = false; // estado de pausa
  int? _desiredStopIndex; // parada objetivo indicada por el último sensor
  int? _currentStopIndex; // parada en la que estamos efectivamente (si pausado)
  double _lastControllerValue = 0.0; // para detectar wrap del ciclo

  // Datos para modo discreto
  List<Offset> _activePath = []; // puntos entre parada actual y objetivo
  List<double> _activeSegLens = [];
  double _activeTotalLen = 0.0;
  Offset? _overridePos; // posición actual en modo discreto
  double? _overrideRot; // rotación actual en modo discreto
  bool get _isDiscrete => widget.sensorControlled && widget.sensorDiscreteStops;

  // ---------------------------
  // MAPEO DE PORCENTAJES (Metro)
  // Ciclo base de checkpoints: PM1 -> S2 -> S1 -> PM2 -> S5 -> PM1
  // Indices en _positions: PM1(0), S2(1), S1(2), PM2(9), S5(17)
  final List<int> _checkpointLoop = [0, 1, 2, 9, 17, 0];
  // Porcentajes vistos desde la barra PM1 (cuando objetivo global es volver a PM1)
  // Regla especial: al salir de PM1 se reinicia a 0 y sube.
  final List<double> _percentPM1 = [100, 10, 20, 50, 85, 100];
  // Porcentajes vistos desde barra PM2 (loop conceptual PM2 -> S5 -> PM1 -> S2 -> S1 -> PM2)
  // Regla especial: al salir de PM2 se reinicia a 0.
  final List<int> _checkpointLoopPM2 = [9, 17, 0, 1, 2, 9];
  final List<double> _percentPM2 = [100, 35, 50, 60, 70, 100];

  // Busca el par (start%, end%) para un segmento fromIdx->toIdx en un loop dado.
  (double? from, double? to, bool resetStart) _segmentPercents(
    int fromIdx,
    int toIdx,
    List<int> loopIdx,
    List<double> loopPerc,
  ) {
    for (int i = 0; i < loopIdx.length - 1; i++) {
      final a = loopIdx[i];
      final b = loopIdx[i + 1];
      if (a == fromIdx && b == toIdx) {
        // Regla de reset: si es primer tramo saliendo del ancla (PM1 para barra PM1, PM2 para barra PM2) entonces porcentaje inicia en 0.
        final bool reset = i == 0; // primer segmento del loop conceptual
        return (reset ? 0.0 : loopPerc[i], loopPerc[i + 1], reset);
      }
    }
    return (null, null, false);
  }

  void _emitCheckpointStatic(int stopIdx) {
    // Emitir porcentajes estáticos en paradas (sin interpolación) para ambas barras
    // PM1 bar
    final posPM1 = _checkpointLoop.indexOf(stopIdx);
    if (posPM1 != -1) {
      final pct = _percentPM1[posPM1];
      BusProgressService.instance.updateStopProgress(
        stopName: 'PM1',
        progress: pct / 100.0,
        remainingDistanceMeters: (100 - pct) * 10.0,
        etaSeconds: 0,
        autoResetOnFull: false,
      );
    }
    // PM2 bar
    final posPM2 = _checkpointLoopPM2.indexOf(stopIdx);
    if (posPM2 != -1) {
      final pct2 = _percentPM2[posPM2];
      BusProgressService.instance.updateStopProgress(
        stopName: 'PM2',
        progress: pct2 / 100.0,
        remainingDistanceMeters: (100 - pct2) * 10.0,
        etaSeconds: 0,
        autoResetOnFull: false,
      );
    }
  }

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
  late List<double> _segmentLengths; // distancia entre posiciones consecutivas
  late List<double> _segmentDurations; // segundos de movimiento por segmento
  late double _movementTotalSeconds; // total de segundos en movimiento (sin paradas)

  StreamSubscription<BusPositionInfo>? _sensorSub; // sub del stream

  @override
  void initState() {
    super.initState();
    _precomputeSegments();
    if (_isDiscrete) {
      _controller = AnimationController(
        duration: widget.segmentDuration,
        vsync: this,
      );
      _controller.addListener(_discreteTick);
    } else {
      _controller = AnimationController(
        duration: Duration(milliseconds: (_totalCycleSeconds * 1000).round()),
        vsync: this,
      )..repeat();
      _controller.addListener(_frameMonitor);
    }

    if (widget.sensorControlled && widget.sensorStream != null) {
      _sensorSub = widget.sensorStream!.listen((info) {
        final name = info.positionRaw?.trim();
        if (name == null) return;
        _handleSensor(name);
      });
    }
  }

  void _precomputeSegments() {
    _segmentLengths = [];
    for (int i = 0; i < _positions.length - 1; i++) {
      _segmentLengths.add((_positions[i + 1] - _positions[i]).distance);
    }
    if (widget.sensorControlled && !widget.sensorDiscreteStops) {
      // Modo controlado por sensores: duración fija por segmento (segmentDuration)
      _segmentDurations = List.filled(
        _positions.length - 1,
        widget.segmentDuration.inMilliseconds / 1000.0,
      );
      _movementTotalSeconds = _segmentDurations.fold(0.0, (a, b) => a + b);
      final totalStopTime = _stopIndices.length * _stopDuration; // usualmente 0
      _totalCycleSeconds = _movementTotalSeconds + totalStopTime;
    } else {
      // Modo simulación automática: velocidad alta y paradas de 0.5s
      final double longest = _segmentLengths.reduce((a, b) => a > b ? a : b);
      // Cada segmento largo no debe exceder maxSegmentSeconds
      final double speed = longest / widget.maxSegmentSeconds; // px/s
      List<double> rawDurations = _segmentLengths.map((d) => d / speed).toList();
      for (int i = 0; i < rawDurations.length; i++) {
        if (rawDurations[i] > widget.maxSegmentSeconds) {
          rawDurations[i] = widget.maxSegmentSeconds; // clamp por seguridad
        }
      }
      _segmentDurations = rawDurations;
      _movementTotalSeconds = _segmentDurations.fold(0.0, (a, b) => a + b);
      final totalStopTime = _stopIndices.length * _stopDuration; // dwell por parada
      final tentativeCycle = _movementTotalSeconds + totalStopTime;
      _totalCycleSeconds = widget.totalCycleSeconds ?? tentativeCycle;
      if (widget.totalCycleSeconds != null && _totalCycleSeconds > tentativeCycle) {
        final extra = _totalCycleSeconds - tentativeCycle;
        final scale = (_movementTotalSeconds + extra) / _movementTotalSeconds;
        _segmentDurations = _segmentDurations.map((d) => d * scale).toList();
        _movementTotalSeconds = _segmentDurations.fold(0.0, (a, b) => a + b);
      }
    }
  }

  void _handleSensor(String sensor) {
    final idx = _sensorIndexMap[sensor];
    if (idx == null) return;
    if (_isDiscrete) {
      if (_currentStopIndex == null) {
        // Primer sensor: posicionar directo
        _currentStopIndex = idx;
        _overridePos = _positions[idx];
        _overrideRot = _orientations[idx];
        _paused = true;
        _emitCheckpointStatic(idx);
        setState(() {});
        return;
      }
      if (_currentStopIndex == idx) {
        // Ya estamos allí
        return;
      }
      _desiredStopIndex = idx;
      _buildActivePath(_currentStopIndex!, idx);
      _paused = false;
      _controller.duration = widget.segmentDuration;
      _controller.reset();
      _controller.forward();
      return;
    } else {
      _desiredStopIndex = idx;
      if (_paused && _currentStopIndex != _desiredStopIndex) {
        _paused = false;
        _resumeFrom(_controller.value);
      }
    }
  }

  double _progressAtStopIndex(int stopIndex) {
    // Reproducimos la misma lógica de _sample para acumular tiempos hasta antes de la parada
    double timeCursor = 0.0;
    for (int i = 0; i < _positions.length - 1; i++) {
      final isStop = _stopIndices.contains(i);
      if (i == stopIndex) {
        return timeCursor / _totalCycleSeconds; // inicio de la parada
      }
      if (isStop) {
        timeCursor += _stopDuration; // usualmente 0
      }
      timeCursor += _segmentDurations[i];
    }
    return 0.0;
  }

  // _isWithinStopWindow eliminado (ya no se usa en modo follow-to-target)

  void _resumeFrom(double current) {
    // Reanudar simplemente haciendo el repeat de nuevo avanzando
    _controller.forward();
    if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    if (_isDiscrete) {
      _controller.removeListener(_discreteTick);
    } else {
      _controller.removeListener(_frameMonitor);
    }
    _controller.dispose();
    super.dispose();
  }

  void _frameMonitor() {
    if (!_controller.isAnimating) return; // si está parado ya no evaluamos
    final value = _controller.value;
    final wrapped = value < _lastControllerValue; // ciclo reinició
    _lastControllerValue = value;

    if (_desiredStopIndex == null || _paused) return;
    final targetProgress = _progressAtStopIndex(_desiredStopIndex!);

    bool reached = false;
    if (!wrapped) {
      // avance normal dentro del mismo ciclo
      if (value >= targetProgress && (value - targetProgress) < 0.003) {
        reached = true;
      }
    } else {
      // wrap: si el target está cerca del inicio (valor pequeño) lo alcanzamos tras reiniciar
      if (value >= targetProgress && (value - targetProgress) < 0.003) {
        reached = true;
      }
    }
    if (reached) {
      _controller.stop();
      _paused = true;
      _currentStopIndex = _desiredStopIndex;
      setState(() {});
    }
  }

  void _buildActivePath(int fromIdx, int toIdx) {
    _activePath = [];
    int i = fromIdx;
    _activePath.add(_positions[i]);
    while (i != toIdx) {
      i = (i + 1) % _positions.length;
      _activePath.add(_positions[i]);
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
    double rot = _overrideRot ?? _orientations[_currentStopIndex ?? 0];
    for (int j = 0; j < _activeSegLens.length; j++) {
      final segLen = _activeSegLens[j];
      if (targetDist <= acc + segLen || j == _activeSegLens.length - 1) {
        final local = segLen == 0 ? 0 : (targetDist - acc) / segLen;
        final p0 = _activePath[j];
        final p1 = _activePath[j + 1];
        pos = Offset(p0.dx + (p1.dx - p0.dx) * local, p0.dy + (p1.dy - p0.dy) * local);
        rot = math.atan2(p1.dy - p0.dy, p1.dx - p0.dx);
        // Interpolación de porcentajes para ambas barras
        final fromIdx = _currentStopIndex!;
        final toIdx = _desiredStopIndex!;
        final (pFrom1, pTo1, reset1) = _segmentPercents(fromIdx, toIdx, _checkpointLoop, _percentPM1);
        final (pFrom2, pTo2, reset2) = _segmentPercents(fromIdx, toIdx, _checkpointLoopPM2, _percentPM2);
        double _remaining(double pct01) => (100.0 - (pct01 * 100.0)) * 10.0; // 1% =10m
        if (pFrom1 != null && pTo1 != null) {
          final pct = (pFrom1 + (pTo1 - pFrom1) * local).clamp(0.0, 100.0);
          BusProgressService.instance.updateStopProgress(
            stopName: 'PM1',
            progress: pct / 100.0,
            remainingDistanceMeters: _remaining(pct / 100.0),
            etaSeconds: (widget.segmentDuration.inMilliseconds / 1000.0) * (1 - local),
            autoResetOnFull: false,
          );
        }
        if (pFrom2 != null && pTo2 != null) {
          final pct2 = (pFrom2 + (pTo2 - pFrom2) * local).clamp(0.0, 100.0);
          BusProgressService.instance.updateStopProgress(
            stopName: 'PM2',
            progress: pct2 / 100.0,
            remainingDistanceMeters: _remaining(pct2 / 100.0),
            etaSeconds: (widget.segmentDuration.inMilliseconds / 1000.0) * (1 - local),
            autoResetOnFull: false,
          );
        }
        break;
      }
      acc += segLen;
    }
    _overridePos = pos;
    _overrideRot = rot;
    if (_controller.status == AnimationStatus.completed) {
      _paused = true;
      _currentStopIndex = _desiredStopIndex;
      _activePath.clear();
      _activeSegLens.clear();
  _emitCheckpointStatic(_currentStopIndex!); // emite porcentaje estático (usa remaining=0 luego UI mostrará 0m)
      setState(() {});
    } else {
      setState(() {});
    }
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
    if (_isDiscrete) {
      final pos = _overridePos ?? _positions.first;
      final rot = _overrideRot ?? _orientations.first;
      const double busWidth = 45;
      const double busHeight = 22;
      return Positioned(
        left: pos.dx - busWidth / 2,
        top: pos.dy - busHeight / 2,
        child: Transform.rotate(
          angle: rot,
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
    }
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
