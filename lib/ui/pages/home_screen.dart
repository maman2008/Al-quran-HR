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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahAsync = ref.watch(surahListProvider);
    final filtered = ref.watch(filteredSurahListProvider);
    final lastReadAsync = ref.watch(lastReadProvider);
    // Removed bookmarks section from Home; no need to watch here

    final searchFocus = FocusNode();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 60,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A5D57), Color(0xFF0D2F2D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white.withOpacity(0.15),
                child: const Icon(Icons.mosque_rounded, color: Color(0xFFFAF8F0)),
              ),
              const SizedBox(width: 8),
              Text('Al-Qur\'an HR', style: GoogleFonts.amiri(fontWeight: FontWeight.w700, fontSize: 22, color: const Color(0xFFFAF8F0))),
            ],
          ),
          actions: [
            // Bookmark (navigate to bookmark list)
            IconButton(
              tooltip: 'Bookmark',
              icon: const Icon(Icons.bookmark_rounded, color: Color(0xFFFAF8F0)),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BookmarkPage()),
              ),
            ),
          
            // Dark mode toggle
            IconButton(
              tooltip: 'Mode Gelap/Terang',
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                color: const Color(0xFFFAF8F0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: () {
                final current = ref.read(themeModeProvider);
                final next = current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                ref.read(themeControllerProvider).set(next);
              },
            ),
            // Qari picker (Audio)
            IconButton(
              tooltip: 'Pilih Qari',
              icon: const Icon(Icons.record_voice_over_rounded, color: Color(0xFFFAF8F0)),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: () => showQariPicker(context, ref),
            ),
          
            const SizedBox(width: 16),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(128),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Material(
                    elevation: 2,
                    shadowColor: Colors.black.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(24),
                    child: SizedBox(
                      height: 48,
                      child: TextField(
                        focusNode: searchFocus,
                        onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
                        style: GoogleFonts.roboto(fontSize: 15, color: const Color(0xFF1A5D57)),
                        decoration: InputDecoration(
                          hintText: 'Cari surah (nama/nomor)...',
                          hintStyle: GoogleFonts.roboto(color: const Color(0xFF889396), fontSize: 15),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(left: 12, right: 8),
                            child: Icon(Icons.search, size: 20, color: Color(0xFF889396)),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 40),
                          filled: true,
                          fillColor: const Color(0xFFFAFAFA),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFD9E7D5)),
                    ),
                    child: SizedBox(
                      height: 40,
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: TabBar(
                          isScrollable: false,
                          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 15),
                          unselectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 15),
                          labelColor: Colors.white,
                          unselectedLabelColor: const Color(0xFF889396),
                          dividerColor: Colors.transparent,
                          labelPadding: const EdgeInsets.symmetric(horizontal: 24),
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: const Color(0xFF1A5D57),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          tabs: const [
                            Tab(text: 'Surah'),
                            Tab(text: 'Juz'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              // Surah Tab
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Last Read Section
                          lastReadAsync.when(
                            data: (lr) => lr == null
                                ? const SizedBox.shrink()
                                : Container(
                                    width: double.infinity,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => SurahDetailPage(surahNumber: lr.surah)),
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                                          border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.15)),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.06),
                                              blurRadius: 18,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.bookmark_rounded, color: Theme.of(context).colorScheme.primary),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Terakhir Dibaca',
                                                    style: GoogleFonts.poppins(
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Surah ${lr.surah} • Ayat ${lr.ayah}',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 13,
                                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.primary,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: TextButton.icon(
                                                onPressed: () => Navigator.of(context).push(
                                                  MaterialPageRoute(builder: (_) => SurahDetailPage(surahNumber: lr.surah)),
                                                ),
                                                icon: Icon(Icons.play_arrow_rounded, color: Theme.of(context).colorScheme.onPrimary, size: 16),
                                                label: Text(
                                                  'Lanjutkan',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Theme.of(context).colorScheme.onPrimary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                            loading: () => const SizedBox.shrink(),
                            error: (e, _) => const SizedBox.shrink(),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Bookmarks section removed as requested
                          const SizedBox(height: 0),
                          
                          // Quick Actions
                          Text(
                            'Akses Cepat',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GridView.count(
                            crossAxisCount: 4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _QuickAction(
                                icon: Icons.menu_book_rounded,
                                label: 'Zikir',
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ZikirPage()),
                                ),
                              ),
                              _QuickAction(
                                icon: Icons.note_alt_rounded,
                                label: 'Catatan',
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const NotesPage()),
                                ),
                              ),
                              _QuickAction(
                                icon: Icons.access_time_rounded,
                                label: 'Sholat',
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const PrayerTimesPage()),
                                ),
                              ),
                              _QuickAction(
                                icon: Icons.explore_rounded,
                                label: 'Kiblat',
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const QiblaPage()),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          

                          // Surah List Header
                          Text(
                            'Daftar Surah',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  
                  // Surah List
                  surahAsync.when(
                    data: (_) => SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      sliver: SliverList.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final s = filtered[index];
                          return SurahCard(
                            surah: s,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => SurahDetailPage(surahNumber: s.number)),
                            ),
                          );
                        },
                      ),
                    ),
                    loading: () => const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(),
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
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Gagal memuat daftar surah',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              e.toString(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Juz',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.2,
                        ),
                        itemCount: 30,
                        itemBuilder: (context, index) {
                          final juz = index + 1;
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => JuzDetailPage(juzNumber: juz)),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Theme.of(context).colorScheme.surface,
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
                                  ),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Juz',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$juz',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 22,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}