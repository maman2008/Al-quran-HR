import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/quran_providers.dart';

Future<void> showQariPicker(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final editionsAsync = ref.watch(audioEditionsProvider);
      final selected = ref.watch(selectedEditionProvider);
      String query = '';
      return StatefulBuilder(
        builder: (context, setState) {
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.record_voice_over_rounded),
                      const SizedBox(width: 8),
                      Text('Pilih Qari', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Muat ulang daftar Qari',
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: () => ref.refresh(audioEditionsProvider),
                      ),
                      if (editionsAsync.maybeWhen(orElse: () => false, data: (d) => d.isNotEmpty))
                        Chip(
                          label: Text(selected.name, overflow: TextOverflow.ellipsis),
                          avatar: const Icon(Icons.check_rounded, size: 18),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (v) => setState(() => query = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Cari Qari / edition id...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  editionsAsync.maybeWhen(
                    orElse: () => const SizedBox.shrink(),
                    data: (eds) {
                      // Quick picks: choose some popular reciters by id if available
                      const quickIds = [
                        'ar.alafasy',
                        'ar.husary',
                        'ar.minshawi',
                        'ar.abdulbasit',
                      ];
                      final quick = eds.where((e) => quickIds.contains(e.id)).toList();
                      if (quick.isEmpty) return const SizedBox.shrink();
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: quick.map((e) {
                            final isSel = e.id == selected.id;
                            return ChoiceChip(
                              selected: isSel,
                              label: Text(e.name, overflow: TextOverflow.ellipsis),
                              avatar: const Icon(Icons.mic_rounded, size: 18),
                              onSelected: (_) {
                                ref.read(selectedEditionProvider.notifier).state = e;
                                Navigator.pop(context);
                              },
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  editionsAsync.when(
                    data: (eds) {
                      final filtered = query.isEmpty
                          ? eds
                          : eds.where((e) =>
                                e.name.toLowerCase().contains(query) ||
                                e.id.toLowerCase().contains(query),
                              ).toList();
                      return Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final e = filtered[index];
                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                ref.read(selectedEditionProvider.notifier).state = e;
                                Navigator.pop(context);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                                      child: const Icon(Icons.mic_rounded),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 2),
                                          Text(e.id, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                        ],
                                      ),
                                    ),
                                    Radio<String>(
                                      value: e.id,
                                      groupValue: selected.id,
                                      onChanged: (_) {
                                        ref.read(selectedEditionProvider.notifier).state = e;
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Gagal memuat Qari\n$e'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
