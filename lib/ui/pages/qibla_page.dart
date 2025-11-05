import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/quran_providers.dart';

class QiblaPage extends ConsumerStatefulWidget {
  const QiblaPage({super.key});

  @override
  ConsumerState<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends ConsumerState<QiblaPage> {
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  double? _direction;
  bool _loading = false;
  String? _error;

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; _direction = null; });
    try {
      final lat = double.parse(_latCtrl.text.trim());
      final lng = double.parse(_lngCtrl.text.trim());
      final api = ref.read(alAdhanApiProvider);
      final data = await api.qibla(latitude: lat, longitude: lng);
      setState(() { _direction = (data['direction'] as num).toDouble(); });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Arah Kiblat', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(labelText: 'Latitude'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _lngCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(labelText: 'Longitude'),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _fetch,
                    icon: const Icon(Icons.navigation_rounded),
                    label: const Text('Arah'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(minHeight: 3),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.rotate(
                      angle: (_direction ?? 0) * math.pi / 180,
                      child: Icon(Icons.explore_rounded, size: 120, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(height: 12),
                    Text(_direction != null ? '${_direction!.toStringAsFixed(1)}°' : '--°', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 24)),
                    const SizedBox(height: 8),
                    Text('Masukkan koordinat untuk mendapatkan arah kiblat.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
