import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/quran_providers.dart';

class SurahInfoPage extends ConsumerWidget {
  final int surahNumber;
  final String titleArabic;
  final String titleEnglish;
  const SurahInfoPage({super.key, required this.surahNumber, required this.titleArabic, required this.titleEnglish});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoAsync = ref.watch(surahInfoProvider(surahNumber));
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tentang Surah', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            Text('$titleArabic • $titleEnglish', style: GoogleFonts.poppins(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
      body: infoAsync.when(
        data: (text) => Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Text(
              (text == null || text.isEmpty)
                  ? 'Artikel singkat tidak tersedia dalam bahasa Indonesia untuk surah ini.'
                  : text,
              style: GoogleFonts.poppins(fontSize: 15, height: 1.7),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Gagal memuat artikel\n$e'),
        ),
      ),
    );
  }
}
