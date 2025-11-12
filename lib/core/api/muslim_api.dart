import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class MuslimApi {
  static const String host = 'https://muslim-api-three.vercel.app';
  static const String _hostEq = 'https://equran.id';
  final http.Client _client;

  MuslimApi({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Map<String, dynamic>>> getDoa({String? source}) async {
    final uri = Uri.parse(
      (source == null || source.isEmpty)
          ? '$host/v1/doa'
          : '$host/v1/doa?source=${Uri.encodeQueryComponent(source)}',
    );
    final res = await _getWithFallback(uri);
    _ensureOk(res, 'Gagal memuat daftar doa');
    final body = _decode(res.body);
    return _extractList(body);
  }

  Future<List<Map<String, dynamic>>> _getDoaMuslimAlt({String? source}) async {
    final paths = <String>[
      '/v1/doa',
      '/doa',
      '/api/doa',
    ];
    for (final p in paths) {
      final base = Uri.parse('$host$p');
      final uri = (source == null || source.isEmpty)
          ? base
          : base.replace(queryParameters: {
              if (p == '/v1/doa') 'source': source,
              if (p != '/v1/doa') 'source': source, // keep same param just in case
            });
      try {
        final res = await _getWithFallback(uri);
        if (res.statusCode != 200) continue;
        final body = _decode(res.body);
        final list = _extractList(body);
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }
    return const <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> searchDoa(String query) async {
    final uri = Uri.parse('$host/v1/doa/find?query=${Uri.encodeQueryComponent(query)}');
    final res = await _getWithFallback(uri);
    _ensureOk(res, 'Gagal mencari doa');
    final body = _decode(res.body);
    return _extractList(body);
  }

  // Combined, more-complete fetch merging muslim-api with EQuran.id
  Future<List<Map<String, dynamic>>> getDoaComplete({String? sourceOrGrup}) async {
    // 1) Prioritize EQuran (more lengkap), respect grup if provided
    final eq = await _safe(() => _getDoaEq(grup: sourceOrGrup));
    if (eq.isNotEmpty) return eq;

    // 2) If filtered EQuran empty, try EQuran tanpa filter
    final eqAll = await _safe(() => _getDoaEq());

    // 3) Get Muslim API (primary + alternates)
    final a = await _safe(() => getDoa(source: sourceOrGrup));
    final aa = a.isNotEmpty ? a : await _safe(() => _getDoaMuslimAlt(source: sourceOrGrup));

    // 4) Merge any available
    final merged = _mergeDoaLists(eqAll, aa);
    if (merged.isNotEmpty) return merged;

    // 5) Last resort: return whichever is non-empty (could be empty)
    return eqAll.isNotEmpty ? eqAll : aa;
  }

  Future<List<Map<String, dynamic>>> searchDoaComplete(String query) async {
    final a = await _safe(() => searchDoa(query));
    final b = await _safe(() => _searchDoaEq(query));
    final merged = _mergeDoaLists(a, b);
    if (merged.isNotEmpty) return merged;
    // last resort: local filter over combined base
    final base = await getDoaComplete();
    final qq = query.toLowerCase();
    return base.where((m) {
      final t = (m['title'] ?? m['judul'] ?? m['name'] ?? '').toString().toLowerCase();
      final id = (m['translation'] ?? m['terjemah'] ?? m['terjemahan'] ?? m['indo'] ?? m['id'] ?? '').toString().toLowerCase();
      final tags = (m['tags'] is List) ? (m['tags'] as List).map((e) => e.toString().toLowerCase()) : const <String>[];
      return t.contains(qq) || id.contains(qq) || tags.contains(qq);
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _getDoaEq({String? grup}) async {
    final base = Uri.parse('$_hostEq/api/doa');
    final uri = (grup == null || grup.isEmpty) ? base : base.replace(queryParameters: {'grup': grup});
    final res = await _getWithFallback(uri);
    _ensureOk(res, 'Gagal memuat doa (EQ)');
    final body = _decode(res.body);
    return _normalizeList(_extractList(body));
  }

  Future<List<Map<String, dynamic>>> _searchDoaEq(String query) async {
    final uri = Uri.parse('$_hostEq/api/doa?tag=${Uri.encodeQueryComponent(query)}');
    final res = await _getWithFallback(uri);
    if (res.statusCode != 200) return const <Map<String, dynamic>>[];
    final body = _decode(res.body);
    return _normalizeList(_extractList(body));
  }

  Future<http.Response> _getWithFallback(Uri uri) async {
    // Primary attempt with timeout
    try {
      return await _client.get(uri, headers: _headers()).timeout(const Duration(seconds: 12));
    } catch (_) {
      // continue to fallbacks
    }

    // On mobile/desktop just retry once with timeout
    if (!kIsWeb) {
      return await _client.get(uri, headers: _headers()).timeout(const Duration(seconds: 12));
    }

    // Web: try CORS-friendly mirrors
    final full = uri.toString();
    final candidates = <Uri>[
      Uri.parse('https://r.jina.ai/$full'),
      Uri.parse('https://api.allorigins.win/raw?url=${Uri.encodeComponent(full)}'),
      Uri.parse('https://cors.isomorphic-git.org/$full'),
    ];
    for (final u in candidates) {
      try {
        final r = await _client.get(u, headers: _headers()).timeout(const Duration(seconds: 12));
        if (r.statusCode == 200) return r;
      } catch (_) {}
    }

    // Last try original again
    return await _client.get(uri, headers: _headers()).timeout(const Duration(seconds: 12));
  }

  Map<String, String> _headers() => const {
        'Accept': 'application/json, text/plain, */*',
        'Content-Type': 'application/json',
        'Accept-Language': 'id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7',
        'User-Agent': 'Mozilla/5.0 (Flutter; Dart) EQuranClient/1.0',
      };

  void _ensureOk(http.Response res, String msg) {
    if (res.statusCode != 200) {
      throw Exception('$msg (${res.statusCode})');
    }
  }

  dynamic _decode(String s) {
    try {
      return json.decode(s);
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> _extractList(dynamic body) {
    if (body is List) {
      return body.whereType<Map<String, dynamic>>().toList();
    }
    if (body is Map) {
      // direct list under common keys
      for (final k in const ['data', 'doa', 'result', 'items', 'list']) {
        final v = body[k];
        if (v is List) return v.whereType<Map<String, dynamic>>().toList();
      }
      // nested under data: {}
      final d = body['data'];
      if (d is Map) {
        for (final v in d.values) {
          if (v is List) return v.whereType<Map<String, dynamic>>().toList();
        }
      }
      // scan shallow values for any list of maps
      for (final v in body.values) {
        if (v is List) return v.whereType<Map<String, dynamic>>().toList();
      }
    }
    return <Map<String, dynamic>>[];
  }

  // merge and normalization helpers
  List<Map<String, dynamic>> _normalizeList(List<Map<String, dynamic>> list) {
    return list.map((m) => _normalizeDoaMap(m)).toList();
  }

  Map<String, dynamic> _normalizeDoaMap(Map<String, dynamic> m) {
    final normalized = Map<String, dynamic>.from(m);
    if (!normalized.containsKey('title')) {
      if (normalized.containsKey('judul')) normalized['title'] = normalized['judul'];
      else if (normalized.containsKey('name')) normalized['title'] = normalized['name'];
      else if (normalized.containsKey('nama')) normalized['title'] = normalized['nama'];
    }
    if (!normalized.containsKey('arabic')) {
      if (normalized.containsKey('arab')) normalized['arabic'] = normalized['arab'];
      else if (normalized.containsKey('ar')) normalized['arabic'] = normalized['ar'];
    }
    if (!normalized.containsKey('translation')) {
      if (normalized.containsKey('terjemah')) normalized['translation'] = normalized['terjemah'];
      else if (normalized.containsKey('terjemahan')) normalized['translation'] = normalized['terjemahan'];
      else if (normalized.containsKey('indo')) normalized['translation'] = normalized['indo'];
      else if (normalized.containsKey('idn')) normalized['translation'] = normalized['idn'];
    }
    if (!normalized.containsKey('tags') && normalized.containsKey('tag') && normalized['tag'] is List) {
      normalized['tags'] = normalized['tag'];
    }
    return normalized;
  }

  List<Map<String, dynamic>> _mergeDoaLists(List<Map<String, dynamic>> a, List<Map<String, dynamic>> b) {
    final map = <String, Map<String, dynamic>>{};
    for (final m in _normalizeList(a)) {
      final key = (m['title'] ?? m['judul'] ?? m['name'] ?? '').toString().toLowerCase().trim();
      if (key.isEmpty) continue;
      map[key] = m;
    }
    for (final m in _normalizeList(b)) {
      final key = (m['title'] ?? m['judul'] ?? m['name'] ?? '').toString().toLowerCase().trim();
      if (key.isEmpty) continue;
      if (map.containsKey(key)) {
        // prefer the one that has arabic and translation
        final cur = map[key]!;
        final hasArab = (cur['arabic'] ?? cur['arab'] ?? '').toString().isNotEmpty;
        final hasIndo = (cur['translation'] ?? cur['terjemah'] ?? cur['terjemahan'] ?? cur['indo'] ?? '').toString().isNotEmpty;
        final nHasArab = (m['arabic'] ?? m['arab'] ?? '').toString().isNotEmpty;
        final nHasIndo = (m['translation'] ?? m['terjemah'] ?? m['terjemahan'] ?? m['indo'] ?? '').toString().isNotEmpty;
        if ((!hasArab && nHasArab) || (!hasIndo && nHasIndo)) {
          map[key] = {...cur, ...m};
        }
      } else {
        map[key] = m;
      }
    }
    return map.values.toList();
  }

  Future<List<Map<String, dynamic>>> _safe(Future<List<Map<String, dynamic>>> Function() f) async {
    try {
      return await f();
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }
}
