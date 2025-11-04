import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/quran_providers.dart';
import 'surah_detail_page.dart';

class SurahListPage extends ConsumerWidget {
  const SurahListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahAsync = ref.watch(surahListProvider);
    final filtered = ref.watch(filteredSurahListProvider);
    final editionsAsync = ref.watch(audioEditionsProvider);
    final selectedEdition = ref.watch(selectedEditionProvider);
    final lastReadAsync = ref.watch(lastReadProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text('HR', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            Text('Al Quran HR', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          editionsAsync.when(
            data: (eds) => PopupMenuButton<AudioEditionDisplay>(
              icon: const Icon(Icons.record_voice_over_rounded),
              onSelected: (value) => ref.read(selectedEditionProvider.notifier).state = value,
              itemBuilder: (context) => eds
                  .map((q) => PopupMenuItem(value: q, child: Text(q.name)))
                  .toList(),
              tooltip: 'Pilih Qari (Audio Edition)\nSaat ini: ${selectedEdition.name}',
            ),
            loading: () => const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => IconButton(
              icon: const Icon(Icons.record_voice_over_rounded),
              onPressed: () {},
              tooltip: 'Gagal memuat Qari',
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            lastReadAsync.when(
              data: (lr) => lr == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      child: Card(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        child: ListTile(
                          leading: const Icon(Icons.bookmark_rounded),
                          title: Text('Terakhir dibaca', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          subtitle: Text('Surah ${lr.surah} • Ayat ${lr.ayah}'),
                          trailing: TextButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => SurahDetailPage(surahNumber: lr.surah)),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Lanjutkan'),
                          ),
                        ),
                      ),
                    ),
              loading: () => const SizedBox.shrink(),
              error: (e, _) => const SizedBox.shrink(),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
                decoration: InputDecoration(
                  hintText: 'Cari surah (nama/nomor)...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: surahAsync.when(
                data: (_) => ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final s = filtered[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                        child: Text('${s.number}'),
                      ),
                      title: Text(s.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      subtitle: Text('${s.englishName} • ${s.revelationType} • ${s.numberOfAyahs} ayat'),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SurahDetailPage(surahNumber: s.number)),
                      ),
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Gagal memuat daftar surah\n$e'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
