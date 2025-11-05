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
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setSheet) {
              final filtered = query.isEmpty
                  ? all
                  : all.where((c) => (c.name.toLowerCase().contains(query) || (c.province ?? '').toLowerCase().contains(query))).toList();
              return SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: TextField(
                          onChanged: (v) => setSheet(() => query = v.toLowerCase()),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search_rounded),
                            hintText: 'Cari kota atau provinsi...',
                          ),
                        ),
                      ),
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final c = filtered[i];
                            final subtitle = (c.province ?? '').isEmpty ? null : c.province;
                            return ListTile(
                              title: Text(c.name),
                              subtitle: subtitle != null ? Text(subtitle) : null,
                              onTap: () => Navigator.pop(ctx, {'code': c.code, 'name': c.name}),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Jadwal Sholat', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.location_city_rounded),
                title: Text(_selectedCityName ?? 'Pilih Kota'),
                subtitle: _selectedCityName != null ? const Text('Ketik untuk ubah kota') : const Text('Ketik untuk memilih kota'),
                onTap: _loading ? null : _pickCity,
                trailing: IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Muat jadwal',
                  onPressed: _loading ? null : _fetch,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(minHeight: 3),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  _tile('Imsak', _today?['Imsak'] ?? '--:--'),
                  _tile('Subuh', _today?['Subuh'] ?? '--:--'),
                  _tile('Terbit', _today?['Terbit'] ?? '--:--'),
                  _tile('Dhuha', _today?['Dhuha'] ?? '--:--'),
                  _tile('Dzuhur', _today?['Dzuhur'] ?? '--:--'),
                  _tile('Ashar', _today?['Ashar'] ?? '--:--'),
                  _tile('Maghrib', _today?['Maghrib'] ?? '--:--'),
                  _tile('Isya', _today?['Isya'] ?? '--:--'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(String title, String time) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.black.withOpacity(0.06))),
      child: ListTile(
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        trailing: Text(time, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
      ),
    );
  }
}
