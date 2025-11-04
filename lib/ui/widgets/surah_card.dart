import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/surah_models.dart';

class SurahCard extends StatelessWidget {
  final SurahSummary surah;
  final VoidCallback? onTap;
  const SurahCard({super.key, required this.surah, this.onTap});

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
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: isDark
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.primary.withOpacity(0.12),
              foregroundColor: isDark
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.primary,
              child: Text(
                '${surah.number}',
                style: const TextStyle(fontWeight: FontWeight.w700),
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
            Icon(Icons.arrow_forward_ios_rounded, size: 18, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
