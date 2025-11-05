import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ZikirPage extends StatefulWidget {
  const ZikirPage({super.key});

  @override
  State<ZikirPage> createState() => _ZikirPageState();
}

class _ZikirPageState extends State<ZikirPage> {
  static const String defaultEndpoint = 'https://muslim-api-three.vercel.app/api/zikir';
  String? _endpoint;
  bool _loading = false;
  String? _error;
  List<_ZikirItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadEndpoint();
  }

  Future<void> _loadEndpoint() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('zikir_endpoint');
    if (!mounted) return;
    final effective = (url == null || url.isEmpty) ? defaultEndpoint : url;
    setState(() => _endpoint = effective);
    await _saveEndpoint(effective);
    await _fetch();
  }

  Future<void> _saveEndpoint(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('zikir_endpoint', url);
    setState(() => _endpoint = url);
  }

  Future<void> _askEndpoint() async {
    final controller = TextEditingController(text: _endpoint ?? '');
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Atur Endpoint Zikir'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'https://example.com/api/zikir'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Simpan')),
        ],
      ),
    );
    if (url != null && url.isNotEmpty) {
      await _saveEndpoint(url);
      await _fetch();
    }
  }

  Future<void> _fetch() async {
    final url = _endpoint;
    if (url == null || url.isEmpty) {
      setState(() => _error = 'Endpoint belum diatur');
      return;
    }
    setState(() { _loading = true; _error = null; _items = []; });
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final data = json.decode(res.body);
      final parsed = _parseData(data);
      setState(() => _items = parsed.isEmpty ? [
        _ZikirItem('Info', 'Tidak ada data yang bisa ditampilkan dari API ini.'),
      ] : parsed);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<_ZikirItem> _parseData(dynamic data) {
    final list = <_ZikirItem>[];
    if (data is List) {
      for (final e in data) {
        if (e is Map<String, dynamic>) {
          final title = (e['title'] ?? e['name'] ?? '').toString();
          final content = (e['content'] ?? e['text'] ?? e['zikir'] ?? '').toString();
          if (title.isNotEmpty || content.isNotEmpty) list.add(_ZikirItem(title, content));
        } else if (e is String) {
          list.add(_ZikirItem('', e));
        }
      }
    } else if (data is Map<String, dynamic>) {
      final items = data['data'] ?? data['items'] ?? data['zikir'] ?? data['results'];
      if (items is List) return _parseData(items);
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Zikir', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(onPressed: _askEndpoint, icon: const Icon(Icons.settings_input_component_rounded), tooltip: 'Atur Endpoint'),
          IconButton(onPressed: _fetch, icon: const Icon(Icons.refresh_rounded), tooltip: 'Muat Ulang'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if ((_endpoint ?? '').isEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.link_rounded),
                  title: const Text('Endpoint belum diatur'),
                  subtitle: const Text('Ketuk untuk memasukkan URL API Zikir'),
                  onTap: _askEndpoint,
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            if (_loading) const LinearProgressIndicator(minHeight: 3),
            const SizedBox(height: 8),
            for (final it in _items)
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (it.title.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(it.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                        ),
                      Text(it.content),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _askEndpoint,
        icon: const Icon(Icons.tune_rounded),
        label: const Text('Atur API'),
      ),
    );
  }
}

class _ZikirItem {
  final String title;
  final String content;
  _ZikirItem(this.title, this.content);
}
