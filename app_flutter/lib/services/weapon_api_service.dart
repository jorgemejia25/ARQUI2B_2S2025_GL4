import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/weapon_event.dart';
import '../models/weapon_count.dart';

class WeaponApiService {
  static final WeaponApiService _instance = WeaponApiService._internal();
  WeaponApiService._internal();
  factory WeaponApiService() => _instance;

  final String _apiBase = '${ApiConfig.baseUrl}${ApiConfig.apiV1Prefix}';

  Future<List<WeaponEvent>> fetchWeaponDetections({
    int limit = 50,
    int offset = 0,
    String? nameFilterEn, // English class name filter
  }) async {
    final params = {
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (nameFilterEn != null && nameFilterEn.isNotEmpty) 'weapon': nameFilterEn,
    };

    final uri = Uri.parse('$_apiBase/weapon-detections').replace(queryParameters: params);
    final response = await http
        .get(uri, headers: {'Content-Type': 'application/json'})
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body) as Map<String, dynamic>;
      final events = (jsonData['events'] as List)
          .map((e) => WeaponEvent.fromJson(e as Map<String, dynamic>))
          .toList();
      return events;
    } else {
      throw Exception('Error ${response.statusCode} fetching weapon detections');
    }
  }

  Future<List<WeaponCount>> fetchTopWeapons({int limit = 3}) async {
    final uri = Uri.parse('$_apiBase/top-weapons').replace(queryParameters: {
      'limit': limit.toString(),
    });
    final response = await http
        .get(uri, headers: {'Content-Type': 'application/json'})
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body) as Map<String, dynamic>;
      final list = (jsonData['top_weapons'] as List);

      // Note: top-weapons endpoint returns structured objects: {top, name, count}
      return list.asMap().entries.map((entry) {
        final item = entry.value as Map<String, dynamic>;
        return WeaponCount(
          top: item['top'] as int,
          nameEn: item['name'] as String,
          nameEs: item['name'] as String,
          count: (item['count'] as num).toInt(),
        );
      }).toList();
    } else {
      throw Exception('Error ${response.statusCode} fetching top weapons');
    }
  }
}