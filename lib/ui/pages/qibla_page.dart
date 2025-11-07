import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

class QiblaPage extends ConsumerStatefulWidget {
  const QiblaPage({super.key});

  @override
  ConsumerState<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends ConsumerState<QiblaPage> {
  double? _direction; // Qibla bearing (0..360)
  double? _deviceHeading; // 0..360, 0 = North
  Position? _position; // current device location
  bool _loading = false;
  String? _error;
  StreamSubscription<CompassEvent>? _compassSub;

  @override
  void initState() {
    super.initState();
    _startCompass();
    _ensureLocationAndCompute();
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }

  void _startCompass() {
    _compassSub?.cancel();
    _compassSub = FlutterCompass.events?.listen((event) {
      final heading = event.heading; // may be null
      if (!mounted) return;
      setState(() { _deviceHeading = heading == null ? null : (heading % 360 + 360) % 360; });
    });
  }

  double _computeQiblaBearing(double latUserDeg, double lonUserDeg) {
    const latKaabaDeg = 21.4225;
    const lonKaabaDeg = 39.8262;
    double toRad(double d) => d * math.pi / 180.0;
    double toDeg(double r) => r * 180.0 / math.pi;
    final latUser = toRad(latUserDeg);
    final lonUser = toRad(lonUserDeg);
    final latKaaba = toRad(latKaabaDeg);
    final lonKaaba = toRad(lonKaabaDeg);
    final dLon = lonKaaba - lonUser;
    final y = math.sin(dLon);
    final x = math.cos(latUser) * math.tan(latKaaba) - math.sin(latUser) * math.cos(dLon);
    final bearingRad = math.atan2(y, x);
    var bearingDeg = toDeg(bearingRad);
    return (bearingDeg % 360 + 360) % 360;
  }

  Future<void> _ensureLocationAndCompute() async {
    setState(() { _loading = true; _error = null; });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() { _error = 'Layanan lokasi tidak aktif. Aktifkan GPS.'; });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        setState(() { _error = 'Izin lokasi ditolak. Buka pengaturan untuk mengizinkan.'; });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      final bearing = _computeQiblaBearing(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() {
        _position = pos;
        _direction = bearing;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
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
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3))),
              child: ListTile(
                leading: const Icon(Icons.my_location_rounded),
                title: Text(_position != null ? 'Lokasi Terdeteksi' : 'Deteksi Lokasi'),
                subtitle: _position != null
                    ? Text('${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}')
                    : const Text('Ketuk untuk mendeteksi lokasi Anda'),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Deteksi ulang',
                  onPressed: _loading ? null : _ensureLocationAndCompute,
                ),
                onTap: _loading ? null : _ensureLocationAndCompute,
              ),
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
                    Builder(
                      builder: (context) {
                        final dir = _direction ?? 0;
                        final heading = _deviceHeading ?? 0;
                        final delta = (dir - heading);
                        return Transform.rotate(
                          angle: delta * math.pi / 180,
                          child: Icon(Icons.explore_rounded, size: 120, color: Theme.of(context).colorScheme.primary),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(_direction != null ? '${_direction!.toStringAsFixed(1)}°' : '--°', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 24)),
                    const SizedBox(height: 6),
                    Text(_deviceHeading != null ? 'Kompas: ${_deviceHeading!.toStringAsFixed(1)}°' : 'Kompas tidak tersedia', style: GoogleFonts.poppins(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                    const SizedBox(height: 8),
                    Text('Arahkan panah mengikuti kiblat'),
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
