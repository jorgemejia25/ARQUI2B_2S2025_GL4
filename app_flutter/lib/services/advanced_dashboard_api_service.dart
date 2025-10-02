import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../widgets/dashboard_filters.dart';

/// Servicio API avanzado para el dashboard con filtros
class AdvancedDashboardApiService {
  static const Duration timeout = ApiConfig.defaultTimeout;

  // Singleton
  static final AdvancedDashboardApiService _instance =
      AdvancedDashboardApiService._internal();
  factory AdvancedDashboardApiService() => _instance;
  AdvancedDashboardApiService._internal();

  /// Obtener análisis avanzado con filtros
  Future<Map<String, dynamic>?> getAdvancedAnalytics({
    DashboardFilters? filters,
  }) async {
    try {
      final params = filters?.toQueryParams() ?? {};
      final uri = Uri.parse(
        '${ApiConfig.dashboardBaseUrl}/analytics/advanced',
      ).replace(queryParameters: params);

      final response = await http
          .get(uri, headers: ApiConfig.defaultHeaders)
          .timeout(timeout);

      if (response.statusCode == 200) {
        final result = json.decode(response.body) as Map<String, dynamic>;
        print('Advanced analytics response: $result');
        return result;
      } else {
        print(
          'Advanced analytics error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error getting advanced analytics: $e');
    }
    return null;
  }

  /// Obtener datos de línea de tiempo
  Future<Map<String, dynamic>?> getTimelineChart({
    DateTime? startDate,
    DateTime? endDate,
    String? eventType,
    String granularity = 'hour',
  }) async {
    try {
      final params = <String, String>{'granularity': granularity};

      if (startDate != null) {
        params['start_date'] = startDate.toIso8601String().split('T')[0];
      }

      if (endDate != null) {
        params['end_date'] = endDate.toIso8601String().split('T')[0];
      }

      if (eventType != null) {
        params['event_type'] = eventType;
      }

      final uri = Uri.parse(
        '${ApiConfig.dashboardBaseUrl}/charts/timeline',
      ).replace(queryParameters: params);

      final response = await http
          .get(uri, headers: ApiConfig.defaultHeaders)
          .timeout(timeout);

      if (response.statusCode == 200) {
        final result = json.decode(response.body) as Map<String, dynamic>;
        print('Timeline chart response: $result');
        return result;
      } else {
        print(
          'Timeline chart error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error getting timeline chart: $e');
    }
    return null;
  }

  /// Obtener datos de comparación
  Future<Map<String, dynamic>?> getComparisonChart({
    required String metric,
    DateTime? startDate,
    DateTime? endDate,
    String compareBy = 'type',
  }) async {
    try {
      final params = <String, String>{
        'metric': metric,
        'compare_by': compareBy,
      };

      if (startDate != null) {
        params['start_date'] = startDate.toIso8601String().split('T')[0];
      }

      if (endDate != null) {
        params['end_date'] = endDate.toIso8601String().split('T')[0];
      }

      final uri = Uri.parse(
        '${ApiConfig.dashboardBaseUrl}/charts/comparison',
      ).replace(queryParameters: params);

      final response = await http
          .get(uri, headers: ApiConfig.defaultHeaders)
          .timeout(timeout);

      if (response.statusCode == 200) {
        final result = json.decode(response.body) as Map<String, dynamic>;
        print('Comparison chart response: $result');
        return result;
      } else {
        print(
          'Comparison chart error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error getting comparison chart: $e');
    }
    return null;
  }

  /// Obtener stream de datos en tiempo real
  Future<Map<String, dynamic>?> getRealtimeStream({int minutes = 5}) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.dashboardBaseUrl}/realtime/stream',
      ).replace(queryParameters: {'minutes': minutes.toString()});

      final response = await http
          .get(uri, headers: ApiConfig.defaultHeaders)
          .timeout(timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error getting realtime stream: $e');
    }
    return null;
  }

  /// Obtener resumen del dashboard (compatible con API antigua)
  Future<Map<String, dynamic>?> getSummary() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.dashboardBaseUrl}/summary'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final result = json.decode(response.body) as Map<String, dynamic>;
        print('Summary response: $result');
        return result;
      } else {
        print('Summary error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error getting summary: $e');
    }
    return null;
  }

  /// Obtener métricas del dashboard
  Future<Map<String, dynamic>?> getMetrics() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.dashboardBaseUrl}/metrics'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error getting metrics: $e');
    }
    return null;
  }

  /// Obtener análisis de gas
  Future<Map<String, dynamic>?> getGasAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final params = <String, String>{};

      if (startDate != null) {
        params['start_date'] = startDate.toIso8601String().split('T')[0];
      }

      if (endDate != null) {
        params['end_date'] = endDate.toIso8601String().split('T')[0];
      }

      final uri = Uri.parse(
        '${ApiConfig.dashboardBaseUrl}/analytics/gas',
      ).replace(queryParameters: params);

      final response = await http
          .get(uri, headers: ApiConfig.defaultHeaders)
          .timeout(timeout);

      if (response.statusCode == 200) {
        final result = json.decode(response.body) as Map<String, dynamic>;
        print('Gas analytics response: $result');
        return result;
      } else {
        print('Gas analytics error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error getting gas analytics: $e');
    }
    return null;
  }

  /// Obtener análisis sísmico
  Future<Map<String, dynamic>?> getSeismicAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final params = <String, String>{};

      if (startDate != null) {
        params['start_date'] = startDate.toIso8601String().split('T')[0];
      }

      if (endDate != null) {
        params['end_date'] = endDate.toIso8601String().split('T')[0];
      }

      final uri = Uri.parse(
        '${ApiConfig.dashboardBaseUrl}/analytics/seismic',
      ).replace(queryParameters: params);

      final response = await http
          .get(uri, headers: ApiConfig.defaultHeaders)
          .timeout(timeout);

      if (response.statusCode == 200) {
        final result = json.decode(response.body) as Map<String, dynamic>;
        print('Seismic analytics response: $result');
        return result;
      } else {
        print(
          'Seismic analytics error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error getting seismic analytics: $e');
    }
    return null;
  }

  /// Obtener métricas de salud del sistema
  Future<Map<String, dynamic>?> getSystemHealthMetrics() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.dashboardBaseUrl}/system/health'),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final result = json.decode(response.body) as Map<String, dynamic>;
        print('System health response: $result');
        return result;
      } else {
        print('System health error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error getting system health metrics: $e');
    }
    return null;
  }
}
