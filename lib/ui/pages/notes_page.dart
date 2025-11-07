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
    
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final primaryColor = const Color(0xFF10B981);
    final backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC);
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final onSurfaceColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Catatan Surah', 
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: .2,
            color: Colors.white,
          )
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              tooltip: 'Tambah Catatan',
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              onPressed: () async {
                final list = await ref.read(surahListProvider.future);
                if (!context.mounted) return;
                final picked = await showModalBottomSheet<SurahSummary>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) {
                    return _PickSurahSheet(list: list, primaryColor: primaryColor);
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
        padding: const EdgeInsets.all(20),
        child: idxAsync.when(
          data: (ids) {
            final list = surahAsync.maybeWhen(data: (d) => d, orElse: () => <SurahSummary>[]);
            if (ids.isEmpty) {
              return _buildEmptyState(primaryColor, onSurfaceColor);
            }
            return ListView.separated(
              itemCount: ids.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (ctx, i) {
                final n = ids[i];
                SurahSummary? meta;
                try { meta = list.firstWhere((e) => e.number == n); } catch (_) {}
                final title = meta?.englishName ?? 'Surah $n';
                return _buildNoteCard(ctx, ref, n, title, meta, primaryColor, surfaceColor, onSurfaceColor);
              },
            );
          },
          loading: () => _buildLoadingState(primaryColor, onSurfaceColor),
          error: (e, _) => _buildErrorState(e, onSurfaceColor),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor, Color onSurfaceColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.note_add_rounded, 
              size: 48, 
              color: primaryColor
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum Ada Catatan',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: onSurfaceColor,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Tap tombol + di atas untuk menambah catatan surah pertama Anda',
              style: GoogleFonts.poppins(
                color: onSurfaceColor.withOpacity(0.6),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(Color primaryColor, Color onSurfaceColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Memuat catatan...',
            style: GoogleFonts.poppins(
              color: onSurfaceColor.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(dynamic error, Color onSurfaceColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded, 
              size: 40, 
              color: const Color(0xFFDC2626)
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Terjadi Kesalahan',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: onSurfaceColor,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.toString(),
              style: GoogleFonts.poppins(
                color: onSurfaceColor.withOpacity(0.6),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, WidgetRef ref, int n, String title, SurahSummary? meta, Color primaryColor, Color surfaceColor, Color onSurfaceColor) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: surfaceColor,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primaryColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.sticky_note_2_rounded, 
                color: Colors.white, 
                size: 24
              ),
            ),
            title: Text(
              title, 
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: onSurfaceColor,
              )
            ),
            subtitle: FutureBuilder<String?>(
              future: ref.read(surahNoteProvider(n).future),
              builder: (c, s) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  (s.data ?? '').isEmpty ? 'Tidak ada catatan' : (s.data!.length > 80 ? '${s.data!.substring(0, 80)}…' : s.data!),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: onSurfaceColor.withOpacity(0.6),
                    fontSize: 14,
                    height: 1.4,
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                tooltip: 'Hapus',
                icon: Icon(
                  Icons.delete_outline_rounded, 
                  color: const Color(0xFFDC2626), 
                  size: 20
                ),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (dCtx) => Dialog(
                      backgroundColor: surfaceColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.delete_rounded,
                                color: const Color(0xFFDC2626),
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Hapus Catatan?',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: onSurfaceColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Catatan untuk $title akan dihapus permanen',
                              style: GoogleFonts.poppins(
                                color: onSurfaceColor.withOpacity(0.6),
                                fontSize: 14,
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
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      side: BorderSide(color: primaryColor),
                                    ),
                                    child: Text(
                                      'Batal', 
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color: primaryColor,
                                      )
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () => Navigator.pop(dCtx, true),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFDC2626),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'Hapus', 
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
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
                        backgroundColor: const Color(0xFFDC2626),
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
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final primaryColor = const Color(0xFF10B981);
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final onSurfaceColor = isDark ? Colors.white : const Color(0xFF1E293B);

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
                color: surfaceColor,
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
                          color: onSurfaceColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.edit_note_rounded,
                            color: primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Catatan Surah $surah',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: onSurfaceColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: onSurfaceColor.withOpacity(0.2)),
                      ),
                      child: TextField(
                        controller: ctrl,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          hintText: 'Tulis catatan Anda di sini...',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          hintStyle: GoogleFonts.poppins(
                            color: onSurfaceColor.withOpacity(0.4),
                          ),
                        ),
                        style: GoogleFonts.poppins(
                          color: onSurfaceColor,
                          fontSize: 15,
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
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: BorderSide(color: primaryColor),
                            ),
                            child: Text(
                              'Tutup', 
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
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
                                  backgroundColor: primaryColor,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                )
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Simpan', 
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
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
  final Color primaryColor;
  const _PickSurahSheet({required this.list, required this.primaryColor});

  @override
  State<_PickSurahSheet> createState() => _PickSurahSheetState();
}

class _PickSurahSheetState extends State<_PickSurahSheet> {
  String q = '';
  
  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final onSurfaceColor = isDark ? Colors.white : const Color(0xFF1E293B);
    
    final filtered = q.isEmpty ? widget.list : widget.list.where((s) => s.englishName.toLowerCase().contains(q) || s.number.toString() == q).toList();
    
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
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
          // Header dengan gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.primaryColor, widget.primaryColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Icon(Icons.bookmark_add_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pilih Surah',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Search Box
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: widget.primaryColor.withOpacity(0.2)),
              ),
              child: TextField(
                onChanged: (v) => setState(() => q = v.toLowerCase()),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded, color: widget.primaryColor),
                  hintText: 'Cari surah…',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  hintStyle: GoogleFonts.poppins(
                    color: onSurfaceColor.withOpacity(0.4),
                  ),
                ),
                style: GoogleFonts.poppins(
                  color: onSurfaceColor,
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
                child: Divider(
                  color: onSurfaceColor.withOpacity(0.1), 
                  height: 1
                ),
              ),
              itemBuilder: (ctx, i) {
                final s = filtered[i];
                return Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: widget.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        s.number.toString(),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: widget.primaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    title: Text(
                      s.englishName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: onSurfaceColor,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: widget.primaryColor,
                    ),
                    onTap: () => Navigator.pop(context, s),
                  ),
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