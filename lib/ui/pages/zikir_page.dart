import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class ZikirPage extends StatefulWidget {
  const ZikirPage({super.key});

  @override
  State<ZikirPage> createState() => _ZikirPageState();
}

class _ZikirPageState extends State<ZikirPage> with SingleTickerProviderStateMixin {
  bool _loading = false;
  String? _error;
  List<_ZikirItem> _items = [];
  final Map<int, List<_ZikirItem>> _cache = {};
  bool _usingFallback = false;
  static const Map<String, List<String>> _sources = {
    'Dzikir Pagi': [
      'https://dzikir.zakiego.com/api/v0/dzikir-pagi',
      'https://dzikir.vercel.app/api/v0/dzikir-pagi',
    ],
    'Dzikir Sore': [
      'https://dzikir.zakiego.com/api/v0/dzikir-sore',
      'https://dzikir.vercel.app/api/v0/dzikir-sore',
    ],
    'Setelah Shalat': [
      'https://dzikir.zakiego.com/api/v0/setelah-shalat',
      'https://dzikir.vercel.app/api/v0/setelah-shalat',
      'https://dzikir.zakiego.com/api/v0/dzikir-setelah-shalat',
      'https://dzikir.vercel.app/api/v0/dzikir-setelah-shalat',
    ],
  };
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _sources.length, vsync: this);
    _tab.addListener(() {
      if (_tab.indexIsChanging) return;
      final cached = _cache[_tab.index];
      if (cached != null) {
        setState(() { _items = cached; _error = null; _loading = false; });
      } else {
        _fetch();
      }
    });
    // initial load for first tab
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  List<String> _currentEndpoints() {
    final key = _sources.keys.elementAt(_tab.index);
    return _sources[key]!;
  }

  String _currentTitle() => _sources.keys.elementAt(_tab.index);

  Future<void> _fetch() async {
    final baseUrls = _currentEndpoints();
    setState(() { _loading = true; _error = null; _items = []; });
    String? lastErr;
    _usingFallback = false;
    for (final base in baseUrls) {
      final candidates = _candidateUrls(base);
      for (final u in candidates) {
        try {
          final res = await http.get(Uri.parse(u)).timeout(const Duration(seconds: 12));
          if (res.statusCode != 200) { lastErr = 'HTTP ${res.statusCode}'; continue; }
          final body = res.body.trim();
          final data = json.decode(body);
          final parsed = _parseData(data);
          if (!mounted) return;
          setState(() => _items = parsed.isEmpty ? [
            _ZikirItem('Info', 'Tidak ada data yang bisa ditampilkan dari API ini.'),
          ] : parsed);
          _cache[_tab.index] = _items;
          lastErr = null;
          break;
        } on TimeoutException catch (_) {
          lastErr = 'Timeout saat mengambil data';
        } catch (e) {
          lastErr = e.toString();
        }
      }
      if (lastErr == null) break;
    }
    if (mounted) {
      if (lastErr != null) {
        final fb = _localFallback(_tab.index);
        if (fb.isNotEmpty) {
          setState(() { _items = fb; _error = null; _usingFallback = true; });
          _cache[_tab.index] = _items;
        } else {
          setState(() => _error = 'Gagal memuat data: $lastErr');
        }
      }
      setState(() => _loading = false);
    }
  }

  List<String> _candidateUrls(String url) {
    if (!kIsWeb) return [url];
    final encoded = Uri.encodeComponent(url);
    return [
      'https://api.allorigins.win/raw?url=$encoded',
      'https://cors.isomorphic-git.org/$url',
      'https://thingproxy.freeboard.io/fetch/$url',
      // Readable proxy that returns raw body text; robust for many hosts
      'https://r.jina.ai/http://$url',
      'https://r.jina.ai/https://$url',
      url,
    ];
  }

  List<_ZikirItem> _localFallback(int tabIndex) {
    final key = _sources.keys.elementAt(tabIndex);
    if (key.contains('Pagi')) {
      return [
        _ZikirItem('Sayyidul Istighfar', 'اللَّهُمَّ أَنْتَ رَبِّي لاَ إِلَهَ إِلاَّ أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ لَكَ بِذَنْبِي، فَاغْفِرْ لِي، فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ.'),
        _ZikirItem('Ayat Kursi', 'اللّهُ لاَ إِلَهَ إِلاَّ هُوَ الْحَيُّ الْقَيُّومُ ... (QS. Al-Baqarah: 255)'),
        _ZikirItem('Al-Ikhlas • 3x', 'قُلْ هُوَ اللَّهُ أَحَدٌ ... (3x)'),
        _ZikirItem('Al-Falaq • 3x', 'قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ... (3x)'),
        _ZikirItem('An-Nas • 3x', 'قُلْ أَعُوذُ بِرَبِّ النَّاسِ ... (3x)'),
        _ZikirItem('Doa Perlindungan Pagi (3x)', 'بِسْمِ اللّٰهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ\n\nBismillāhillazī lā yaḍurru ma‘asmihi syai’un fil-arḍi walā fis-samā’i wa huwa as-samī‘ul-‘alīm (3x)'),
        _ZikirItem('Tasbih 33x, Tahmid 33x, Takbir 34x', 'Subhanallah (33x)\n\nAlhamdulillah (33x)\n\nAllahu Akbar (34x)'),
      ];
    } else if (key.contains('Sore')) {
      return [
        _ZikirItem('Sayyidul Istighfar', 'اللَّهُمَّ أَنْتَ رَبِّي لاَ إِلَهَ إِلاَّ أَنْتَ ...\n\nYa Allah, Engkau Rabbku, tiada ilah selain Engkau ...'),
      ];
    } else {
      // Setelah Shalat
      return [
        _ZikirItem('Istighfar 3x', 'أَسْتَغْفِرُ اللّٰهَ\n\nAstaghfirullah (3x)'),
        _ZikirItem('Tasbih 33x, Tahmid 33x, Takbir 34x', 'سُبْحَانَ اللّٰهِ (33x)\n\nالْحَمْدُ لِلّٰهِ (33x)\n\nاللّٰهُ أَكْبَرُ (34x)\n\nSubhanallah (33x)\n\nAlhamdulillah (33x)\n\nAllahu Akbar (34x)'),
        _ZikirItem('Tahlil setelah tasbih', 'لاَ إِلَهَ إِلاَّ اللّٰهُ وَحْدَهُ لَا شَرِيْكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيْرٌ\n\nLa ilaha illallah wahdahu la syarika lah, lahul mulku walahul hamdu wahuwa ala kulli syaiin qadir'),
        _ZikirItem('Ayat Kursi', 'اللّهُ لاَ إِلَهَ إِلاَّ هُوَ الْحَيُّ الْقَيُّومُ ...'),
        _ZikirItem('Tasbih, Tahmid, Takbir masing-masing 10x (alternatif)', 'Subhanallah (10x)\n\nAlhamdulillah (10x)\n\nAllahu Akbar (10x)'),
        _ZikirItem('Doa selesai shalat', 'اللَّهُمَّ أَنْتَ السَّلاَمُ وَمِنْكَ السَّلاَمُ تَبَارَكْتَ يَا ذَا الْجَلاَلِ وَالإِكْرَامِ\n\nAllahumma antas-salaam wa minkas-salaam tabaarakta yaa dzal jalaali wal ikraam'),
      ];
    }
  }

  List<_ZikirItem> _parseData(dynamic data) {
    final list = <_ZikirItem>[];
    if (data is List) {
      for (final e in data) {
        if (e is Map<String, dynamic>) {
          final title = (e['title'] ?? e['name'] ?? e['judul'] ?? '').toString();
          final content = _composeContent(e);
          if (title.isNotEmpty || content.isNotEmpty) list.add(_ZikirItem(title, content));
        } else if (e is String) {
          final s = e.trim();
          final looksLikeUrl = s.startsWith('http://') || s.startsWith('https://');
          if (!looksLikeUrl && s.isNotEmpty) list.add(_ZikirItem('', s));
        }
      }
    } else if (data is Map<String, dynamic>) {
      final items = data['data'] ?? data['items'] ?? data['zikir'] ?? data['results'];
      if (items is List) return _parseData(items);
    }
    return list;
  }

  String _composeContent(Map<String, dynamic> e) {
    final parts = <String>[];
    String pick(List<String> keys) {
      for (final k in keys) {
        final v = e[k];
        if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
      }
      return '';
    }
    final arab = pick(['arab', 'arabic', 'arab_text']);
    final latin = pick(['latin', 'transliteration', 'lafadz_latin']);
    final indo = pick(['translation', 'terjemah', 'terjemahan', 'id', 'indo']);
    final zikir = pick(['zikir', 'dzikir', 'content', 'text']);

    if (zikir.isNotEmpty) parts.add(zikir);
    if (arab.isNotEmpty) parts.add(arab);
    if (latin.isNotEmpty) parts.add(latin);
    if (indo.isNotEmpty) parts.add(indo);

    return parts.join('\n\n');
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    
    final primaryColor = const Color(0xFF10B981);
    final backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC);
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final onSurfaceColor = isDark ? Colors.white : const Color(0xFF1E293B);
    
    return Theme(
      data: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: brightness,
          background: backgroundColor,
          surface: surfaceColor,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text(
            'Zikir',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              letterSpacing: .2,
              color: onSurfaceColor,
            ),
          ),
          centerTitle: true,
          backgroundColor: surfaceColor,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _fetch,
                icon: Icon(Icons.refresh_rounded, color: primaryColor),
                tooltip: 'Muat Ulang',
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tab,
                  isScrollable: false,
                  dividerColor: Colors.transparent,
                  splashFactory: NoSplash.splashFactory,
                  overlayColor: MaterialStateProperty.all(Colors.transparent),
                  labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: onSurfaceColor.withOpacity(0.6),
                  indicator: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: [
                    for (final k in _sources.keys)
                      Tab(
                        text: k.replaceAll('Dzikir ', ''),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: RefreshIndicator(
          color: primaryColor,
          backgroundColor: surfaceColor,
          onRefresh: _fetch,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              // Header dengan gradient
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withOpacity(0.1),
                      primaryColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.lightbulb_outline_rounded,
                            color: primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _currentTitle(),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                              color: onSurfaceColor,
                              letterSpacing: .2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bacaan zikir untuk ${_currentTitle().toLowerCase()} sesuai sunnah',
                      style: GoogleFonts.poppins(
                        color: onSurfaceColor.withOpacity(0.7),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 20, color: const Color(0xFFDC2626)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFDC2626),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_usingFallback)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.wifi_off_rounded,
                          size: 20, color: primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Menampilkan data lokal. Beberapa konten mungkin ringkas.',
                          style: GoogleFonts.poppins(
                            color: primaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_loading)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          backgroundColor: surfaceColor.withOpacity(.5),
                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Memuat zikir...',
                        style: GoogleFonts.poppins(
                          color: onSurfaceColor.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

              // List zikir items
              if (_items.isNotEmpty)
                ..._items.asMap().entries.map((entry) => 
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: _buildZikirCard(entry, primaryColor, surfaceColor, onSurfaceColor),
                  )
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZikirCard(
    MapEntry<int, _ZikirItem> entry, 
    Color primaryColor, 
    Color surfaceColor, 
    Color onSurfaceColor,
  ) {
    return Card(
      elevation: 0,
      color: surfaceColor,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan nomor
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.03),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(
                bottom: BorderSide(
                  color: primaryColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${entry.key + 1}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: (entry.value.title.isNotEmpty)
                      ? Text(
                          entry.value.title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            letterSpacing: .2,
                            color: onSurfaceColor,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          // Konten
          if (entry.value.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildParagraphs(entry.value.content, onSurfaceColor),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildParagraphs(String content, Color onSurfaceColor) {
    final parts = content.split('\n\n').where((e) => e.trim().isNotEmpty).toList();
    final onSurface = onSurfaceColor;
    TextStyle base = GoogleFonts.poppins(
      fontSize: 15.5,
      height: 1.7,
      color: onSurface.withOpacity(0.9),
    );
    TextStyle arab = GoogleFonts.notoNaskhArabic(
      fontSize: 22,
      height: 1.9,
      fontWeight: FontWeight.w600,
      color: onSurface,
    );
    bool isArabic(String s) => RegExp(r"[\u0600-\u06FF]").hasMatch(s);
    
    return [
      for (final p in parts)
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: SelectableText(
            p,
            textAlign: isArabic(p) ? TextAlign.right : TextAlign.start,
            style: isArabic(p) ? arab : base,
          ),
        ),
    ];
  }
}

class _ZikirItem {
  final String title;
  final String content;
  _ZikirItem(this.title, this.content);
}