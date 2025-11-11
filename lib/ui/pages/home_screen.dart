import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/quran_providers.dart';
import '../widgets/surah_card.dart';
import 'surah_detail_page.dart';
import 'juz_detail_page.dart';
import '../widgets/qari_picker.dart';
import 'bookmark_page.dart';
import 'zikir_page.dart';
import 'notes_page.dart';
import 'prayer_times_page.dart';
import 'qibla_page.dart';
import 'doa_page.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahAsync = ref.watch(surahListProvider);
    final filtered = ref.watch(filteredSurahListProvider);
    final lastReadAsync = ref.watch(lastReadProvider);
    final bookmarksAsync = ref.watch(bookmarksProvider);

    final searchFocus = FocusNode();
    final w = MediaQuery.of(context).size.width;
    final compact = w < 360;
    // Revert background to previous constant color
    final bgColor = const Color(0xFFFAF8F0);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: compact ? 64 : 70,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              // Revert to original gradient
              gradient: const LinearGradient(
                colors: [Color(0xFF1A5D57), Color(0xFF0D2F2D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          title: Row(
            children: [
              Container(
                width: compact ? 34 : 40,
                height: compact ? 34 : 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                ),
                child: const Icon(Icons.mosque_rounded, color: Color(0xFFFAF8F0), size: 20),
              ),
              SizedBox(width: compact ? 8 : 12),
              Expanded(
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Al-Qur\'an HR', 
                    style: GoogleFonts.amiri(
                      fontWeight: FontWeight.w700, 
                      fontSize: compact ? 20 : 22, 
                      color: const Color(0xFFFAF8F0),
                      height: 1.1,
                    ),
                  ),
                  if (!compact)
                    Text('Baca • Dengar • Tadabbur',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: const Color(0xFFFAF8F0).withOpacity(0.85),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
              ),
            ],
          ),
          actions: [
            // Bookmark Button
            _AppBarIcon(
              icon: Icons.bookmark_rounded,
              tooltip: 'Bookmark',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BookmarkPage()),
              ),
            ),
            
            // Theme Toggle
            _AppBarIcon(
              icon: Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              tooltip: 'Mode Gelap/Terang',
              onPressed: () {
                final current = ref.read(themeModeProvider);
                final next = current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                ref.read(themeControllerProvider).set(next);
              },
            ),
            
            // Qari Picker
            _AppBarIcon(
              icon: Icons.record_voice_over_rounded,
              tooltip: 'Pilih Qari',
              onPressed: () => showQariPicker(context, ref),
            ),
            
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(compact ? 124 : 140),
            child: Column(
              children: [
                SizedBox(height: compact ? 12 : 16),
                // Search Bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 20),
                  child: Material(
                    elevation: 3,
                    shadowColor: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: compact ? 48 : 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE8E8E8)),
                      ),
                      child: TextField(
                        focusNode: searchFocus,
                        onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
                        style: GoogleFonts.poppins(fontSize: 15, color: const Color(0xFF1A5D57)),
                        decoration: InputDecoration(
                          hintText: 'Cari surah, ayat, atau topik...',
                          hintStyle: GoogleFonts.poppins(color: const Color(0xFF889396), fontSize: 14),
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            padding: EdgeInsets.all(compact ? 6 : 8),
                            child: Icon(Icons.search_rounded, size: compact ? 18 : 20, color: const Color(0xFF1A5D57)),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFF1A5D57), width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: compact ? 12 : 16),
                
                // Tab Bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 20),
                  child: Container(
                    height: compact ? 44 : 48,
                    decoration: BoxDecoration(
                      // Revert to previous opacity
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: TabBar(
                        isScrollable: false,
                        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: compact ? 13 : 14),
                        unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: compact ? 13 : 14),
                        labelColor: const Color(0xFF1A5D57),
                        // Revert to previous value
                        unselectedLabelColor: const Color(0xFFFAF8F0),
                        dividerColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: const Color(0xFFFAF8F0),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        tabs: const [
                          Tab(text: 'Surah'),
                          Tab(text: 'Juz'),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 10 : 12),
              ],
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: TabBarView(
            children: [
              // Surah Tab
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Last Read Section
                          lastReadAsync.when(
                            data: (lr) => lr == null
                                ? const SizedBox.shrink()
                                : _LastReadCard(
                                    surah: lr.surah,
                                    ayah: lr.ayah,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => SurahDetailPage(surahNumber: lr.surah)),
                                    ),
                                  ),
                            loading: () => _LastReadSkeleton(),
                            error: (e, _) => const SizedBox.shrink(),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Quick Actions
                         Text(
  'Akses Cepat',
  style: GoogleFonts.poppins(
    fontWeight: FontWeight.w700,
    fontSize: 18,
    color: const Color(0xFF1A5D57),
  ),
),
const SizedBox(height: 20),
Container(
  height: 100,
  child: ListView.separated(
    scrollDirection: Axis.horizontal,
    physics: const BouncingScrollPhysics(),
    padding: const EdgeInsets.symmetric(horizontal: 4),
    itemCount: 5,
    separatorBuilder: (_, __) => const SizedBox(width: 20),
    itemBuilder: (context, index) {
      final List<Map<String, dynamic>> quickActions = [
        {
          'icon': Icons.auto_awesome_rounded,
          'label': 'Zikir',
          'color': Color(0xFF1A5D57),
          'page': const ZikirPage(),
        },
        {
          'icon': Icons.handshake,
          'label': 'Doa', 
          'color': Color(0xFF2C5530),
          'page': const DoaPage(),
        },
        {
          'icon': Icons.note_alt_rounded,
          'label': 'Catatan',
          'color': Color(0xFF7D4E1F),
          'page': const NotesPage(),
        },
        {
          'icon': Icons.mosque_rounded,
          'label': 'Sholat',
          'color': Color(0xFF1E3A5F),
          'page': const PrayerTimesPage(),
        },
        {
          'icon': Icons.explore_rounded,
          'label': 'Kiblat',
          'color': Color(0xFF8B4513),
          'page': const QiblaPage(),
        },
      ];

      final action = quickActions[index];
      
      return Container(
        width: 70,
        child: Column(
          children: [
            // Icon dengan background circle
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: action['color'].withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: action['color'].withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                shape: CircleBorder(),
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => action['page'] as Widget),
                  ),
                  child: Icon(
                    action['icon'] as IconData,
                    size: 28,
                    color: action['color'],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Label
            Text(
              action['label'] as String,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A5D57),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    },
  ),
),
                          const SizedBox(height: 24),

                          // Surah List Header
                          Row(
                            children: [
                              Text(
                                'Daftar Surah',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  color: const Color(0xFF1A5D57),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${filtered.length} Surah',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF889396),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  
                  // Surah List
                  surahAsync.when(
                    data: (_) => SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      sliver: SliverList.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final s = filtered[index];
                          final progress = ref.watch(surahProgressProvider(s.number)).maybeWhen(data: (v) => v, orElse: () => 0.0);
                          final bookmarkedSurahSet = bookmarksAsync.maybeWhen(
                            data: (list) => list.map((b) => b.surah).toSet(),
                            orElse: () => <int>{},
                          );
                          return SurahCard(
                            surah: s,
                            progress: progress,
                            bookmarked: bookmarkedSurahSet.contains(s.number),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => SurahDetailPage(surahNumber: s.number)),
                            ),
                          );
                        },
                      ),
                    ),
                    loading: () => SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      sliver: SliverList.separated(
                        itemCount: 6,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, __) => _SkeletonCard(),
                      ),
                    ),
                    error: (e, st) => SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: const Color(0xFF1A5D57),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Gagal memuat daftar surah',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: const Color(0xFF1A5D57),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              e.toString(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF889396),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Juz Tab
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Juz',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: const Color(0xFF1A5D57),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: 30,
                        itemBuilder: (context, index) {
                          final juz = index + 1;
                          return _JuzCard(
                            juzNumber: juz,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => JuzDetailPage(juzNumber: juz)),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppBarIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _AppBarIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, color: const Color(0xFFFAF8F0), size: 20),
        padding: const EdgeInsets.all(8),
        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        onPressed: onPressed,
      ),
    );
  }
}

class _LastReadCard extends StatelessWidget {
  final int surah;
  final int ayah;
  final VoidCallback onTap;

  const _LastReadCard({
    required this.surah,
    required this.ayah,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A5D57), Color(0xFF0D2F2D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A5D57).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: const Icon(Icons.bookmark_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terakhir Dibaca',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Surah $surah • Ayat $ayah',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextButton.icon(
                  onPressed: onTap,
                  icon: Icon(Icons.play_arrow_rounded, color: const Color(0xFF1A5D57), size: 16),
                  label: Text(
                    'Lanjutkan',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A5D57),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LastReadSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Color(0xFFD0D0D0),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0D0D0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0D0D0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFD0D0D0),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _HoverScale(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: color),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JuzCard extends StatelessWidget {
  final int juzNumber;
  final VoidCallback onTap;

  const _JuzCard({
    required this.juzNumber,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _HoverScale(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8E8E8)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A5D57).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$juzNumber',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: const Color(0xFF1A5D57),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Juz $juzNumber',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF1A5D57),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HoverScale extends StatefulWidget {
  final Widget child;
  const _HoverScale({required this.child});
  @override
  State<_HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<_HoverScale> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            height: 44, 
            width: 44, 
            decoration: const BoxDecoration(
              color: Color(0xFFE8E8E8),
              shape: BoxShape.circle
            )
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16, 
                  width: 140, 
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E8E8),
                    borderRadius: BorderRadius.circular(8)
                  )
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12, 
                  width: 220, 
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E8E8),
                    borderRadius: BorderRadius.circular(6)
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}