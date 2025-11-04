import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/quran_providers.dart';
import 'surah_detail_page.dart';

class BookmarkPage extends ConsumerWidget {
  const BookmarkPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarksProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Bookmark Saya', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        actions: [
          bookmarksAsync.maybeWhen(
            data: (list) => IconButton(
              tooltip: 'Hapus semua',
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: list.isEmpty
                  ? null
                  : () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Hapus semua bookmark?'),
                          content: const Text('Tindakan ini akan menghapus seluruh bookmark yang tersimpan.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await ref.read(bookmarkControllerProvider).clearAll();
                      }
                    },
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: bookmarksAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bookmarks_outlined, size: 48),
                    const SizedBox(height: 12),
                    Text('Belum ada bookmark', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Simpan ayat dari halaman surah untuk muncul di sini.', textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final b = items[index];
              final saved = b.savedAt != null ? _fmt(b.savedAt!) : null;
              return Dismissible(
                key: ValueKey('bm-${b.surah}-${b.ayah}-${index}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_forever_rounded, color: Colors.white),
                ),
                onDismissed: (_) => ref.read(bookmarkControllerProvider).remove(b),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: Theme.of(context).colorScheme.primaryContainer,
                  leading: Icon(
                    Icons.bookmark_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    b.surahName ?? 'Surah ${b.surah}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  subtitle: Text(
                    'Ayat ${b.ayah}${saved != null ? ' • $saved' : ''}',
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8)),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    onPressed: () => ref.read(bookmarkControllerProvider).remove(b),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SurahDetailPage(surahNumber: b.surah)),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Gagal memuat bookmark\n$e'),
        ),
      ),
    );
  }

  String _fmt(DateTime d) {
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }
}
