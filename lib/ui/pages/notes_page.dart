import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/quran_providers.dart';
import '../../models/surah_models.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idxAsync = ref.watch(surahNotesIndexProvider);
    final surahAsync = ref.watch(surahListProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Catatan Surah', 
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white
          )
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32), // Green color from screenshot
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Tambah Catatan',
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white),
              ),
              onPressed: () async {
                final list = await ref.read(surahListProvider.future);
                if (!context.mounted) return;
                final picked = await showModalBottomSheet<SurahSummary>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) {
                    return _PickSurahSheet(list: list);
                  },
                );
                if (picked != null) {
                  await _openEditor(context, ref, picked.number, initial: await ref.read(surahNoteProvider(picked.number).future) ?? '');
                }
                ref.invalidate(surahNotesIndexProvider);
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: idxAsync.when(
          data: (ids) {
            final list = surahAsync.maybeWhen(data: (d) => d, orElse: () => <SurahSummary>[]);
            if (ids.isEmpty) {
              return _buildEmptyState();
            }
            return ListView.separated(
              itemCount: ids.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final n = ids[i];
                SurahSummary? meta;
                try { meta = list.firstWhere((e) => e.number == n); } catch (_) {}
                final title = meta?.englishName ?? 'Surah $n';
                return _buildNoteCard(ctx, ref, n, title, meta);
              },
            );
          },
          loading: () => _buildLoadingState(),
          error: (e, _) => _buildErrorState(e),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.note_add_rounded, 
              size: 64, 
              color: const Color(0xFF2E7D32)
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum Ada Catatan',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF424242)
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap tombol + untuk menambah catatan',
            style: GoogleFonts.poppins(
              color: const Color(0xFF757575)
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Memuat catatan...',
            style: GoogleFonts.poppins(
              color: const Color(0xFF757575)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(dynamic error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, 
            size: 64, 
            color: const Color(0xFFD32F2F)
          ),
          const SizedBox(height: 16),
          Text(
            'Terjadi Kesalahan',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF424242)
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.toString(),
              style: GoogleFonts.poppins(
                color: const Color(0xFF757575)
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, WidgetRef ref, int n, String title, SurahSummary? meta) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.sticky_note_2_rounded, 
                color: Colors.white, 
                size: 20
              ),
            ),
            title: Text(title, 
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: const Color(0xFF424242)
              )
            ),
            subtitle: FutureBuilder<String?>(
              future: ref.read(surahNoteProvider(n).future),
              builder: (c, s) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  (s.data ?? '').isEmpty ? '—' : (s.data!.length > 80 ? '${s.data!.substring(0, 80)}…' : s.data!),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF757575),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            onTap: () async {
              final text = await ref.read(surahNoteProvider(n).future);
              if (!context.mounted) return;
              await _openEditor(context, ref, n, initial: text ?? '');
              ref.invalidate(surahNoteProvider(n));
              ref.invalidate(surahNotesIndexProvider);
            },
            trailing: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                tooltip: 'Hapus',
                icon: Icon(Icons.delete_outline_rounded, 
                  color: const Color(0xFFD32F2F), 
                  size: 20
                ),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (dCtx) => Dialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD32F2F).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.delete_rounded,
                                color: const Color(0xFFD32F2F),
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Hapus Catatan?',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Catatan untuk $title akan dihapus permanen',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF757575),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(dCtx, false),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      side: BorderSide(color: const Color(0xFF2E7D32)),
                                    ),
                                    child: Text('Batal', 
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF2E7D32)
                                      )
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () => Navigator.pop(dCtx, true),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFD32F2F),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text('Hapus', 
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white
                                      )
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                  if (ok == true) {
                    await ref.read(notesControllerProvider).setSurah(n, '');
                    ref.invalidate(surahNoteProvider(n));
                    ref.invalidate(surahNotesIndexProvider);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Catatan $title dihapus'),
                        backgroundColor: const Color(0xFFD32F2F),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      )
                    );
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref, int surah, {required String initial}) async {
    final ctrl = TextEditingController(text: initial);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.edit_note_rounded,
                            color: const Color(0xFF2E7D32),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Catatan Surah $surah',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: const Color(0xFF424242)
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: TextField(
                        controller: ctrl,
                        maxLines: 8,
                        decoration: InputDecoration(
                          hintText: 'Tulis catatan Anda di sini...',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          hintStyle: GoogleFonts.poppins(
                            color: const Color(0xFF9E9E9E)
                          ),
                        ),
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF424242)
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: const Color(0xFF2E7D32)),
                            ),
                            child: Text('Tutup', 
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF2E7D32)
                              )
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              await ref.read(notesControllerProvider).setSurah(surah, ctrl.text);
                              if (!context.mounted) return;
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Catatan Surah $surah tersimpan'),
                                  backgroundColor: const Color(0xFF2E7D32),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                )
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('Simpan', 
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                color: Colors.white
                              )
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PickSurahSheet extends StatefulWidget {
  final List<SurahSummary> list;
  const _PickSurahSheet({required this.list});

  @override
  State<_PickSurahSheet> createState() => _PickSurahSheetState();
}

class _PickSurahSheetState extends State<_PickSurahSheet> {
  String q = '';
  @override
  Widget build(BuildContext context) {
    final filtered = q.isEmpty ? widget.list : widget.list.where((s) => s.englishName.toLowerCase().contains(q) || s.number.toString() == q).toList();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: TextField(
                onChanged: (v) => setState(() => q = v.toLowerCase()),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded, color: const Color(0xFF757575)),
                  hintText: 'Cari surah…',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  hintStyle: GoogleFonts.poppins(
                    color: const Color(0xFF9E9E9E)
                  ),
                ),
                style: GoogleFonts.poppins(
                  color: const Color(0xFF424242)
                ),
              ),
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: filtered.length,
              separatorBuilder: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(color: const Color(0xFFE0E0E0), height: 1),
              ),
              itemBuilder: (ctx, i) {
                final s = filtered[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      s.number.toString(),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2E7D32),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  title: Text(
                    s.englishName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF424242)
                    ),
                  ),
                  onTap: () => Navigator.pop(context, s),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}