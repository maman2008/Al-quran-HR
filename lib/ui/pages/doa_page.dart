import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/quran_providers.dart';

class DoaPage extends ConsumerStatefulWidget {
  const DoaPage({super.key});

  @override
  ConsumerState<DoaPage> createState() => _DoaPageState();
}

class _DoaPageState extends ConsumerState<DoaPage> {
  String _source = '';
  String _query = '';
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  Timer? _debounce;

  static const _sources = <String>['', 'quran', 'hadits', 'pilihan', 'harian', 'ibadah', 'haji', 'lainnya'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = ref.read(muslimApiProvider);
      List<Map<String, dynamic>> list;
      if (_query.isNotEmpty) {
        try {
          list = await api.searchDoaComplete(_query);
        } catch (_) {
          final base = await api.getDoaComplete(sourceOrGrup: _source.isEmpty ? null : _source);
          list = _filterLocal(base, _query);
        }
      } else {
        list = await api.getDoaComplete(sourceOrGrup: _source.isEmpty ? null : _source);
      }
      if (!mounted) return;
      setState(() { _items = list; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Gagal memuat doa. Periksa koneksi internet Anda.'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  void _setSource(String s) {
    if (_source == s) return;
    setState(() { _source = s; });
    _load();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() { _query = v.trim(); });
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF10B981);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Doa & Zikir',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: primary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primary),
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Box
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: _onSearch,
                    decoration: InputDecoration(
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(12),
                        child: Icon(Icons.search_rounded, color: primary),
                      ),
                      hintText: 'Cari doa atau zikir...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Filter Chips
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _sources.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final s = _sources[index];
                      final selected = _source == s;
                      final label = s.isEmpty ? 'Semua' : s[0].toUpperCase() + s.substring(1);
                      return GestureDetector(
                        onTap: () => _setSource(s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected ? primary : primary.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            label,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: selected ? Colors.white : primary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Loading Indicator
          if (_loading)
            LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: primary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(primary),
            ),

          // Error Message
          if (_error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: Colors.red[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: GoogleFonts.poppins(
                        color: Colors.red[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: _items.isEmpty && !_loading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          size: 64,
                          color: primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada data doa',
                          style: GoogleFonts.poppins(
                            color: primary.withOpacity(0.7),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Coba kata kunci lain atau filter berbeda',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: _items.length,
                    itemBuilder: (context, i) => _DoaCard(item: _items[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

List<Map<String, dynamic>> _filterLocal(List<Map<String, dynamic>> base, String q) {
  final qq = q.toLowerCase();
  return base.where((m) {
    final t = (m['title'] ?? m['judul'] ?? m['name'] ?? '').toString().toLowerCase();
    final id = (m['translation'] ?? m['terjemah'] ?? m['terjemahan'] ?? m['id'] ?? '').toString().toLowerCase();
    return t.contains(qq) || id.contains(qq);
  }).toList();
}

class _DoaCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _DoaCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF10B981);

    String title = (item['title'] ?? item['judul'] ?? item['name'] ?? '').toString();
    String arab = (item['arab'] ?? item['arabic'] ?? '').toString();
    String indo = (item['translation'] ?? item['terjemah'] ?? item['terjemahan'] ?? item['id'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            if (title.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: primary,
                  ),
                ),
              ),
            
            // Arabic Text
            if (arab.isNotEmpty)
              SelectableText(
                arab,
                textAlign: TextAlign.right,
                style: GoogleFonts.notoNaskhArabic(
                  fontSize: 20,
                  height: 1.8,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            if (arab.isNotEmpty) const SizedBox(height: 12),
            
            // Translation
            if (indo.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primary.withOpacity(0.1)),
                ),
                child: Text(
                  indo,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.6,
                    color: Colors.grey[800],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}