import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dashboard_models.dart';

class DashboardApiService {
  static const String baseUrl =
      'https://arqui2b2s2025gl4-production.up.railway.app/api/v1/data/dashboard';

  static const Duration timeout = Duration(seconds: 10);

  // Singleton
  static final DashboardApiService _instance = DashboardApiService._internal();
  factory DashboardApiService() => _instance;
  DashboardApiService._internal();

  Future<DashboardSummary?> getSummary() async {
    try {
      print('🔄 Solicitando resumen del dashboard...');
      final response = await http
          .get(
            Uri.parse('$baseUrl/summary'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(
          '✅ Resumen recibido: ${data['alerts_summary']?.length ?? 0} tipos de alertas',
        );
        final summary = DashboardSummary.fromJson(data);
        print(
          '✅ DashboardSummary creado con ${summary.alertsSummary.length} alertas',
        );
        return summary;
      } else {
        print('❌ Error API resumen: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Excepción API resumen: $e');
    }
    return null;
  }

  Future<GasChartData?> getGasChartData({int hours = 24}) async {
    try {
      print('🔄 Solicitando datos de gas...');
      final response = await http
          .get(
            Uri.parse('$baseUrl/charts/gas?hours=$hours'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(
          '✅ Datos de gas recibidos: ${data['gas_by_hour']?.length ?? 0} puntos',
        );
        final gasData = GasChartData.fromJson(data);
        print('✅ GasChartData creado con ${gasData.data.length} puntos');
        return gasData;
      } else {
        print('❌ Error API gas: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Excepción API gas: $e');
    }
    return null;
  }

  Future<SeismicChartData?> getSeismicChartData({int hours = 24}) async {
    try {
      print('🔄 Solicitando datos sísmicos...');
      final response = await http
          .get(
            Uri.parse('$baseUrl/charts/seismic?hours=$hours'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(
          '✅ Datos sísmicos recibidos: ${data['seismic_by_hour']?.length ?? 0} puntos',
        );
        final seismicData = SeismicChartData.fromJson(data);
        print(
          '✅ SeismicChartData creado con ${seismicData.data.length} puntos',
        );
        return seismicData;
      } else {
        print('❌ Error API sísmico: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Excepción API sísmico: $e');
    }
    return null;
  }

  // Método comentado - no se usa el estado de transporte
  // Future<List<DetailedBusStatus>?> getBusesStatus() async {
  //   try {
  //     final response = await http
  //         .get(
  //           Uri.parse('$baseUrl/buses/status'),
  //           headers: {'Content-Type': 'application/json'},
  //         )
  //         .timeout(timeout);

  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body) as List;
  //       return data.map((e) => DetailedBusStatus.fromJson(e)).toList();
  //     }
  //   } catch (e) {
  //     // Error silencioso para producción
  //   }
  //   return null;
  // }

  Future<DashboardMetrics?> getMetrics() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/metrics'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DashboardMetrics.fromJson(data);
      }
    } catch (e) {
      // Error silencioso para producción
    }
    return null;
  }

  Future<Map<String, dynamic>?> getHourlyStats({int hours = 24}) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/stats/hourly?hours=$hours'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      // Error silencioso para producción
    }
    return null;
  }
}
