import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/surah_models.dart';
import '../theme.dart';

class SurahCard extends StatelessWidget {
  final SurahSummary surah;
  final VoidCallback? onTap;
  final double? progress; // 0..1
  final bool bookmarked;
  const SurahCard({super.key, required this.surah, this.onTap, this.progress, this.bookmarked = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: cs.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.20 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(isDark ? 0.55 : 0.12),
                        Theme.of(context).colorScheme.primary.withOpacity(isDark ? 0.85 : 0.24),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${surah.number}',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        surah.name,
                        style: GoogleFonts.amiri(fontSize: 22, fontWeight: FontWeight.w700),
                        textAlign: TextAlign.start,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${surah.englishName} • ${surah.revelationType} • ${surah.numberOfAyahs} ayat',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (bookmarked)
                  Icon(Icons.bookmark_rounded, color: AppTheme.islamicGold, size: 22)
                else
                  Icon(Icons.bookmark_border_rounded, color: cs.onSurfaceVariant, size: 22),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: cs.onSurfaceVariant),
              ],
            ),
            if ((progress ?? 0) > 0) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress!.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: cs.outlineVariant.withOpacity(0.25),
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.islamicGold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
