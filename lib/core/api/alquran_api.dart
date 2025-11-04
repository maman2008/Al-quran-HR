import 'dart:convert';
import 'package:http/http.dart' as http;

class AlQuranApi {
  static const String baseUrl = 'https://api.alquran.cloud/v1';

  final http.Client _client;
  AlQuranApi({http.Client? client}) : _client = client ?? http.Client();

  Future<List<dynamic>> fetchSurahList() async {
    final uri = Uri.parse('$baseUrl/surah');
    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Gagal memuat daftar surah (${res.statusCode})');
    }
    final data = json.decode(res.body) as Map<String, dynamic>;
    return (data['data'] as List<dynamic>);
  }

  // Get a surah with a specific edition
  Future<Map<String, dynamic>> fetchSurahEdition(int surahNumber, String edition) async {
    final uri = Uri.parse('$baseUrl/surah/$surahNumber/$edition');
    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Gagal memuat surah $surahNumber ($edition)');
    }
    final data = json.decode(res.body) as Map<String, dynamic>;
    return data['data'] as Map<String, dynamic>;
  }

  // List all Arabic audio editions (Qari)
  Future<List<dynamic>> fetchAudioEditions() async {
    // Fetch all audio editions (no language restriction) to show a wider set of Qari
    final uri = Uri.parse('$baseUrl/edition?type=audio');
    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Gagal memuat daftar Qari (${res.statusCode})');
    }
    final data = json.decode(res.body) as Map<String, dynamic>;
    return data['data'] as List<dynamic>;
  }

  // Get a Juz with a specific edition
  Future<Map<String, dynamic>> fetchJuzEdition(int juzNumber, String edition) async {
    final uri = Uri.parse('$baseUrl/juz/$juzNumber/$edition');
    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Gagal memuat Juz $juzNumber ($edition)');
    }
    final data = json.decode(res.body) as Map<String, dynamic>;
    return data['data'] as Map<String, dynamic>;
  }
}
