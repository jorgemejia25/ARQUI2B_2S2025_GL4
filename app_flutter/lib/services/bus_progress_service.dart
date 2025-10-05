import 'dart:async';

/// Datos de aproximación a una parada específica.
class StopApproachProgress {
  final String stopName; // PM1, PM2, PU1, PU2
  final double progress; // 0..1
  final double remainingDistanceMeters; // metros restantes (px = m)
  final double etaSeconds; // segundos estimados restantes
  const StopApproachProgress({
    required this.stopName,
    required this.progress,
    required this.remainingDistanceMeters,
    required this.etaSeconds,
  });

  StopApproachProgress copyWith({
    double? progress,
    double? remainingDistanceMeters,
    double? etaSeconds,
  }) => StopApproachProgress(
        stopName: stopName,
        progress: progress ?? this.progress,
        remainingDistanceMeters: remainingDistanceMeters ?? this.remainingDistanceMeters,
        etaSeconds: etaSeconds ?? this.etaSeconds,
      );
}

/// Servicio singleton que recibe actualizaciones desde los widgets de buses y
/// emite un stream con el progreso hacia paradas clave.
class BusProgressService {
  static final BusProgressService _instance = BusProgressService._internal();
  factory BusProgressService() => _instance;
  BusProgressService._internal();

  static BusProgressService get instance => _instance;

  final _controller = StreamController<List<StopApproachProgress>>.broadcast();
  Stream<List<StopApproachProgress>> get stream => _controller.stream;

  final Map<String, StopApproachProgress> _byStop = {
    'PM1': const StopApproachProgress(stopName: 'PM1', progress: 0, remainingDistanceMeters: 0, etaSeconds: 0),
    'PM2': const StopApproachProgress(stopName: 'PM2', progress: 0, remainingDistanceMeters: 0, etaSeconds: 0),
    'PU1': const StopApproachProgress(stopName: 'PU1', progress: 0, remainingDistanceMeters: 0, etaSeconds: 0),
    'PU2': const StopApproachProgress(stopName: 'PU2', progress: 0, remainingDistanceMeters: 0, etaSeconds: 0),
  };

  /// Devuelve el snapshot actual (últimos valores) para usar como `initialData`
  /// en un StreamBuilder y así evitar estados "vacíos" iniciales en UI.
  List<StopApproachProgress> get currentValues => _byStop.values.toList(growable: false);

  /// Actualiza progreso de una parada destino específica.
  /// [progress] entre 0..1. Cuando llega (progress >=1) se resetea a 0 tras emitir.
  void updateStopProgress({
    required String stopName,
    required double progress,
    required double remainingDistanceMeters,
    required double etaSeconds,
    bool autoResetOnFull = true,
  }) {
    if (!_byStop.containsKey(stopName)) return; // ignorar otras paradas
  if (progress >= 1.0 && autoResetOnFull) {
      // Emitir llegada primero como 1 y luego reset a 0 para reinicio visual
      _byStop[stopName] = StopApproachProgress(
        stopName: stopName,
        progress: 1.0,
        remainingDistanceMeters: 0,
        etaSeconds: 0,
      );
      _emit();
      // Reset inmediato (pequeño delay microtask para permitir construir UI)
      scheduleMicrotask(() {
        _byStop[stopName] = StopApproachProgress(
          stopName: stopName,
          progress: 0,
          remainingDistanceMeters: 0,
          etaSeconds: 0,
        );
        _emit();
      });
      return;
    }
    _byStop[stopName] = StopApproachProgress(
      stopName: stopName,
      progress: progress.clamp(0.0, 1.0),
      remainingDistanceMeters: remainingDistanceMeters < 0 ? 0 : remainingDistanceMeters,
      etaSeconds: etaSeconds < 0 ? 0 : etaSeconds,
    );
    _emit();
  }

  void _emit() {
    _controller.add(_byStop.values.toList());
  }

  void dispose() {
    _controller.close();
  }
}
