import 'dart:convert';
import 'package:http/http.dart' as http;

class MyQuranApi {
  static const String baseUrl = 'https://api.myquran.com/v2/sholat';
  final http.Client _client;
  MyQuranApi({http.Client? client}) : _client = client ?? http.Client();

  Future<List<MyQCity>> fetchCities() async {
    final uri = Uri.parse('$baseUrl/kota/semua');
    http.Response res;
    int attempts = 0;
    while (true) {
      attempts++;
      try {
        res = await _client.get(uri, headers: const {'User-Agent': 'alquran_hr/1.0'}).timeout(const Duration(seconds: 10));
        break;
      } catch (e) {
        if (attempts >= 3) rethrow;
        await Future.delayed(Duration(milliseconds: 300 * attempts));
      }
    }
    if (res.statusCode != 200) {
      throw Exception('Gagal memuat daftar kota (${res.statusCode})');
    }
    final data = json.decode(res.body);
    final list = (data is Map<String, dynamic>) ? data['data'] : data;
    if (list is! List) return [];
    return list.map((e) => MyQCity.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<MyQMonthlySchedule> fetchMonthlySchedule({
    required String cityCode,
    required int year,
    required int month,
  }) async {
    final uri = Uri.parse('$baseUrl/jadwal/$cityCode/$year/${month.toString().padLeft(2, '0')}');
    http.Response res;
    int attempts = 0;
    while (true) {
      attempts++;
      try {
        res = await _client.get(uri, headers: const {'User-Agent': 'alquran_hr/1.0'}).timeout(const Duration(seconds: 10));
        break;
      } catch (e) {
        if (attempts >= 3) rethrow;
        await Future.delayed(Duration(milliseconds: 300 * attempts));
      }
    }
    if (res.statusCode != 200) {
      throw Exception('Gagal memuat jadwal sholat (${res.statusCode})');
    }
    final data = json.decode(res.body) as Map<String, dynamic>;
    final d = data['data'] as Map<String, dynamic>;
    final items = (d['jadwal'] as List).map((e) => MyQDay.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    return MyQMonthlySchedule(city: d['lokasi']?.toString() ?? '', items: items);
  }
}

class MyQCity {
  final String code;
  final String name;
  final String? province;
  MyQCity({required this.code, required this.name, this.province});
  factory MyQCity.fromJson(Map<String, dynamic> j) {
    final id = (j['id'] ?? j['kode'] ?? '').toString();
    final name = (j['lokasi'] ?? j['kota'] ?? j['nama'] ?? '').toString();
    final prov = (j['daerah'] ?? j['provinsi'])?.toString();
    return MyQCity(code: id, name: name, province: prov);
  }
}

class MyQDay {
  final DateTime date;
  final String imsak;
  final String subuh;
  final String terbit;
  final String dhuha;
  final String dzuhur;
  final String ashar;
  final String maghrib;
  final String isya;
  MyQDay({
    required this.date,
    required this.imsak,
    required this.subuh,
    required this.terbit,
    required this.dhuha,
    required this.dzuhur,
    required this.ashar,
    required this.maghrib,
    required this.isya,
  });
  factory MyQDay.fromJson(Map<String, dynamic> j) {
    // date format: '2023-10-31'
    final tgl = (j['date'] ?? j['tanggal'] ?? '').toString();
    final date = DateTime.tryParse(tgl) ?? DateTime.now();
    return MyQDay(
      date: date,
      imsak: (j['imsak'] ?? '').toString(),
      subuh: (j['subuh'] ?? j['shubuh'] ?? '').toString(),
      terbit: (j['terbit'] ?? '').toString(),
      dhuha: (j['dhuha'] ?? '').toString(),
      dzuhur: (j['dzuhur'] ?? '').toString(),
      ashar: (j['ashar'] ?? '').toString(),
      maghrib: (j['maghrib'] ?? '').toString(),
      isya: (j['isya'] ?? '').toString(),
    );
  }
}

class MyQMonthlySchedule {
  final String city;
  final List<MyQDay> items;
  MyQMonthlySchedule({required this.city, required this.items});
}
