import 'dart:convert';
import 'package:http/http.dart' as http;

class AlAdhanApi {
  static const String baseUrl = 'https://api.aladhan.com/v1';
  final http.Client _client;
  AlAdhanApi({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> timingsByCity({
    required String city,
    required String country,
    int method = 5,
  }) async {
    final uri = Uri.parse('$baseUrl/timingsByCity?city=${Uri.encodeQueryComponent(city)}&country=${Uri.encodeQueryComponent(country)}&method=$method');
    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Gagal memuat jadwal sholat (${res.statusCode})');
    }
    final data = json.decode(res.body) as Map<String, dynamic>;
    if (data['code'] != 200) {
      throw Exception('API error: ${data['status']}');
    }
    return data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> qibla({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse('$baseUrl/qibla/$latitude/$longitude');
    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Gagal memuat arah kiblat (${res.statusCode})');
    }
    final data = json.decode(res.body) as Map<String, dynamic>;
    if (data['code'] != 200) {
      throw Exception('API error: ${data['status']}');
    }
    return data['data'] as Map<String, dynamic>;
  }
}
