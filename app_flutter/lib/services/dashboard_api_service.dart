import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dashboard_models.dart';
import '../config/api_config.dart';

class DashboardApiService {
  static const Duration timeout = ApiConfig.defaultTimeout;

  // Singleton
  static final DashboardApiService _instance = DashboardApiService._internal();
  factory DashboardApiService() => _instance;
  DashboardApiService._internal();

  Future<DashboardSummary?> getSummary({
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final uri = _buildUriWithParams(
        ApiConfig.dashboardSummaryUrl,
        queryParams,
      );
      final response = await http
          .get(uri, headers: ApiConfig.defaultHeaders)
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DashboardSummary.fromJson(data);
      }
    } catch (e) {
      // Error silencioso para producción
    }
    return null;
  }

  Future<GasChartData?> getGasChartData({
    int hours = 24,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final params = <String, dynamic>{'hours': hours};
      if (queryParams != null) params.addAll(queryParams);

      final uri = _buildUriWithParams(ApiConfig.dashboardGasChartUrl, params);
      final response = await http
          .get(uri, headers: ApiConfig.defaultHeaders)
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return GasChartData.fromJson(data);
      }
    } catch (e) {
      // Error silencioso para producción
    }
    return null;
  }

  Future<SeismicChartData?> getSeismicChartData({
    int hours = 24,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final params = <String, dynamic>{'hours': hours};
      if (queryParams != null) params.addAll(queryParams);

      final uri = _buildUriWithParams(
        ApiConfig.dashboardSeismicChartUrl,
        params,
      );
      final response = await http
          .get(uri, headers: ApiConfig.defaultHeaders)
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SeismicChartData.fromJson(data);
      }
    } catch (e) {
      // Error silencioso para producción
    }
    return null;
  }

  Future<DashboardMetrics?> getMetrics({
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final uri = _buildUriWithParams(
        ApiConfig.dashboardMetricsUrl,
        queryParams,
      );
      final response = await http
          .get(uri, headers: ApiConfig.defaultHeaders)
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
            Uri.parse('${ApiConfig.dashboardHourlyStatsUrl}?hours=$hours'),
            headers: ApiConfig.defaultHeaders,
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

  /// Construye una URI con parámetros de consulta
  Uri _buildUriWithParams(String baseUrl, Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) {
      return Uri.parse(baseUrl);
    }

    final uri = Uri.parse(baseUrl);
    return uri.replace(
      queryParameters: params.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }
}
