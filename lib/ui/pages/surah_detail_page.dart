import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import '../../providers/quran_providers.dart';
import '../../models/surah_models.dart';
import 'surah_info_page.dart';

class SurahDetailPage extends ConsumerStatefulWidget {
  final int surahNumber;
  const SurahDetailPage({super.key, required this.surahNumber});

  @override
  ConsumerState<SurahDetailPage> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends ConsumerState<SurahDetailPage> {
  int? playingAyah;
  ConcatenatingAudioSource? _playlist;
  List<int> _ayahIndexMap = [];
  StreamSubscription<int?>? _indexSub;
  ProviderSubscription<AudioEditionDisplay>? _qariListenSub;

  void _resetPlayer(AudioPlayer player) {
    player.stop();
    _playlist = null;
    _ayahIndexMap = [];
  }

  @override
  void initState() {
    super.initState();
    _qariListenSub = ref.listenManual(selectedEditionProvider, (prev, next) {
      final player = ref.read(audioPlayerProvider);
      _indexSub?.cancel();
      _indexSub = null;
      _resetPlayer(player);
      setState(() { playingAyah = null; });
      ref.invalidate(surahDetailProvider(widget.surahNumber));
    });
  }

  Future<void> _ensurePlaylist(AudioPlayer player, List<AyahComposite> ayahs) async {
    // Build playlist from ayahs having audio
    final sources = <AudioSource>[];
    _ayahIndexMap = [];
    for (final a in ayahs) {
      final url = a.audioUrl;
      if (url != null && url.isNotEmpty) {
        sources.add(AudioSource.uri(Uri.parse(url)));
        _ayahIndexMap.add(a.numberInSurah);
      }
    }
    _playlist = ConcatenatingAudioSource(children: sources);
    await player.setAudioSource(_playlist!);
  }

  Future<void> _playAyah(AudioPlayer player, List<AyahComposite> ayahs, int ayahNumber) async {
    // Seek to the ayah index inside playlist and play
    if (_playlist == null) {
      await _ensurePlaylist(player, ayahs);
    }
    final idx = _ayahIndexMap.indexOf(ayahNumber);
    if (idx < 0) return;
    await player.seek(Duration.zero, index: idx);
    await player.play();
    setState(() { playingAyah = ayahNumber; });
    // Save last read when starts playing
    await ref.read(lastReadControllerProvider).save(widget.surahNumber, ayahNumber);
  }

  @override
  void dispose() {
    _indexSub?.cancel();
    _qariListenSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(surahDetailProvider(widget.surahNumber));
    final player = ref.watch(audioPlayerProvider);

    return Scaffold(
      appBar: AppBar(
        title: detailAsync.maybeWhen(
          data: (d) => Text(d.summary.englishName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          orElse: () => Text('Surah ${widget.surahNumber}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ),
        actions: [
          detailAsync.maybeWhen(
            data: (d) {
              final noteAsync = ref.watch(surahNoteProvider(d.summary.number));
              final hasNote = noteAsync.maybeWhen(data: (t) => (t ?? '').trim().isNotEmpty, orElse: () => false);
              return IconButton(
                tooltip: 'Catatan Surah',
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.note_alt_rounded),
                    if (hasNote)
                      Positioned(
                        right: -1,
                        top: -1,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
                onPressed: () async {
                  final existing = await ref.read(surahNoteProvider(d.summary.number).future);
                  final ctrl = TextEditingController(text: existing ?? '');
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (ctx) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                        child: SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Text('Catatan Surah ${d.summary.number}', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                                    const Spacer(),
                                    if ((existing ?? '').trim().isNotEmpty)
                                      IconButton(
                                        tooltip: 'Hapus Catatan',
                                        onPressed: () async {
                                          final ok = await showDialog<bool>(
                                            context: context,
                                            builder: (dCtx) => AlertDialog(
                                              title: const Text('Hapus catatan?'),
                                              content: const Text('Tindakan ini tidak dapat dibatalkan.'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Batal')),
                                                FilledButton(onPressed: () => Navigator.pop(dCtx, true), child: const Text('Hapus')),
                                              ],
                                            ),
                                          );
                                          if (ok == true) {
                                            await ref.read(notesControllerProvider).setSurah(d.summary.number, '');
                                            if (!mounted) return;
                                            ref.invalidate(surahNoteProvider(d.summary.number));
                                            ref.invalidate(surahNotesIndexProvider);
                                            Navigator.pop(ctx);
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catatan dihapus')));
                                          }
                                        },
                                        icon: const Icon(Icons.delete_outline_rounded),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: ctrl,
                                  maxLines: 8,
                                  decoration: const InputDecoration(
                                    hintText: 'Tulis catatan untuk surah ini...',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Tutup'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: FilledButton(
                                        onPressed: () async {
                                          await ref.read(notesControllerProvider).setSurah(d.summary.number, ctrl.text);
                                          if (!mounted) return;
                                          ref.invalidate(surahNoteProvider(d.summary.number));
                                          ref.invalidate(surahNotesIndexProvider);
                                          Navigator.pop(ctx);
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catatan surah tersimpan')));
                                        },
                                        child: const Text('Simpan'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          detailAsync.maybeWhen(
            data: (d) => IconButton(
              tooltip: 'Tentang surah ini',
              icon: const Icon(Icons.info_outline_rounded),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (ctx) {
                    return DraggableScrollableSheet(
                      expand: false,
                      initialChildSize: 0.65,
                      minChildSize: 0.45,
                      maxChildSize: 0.95,
                      builder: (ctx, scrollController) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          child: ListView(
                            controller: scrollController,
                            children: [
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              Text('Tentang Surah', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),
                              ListTile(
                                leading: CircleAvatar(child: Text('${d.summary.number}')),
                                title: Text(d.summary.name, style: GoogleFonts.amiri(fontSize: 22, fontWeight: FontWeight.w700)),
                                subtitle: Text('${d.summary.englishName} • ${d.summary.revelationType} • ${d.summary.numberOfAyahs} ayat'),
                              ),
                              const SizedBox(height: 8),
                              FutureBuilder<String?>(
                                future: ref.read(surahInfoProvider(d.summary.number).future),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      child: LinearProgressIndicator(minHeight: 4),
                                    );
                                  }
                                  final text = snapshot.data;
                                  if (text == null || text.isEmpty) {
                                    return Text(
                                      'Artikel singkat tidak tersedia. Gunakan tautan di bawah untuk membuka sumber eksternal.',
                                      style: GoogleFonts.poppins(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                    );
                                  }
                                  return Text(
                                    text,
                                    style: GoogleFonts.poppins(fontSize: 14, height: 1.6),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => SurahInfoPage(
                                          surahNumber: d.summary.number,
                                          titleArabic: d.summary.name,
                                          titleEnglish: d.summary.englishName,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('Baca selengkapnya'),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          detailAsync.maybeWhen(
            data: (d) => IconButton(
              icon: const Icon(Icons.bookmark_add_outlined),
              tooltip: 'Simpan bookmark (ayat aktif)',
              onPressed: () async {
                final ayah = playingAyah ?? 1;
                await ref.read(bookmarkControllerProvider).toggleWithMeta(
                      surah: d.summary.number,
                      ayah: ayah,
                      surahName: d.summary.name,
                    );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Bookmark ${d.summary.name} ayat $ayah diubah')),
                );
              },
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: detailAsync.when(
        data: (data) {
          // Attach player index listener once when data ready
          _indexSub ??= player.currentIndexStream.listen((idx) {
            if (idx == null) return;
            if (idx >= 0 && idx < _ayahIndexMap.length) {
              setState(() { playingAyah = _ayahIndexMap[idx]; });
            }
          });

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: data.ayahs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final a = data.ayahs[index];
              final isPlaying = playingAyah == a.numberInSurah && player.playing;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
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
                        IconButton(
                          icon: Icon(isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, size: 28),
                          onPressed: () async {
                            if (isPlaying) {
                              await player.pause();
                              setState(() { playingAyah = null; });
                            } else {
                              await _playAyah(player, data.ayahs, a.numberInSurah);
                            }
                          },
                          tooltip: isPlaying ? 'Jeda' : 'Putar',
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      a.arabic,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.amiri(
                        fontSize: 24,
                        height: 2.0,
                      ),
                    ),
                    if ((a.transliteration ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        a.transliteration!,
                        style: GoogleFonts.poppins(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                    if ((a.translationId ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        a.translationId!,
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Gagal memuat surah:\n$e'),
        ),
      ),
      floatingActionButton: detailAsync.maybeWhen(
        data: (d) => FloatingActionButton.extended(
          onPressed: () async {
            await _ensurePlaylist(player, d.ayahs);
            // Start from the first ayah with audio
            await player.seek(Duration.zero, index: 0);
            await player.play();
          },
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Putar Surah'),
        ),
        orElse: () => null,
      ),
    );
  }
}
