import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/quran_providers.dart';
import '../../core/api/myquran_api.dart';

class PrayerTimesPage extends ConsumerStatefulWidget {
  const PrayerTimesPage({super.key});

  @override
  ConsumerState<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends ConsumerState<PrayerTimesPage> {
  String? _selectedCityCode;
  String? _selectedCityName;
  bool _loading = false;
  String? _error;
  Map<String, String>? _today;

  @override
  void initState() {
    super.initState();
    _loadSelectedCity();
  }

  Future<void> _loadSelectedCity() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedCityCode = prefs.getString('myq_city_code');
      _selectedCityName = prefs.getString('myq_city_name');
    });
    if (_selectedCityCode != null) {
      await _fetch();
    }
  }

  Future<void> _saveSelectedCity(String code, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('myq_city_code', code);
    await prefs.setString('myq_city_name', name);
    setState(() {
      _selectedCityCode = code;
      _selectedCityName = name;
    });
  }

  Future<void> _pickCity() async {
    final api = ref.read(myQuranApiProvider);
    setState(() { _loading = true; _error = null; });
    try {
      final all = await api.fetchCities();
      if (!mounted) return;
      String query = '';
      final result = await showModalBottomSheet<Map<String, String>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setSheet) {
              final filtered = query.isEmpty
                  ? all
                  : all.where((c) => (c.name.toLowerCase().contains(query) || (c.province ?? '').toLowerCase().contains(query))).toList();
              final brightness = Theme.of(context).brightness;
              final isDark = brightness == Brightness.dark;
              final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
              final primaryColor = const Color(0xFF10B981);
              
              return SafeArea(
                top: false,
                child: Container(
                  margin: const EdgeInsets.only(top: 60),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header dengan gradient
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, primaryColor.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on_rounded, color: Colors.white, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Pilih Kota',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close_rounded, color: Colors.white),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ),
                      
                      // Search Box
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: primaryColor.withOpacity(0.2)),
                          ),
                          child: TextField(
                            onChanged: (v) => setSheet(() => query = v.toLowerCase()),
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.search_rounded, color: primaryColor),
                              hintText: 'Cari kota atau provinsi...',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),
                      ),
                      
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                          itemBuilder: (ctx, i) {
                            final c = filtered[i];
                            final subtitle = (c.province ?? '').isEmpty ? null : c.province;
                            return Material(
                              color: Colors.transparent,
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.location_city_rounded, color: primaryColor, size: 20),
                                ),
                                title: Text(
                                  c.name,
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                ),
                                subtitle: subtitle != null ? Text(
                                  subtitle,
                                  style: GoogleFonts.poppins(color: Colors.grey.shade600),
                                ) : null,
                                trailing: Icon(Icons.chevron_right_rounded, color: primaryColor),
                                onTap: () => Navigator.pop(ctx, {'code': c.code, 'name': c.name}),
                              ),
                            );
                          },
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
      if (result != null) {
        await _saveSelectedCity(result['code']!, result['name']!);
        await _fetch();
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _fetch() async {
    final code = _selectedCityCode;
    if (code == null) {
      setState(() { _error = 'Pilih kota terlebih dahulu.'; });
      return;
    }
    setState(() { _loading = true; _error = null; _today = null; });
    try {
      final now = DateTime.now();
      final api = ref.read(myQuranApiProvider);
      final monthly = await api.fetchMonthlySchedule(cityCode: code, year: now.year, month: now.month);
      MyQDay? today;
      try {
        today = monthly.items.firstWhere(
          (d) => d.date.year == now.year && d.date.month == now.month && d.date.day == now.day,
        );
      } catch (_) {
        if (monthly.items.isNotEmpty) today = monthly.items.last;
      }
      if (today == null) {
        throw Exception('Tanggal tidak tersedia');
      }
      final t = today; // promote to non-null for the closure below
      setState(() {
        _today = {
          'Imsak': t.imsak,
          'Subuh': t.subuh,
          'Terbit': t.terbit,
          'Dhuha': t.dhuha,
          'Dzuhur': t.dzuhur,
          'Ashar': t.ashar,
          'Maghrib': t.maghrib,
          'Isya': t.isya,
        };
      });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final primaryColor = const Color(0xFF10B981);
    final backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC);
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final onSurfaceColor = isDark ? Colors.white : const Color(0xFF1E293B);
    
    // Icons untuk setiap waktu sholat
    final prayerIcons = {
      'Imsak': Icons.nightlight_round,
      'Subuh': Icons.wb_twilight_rounded,
      'Terbit': Icons.wb_sunny_rounded,
      'Dhuha': Icons.light_mode_rounded,
      'Dzuhur': Icons.brightness_high_rounded,
      'Ashar': Icons.brightness_medium_rounded,
      'Maghrib': Icons.nightlight_round,
      'Isya': Icons.dark_mode_rounded,
    };

    final w = MediaQuery.of(context).size.width;
    final gridCount = w >= 720 ? 3 : 2;
    final scale = MediaQuery.of(context).textScaleFactor.clamp(0.9, 1.2);
    // Use fixed item height to avoid tiny overflows on small screens
    final baseExtent = w >= 720 ? 156.0 : (w >= 380 ? 148.0 : 144.0);
    final itemExtent = baseExtent * (scale <= 1 ? 1.0 : (scale + 0.08));
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Jadwal Sholat',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: .2,
          ),
        ),
        centerTitle: true,
        backgroundColor: surfaceColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // City Selection Card dengan gradient
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.location_on_rounded, color: Colors.white, size: 24),
                  ),
                  title: Text(
                    _selectedCityName ?? 'Pilih Kota',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    _selectedCityName != null ? 'Ketuk untuk mengubah kota' : 'Ketuk untuk memilih kota',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  trailing: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(_loading ? Icons.refresh : Icons.refresh_rounded, 
                          color: Colors.white, size: 20),
                      tooltip: 'Muat jadwal',
                      onPressed: _loading ? null : _fetch,
                    ),
                  ),
                  onTap: _loading ? null : _pickCity,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Loading & Error States
            if (_loading) 
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      backgroundColor: surfaceColor.withOpacity(.5),
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Memuat jadwal sholat...',
                    style: GoogleFonts.poppins(
                      color: onSurfaceColor.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

            if (_error != null) 
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, size: 20, color: const Color(0xFFDC2626)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFDC2626),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // Header Date
            if (_today != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryColor.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_rounded, color: primaryColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Jadwal Sholat Hari Ini',
                      style: GoogleFonts.poppins(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year})',
                      style: GoogleFonts.poppins(
                        color: primaryColor.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // Prayer Times Grid
            Expanded(
              child: _today != null 
                  ? GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: itemExtent,
                      ),
                      itemCount: _today!.length,
                      itemBuilder: (context, i) {
                        final entry = _today!.entries.elementAt(i);
                        final prayerName = entry.key;
                        final prayerTime = entry.value;
                        final icon = prayerIcons[prayerName] ?? Icons.access_time_rounded;
                        
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  surfaceColor,
                                  surfaceColor,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: primaryColor.withOpacity(0.1),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(icon, color: primaryColor, size: 18),
                                  ),
                                  const SizedBox(height: 8),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      prayerName,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12.5 * scale,
                                        color: onSurfaceColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      prayerTime,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16 * scale,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(Icons.schedule_rounded, color: primaryColor, size: 40),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Pilih Kota Terlebih Dahulu',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: onSurfaceColor.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ketuk kartu di atas untuk memilih kota',
                            style: GoogleFonts.poppins(
                              color: onSurfaceColor.withOpacity(0.5),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
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