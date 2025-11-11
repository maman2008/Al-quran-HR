import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class MuslimApi {
  static const String host = 'https://muslim-api-three.vercel.app';
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

  Future<List<Map<String, dynamic>>> searchDoa(String query) async {
    final uri = Uri.parse('$host/v1/doa/find?query=${Uri.encodeQueryComponent(query)}');
    final res = await _getWithFallback(uri);
    _ensureOk(res, 'Gagal mencari doa');
    final body = _decode(res.body);
    return _extractList(body);
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
      Uri.parse('https://r.jina.ai/https://$host${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}'),
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
        'Accept': 'application/json',
        'Content-Type': 'application/json',
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
    if (body is Map && body['data'] is List) {
      return (body['data'] as List).whereType<Map<String, dynamic>>().toList();
    }
    return <Map<String, dynamic>>[];
  }
}
