import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/quran_providers.dart';
import 'notes_page.dart';
import 'bookmark_page.dart';

class JuzDetailPage extends ConsumerWidget {
  final int juzNumber;
  const JuzDetailPage({super.key, required this.juzNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final juzAsync = ref.watch(juzDetailProvider(juzNumber));

    return Scaffold(
      appBar: AppBar(
        title: Text('Juz $juzNumber', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        actions: [
          // Notes (buka halaman catatan umum)
          IconButton(
            tooltip: 'Catatan',
            icon: Icon(Icons.note_alt_rounded, color: Theme.of(context).colorScheme.primary),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotesPage()),
            ),
          ),
          // Info singkat
          IconButton(
            tooltip: 'Info Juz',
            icon: Icon(Icons.info_outline_rounded, color: Theme.of(context).colorScheme.primary),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Tentang Juz $juzNumber'),
                  content: const Text('Halaman ini menampilkan ayat-ayat dalam Juz terpilih lengkap dengan teks Arab dan terjemah.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
                  ],
                ),
              );
            },
          ),
          // Buka daftar bookmark
          IconButton(
            tooltip: 'Bookmark',
            icon: Icon(Icons.bookmark_add_outlined, color: Theme.of(context).colorScheme.primary),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BookmarkPage()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: juzAsync.when(
          data: (state) {
            if (state.ayahs.isEmpty) {
              return const Center(child: Text('Tidak ada data untuk Juz ini.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
              itemCount: state.ayahs.length,
              separatorBuilder: (_, __) => const Divider(height: 20),
              itemBuilder: (context, index) {
                final a = state.ayahs[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                          child: Text('${a.numberInSurah}', style: const TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${a.surahName} • Ayat ${a.numberInSurah}',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Simpan bookmark ayat ini',
                          icon: Icon(Icons.bookmark_add_outlined, color: Theme.of(context).colorScheme.primary),
                          onPressed: () async {
                            await ref.read(bookmarkControllerProvider).toggleWithMeta(
                                  surah: a.surahNumber,
                                  ayah: a.numberInSurah,
                                  surahName: a.surahName,
                                );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Bookmark ${a.surahName} ayat ${a.numberInSurah} diubah'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      a.arabic,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.amiri(fontSize: 22, height: 2.0),
                    ),
                    if ((a.translationId ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        a.translationId!,
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ],
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Gagal memuat Juz $juzNumber.\n$e'),
          ),
        ),
      ),
    );
  }
}
