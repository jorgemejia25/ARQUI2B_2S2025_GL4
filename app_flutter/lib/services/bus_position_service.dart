import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Modelo simple para una posición de bus
class BusPositionInfo {
  final String tipo; // metro | urbano
  final String? positionRaw; // cadena cruda "lat,lon" o cualquier formato
  final DateTime? ts;
  final String? busCode;
  final double? speedKmh;

  const BusPositionInfo({
    required this.tipo,
    this.positionRaw,
    this.ts,
    this.busCode,
    this.speedKmh,
  });
}

/// Servicio que hace polling cada 1s a los endpoints de posiciones.
/// Exposición vía streams separados para metro y urbano.
class BusPositionService {
  static final BusPositionService _instance = BusPositionService._internal();
  factory BusPositionService() => _instance;
  BusPositionService._internal();

  final Duration pollingInterval = const Duration(seconds: 1);
  Timer? _timer;

  // Últimos valores cache para evitar emitir duplicados
  String? _lastMetroPos;
  String? _lastUrbanPos;

  final _metroController = StreamController<BusPositionInfo>.broadcast();
  final _urbanController = StreamController<BusPositionInfo>.broadcast();

  Stream<BusPositionInfo> get metroStream => _metroController.stream;
  Stream<BusPositionInfo> get urbanStream => _urbanController.stream;

  bool get isRunning => _timer != null;

  void start() {
    if (_timer != null) return; // ya corriendo
    _timer = Timer.periodic(pollingInterval, (_) async {
      await _fetchLatest('metro');
      await _fetchLatest('urban');
    });
    // disparo inmediato sin esperar 1s
    _fetchLatest('metro');
    _fetchLatest('urban');
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _fetchLatest(String tipo) async {
    final String url = tipo == 'metro'
        ? ApiConfig.busPositionMetroUrl
        : ApiConfig.busPositionUrbanUrl;

    try {
      final uri = Uri.parse('$url?limit=1&hours=1');
      final resp = await http
          .get(uri, headers: ApiConfig.defaultHeaders)
          .timeout(ApiConfig.shortTimeout);

      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body) as Map<String, dynamic>;
        final List data = decoded['data'] as List? ?? const [];
        if (data.isEmpty) return; // nada que emitir
        final item = data.first as Map<String, dynamic>;
        final String? pos = item['position'] as String?;

        // Evitar re-emitir si no cambió
        if (tipo == 'metro') {
          if (pos == null || pos == _lastMetroPos) return;
          _lastMetroPos = pos;
          _metroController.add(
            BusPositionInfo(
              tipo: 'metro',
              positionRaw: pos,
              ts: _parseTs(item['ts']),
              busCode: item['bus_code'] as String?,
              speedKmh: _toDouble(item['speed_kmh']),
            ),
          );
        } else {
          if (pos == null || pos == _lastUrbanPos) return;
            _lastUrbanPos = pos;
            _urbanController.add(
              BusPositionInfo(
                tipo: 'urban',
                positionRaw: pos,
                ts: _parseTs(item['ts']),
                busCode: item['bus_code'] as String?,
                speedKmh: _toDouble(item['speed_kmh']),
              ),
            );
        }
      }
    } catch (_) {
      // Silenciar errores de red para no spamear la UI
    }
  }

  DateTime? _parseTs(dynamic value) {
    if (value is String) {
      try {
        return DateTime.parse(value.replaceAll(' ', 'T'));
      } catch (_) {}
    }
    return null;
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) {
      return double.tryParse(v);
    }
    return null;
  }

  void dispose() {
    stop();
    _metroController.close();
    _urbanController.close();
  }
}
