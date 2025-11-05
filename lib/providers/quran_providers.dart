import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/alquran_api.dart';
import '../models/surah_models.dart';
import '../core/api/quran_com_api.dart';
import '../core/api/aladhan_api.dart';
import '../core/api/myquran_api.dart';

// API client provider
final apiProvider = Provider<AlQuranApi>((ref) => AlQuranApi());
final quranComApiProvider = Provider<QuranComApi>((ref) => QuranComApi());
final alAdhanApiProvider = Provider<AlAdhanApi>((ref) => AlAdhanApi());
final myQuranApiProvider = Provider<MyQuranApi>((ref) => MyQuranApi());

// Theme mode toggle and persistence
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

final themeControllerProvider = Provider((ref) => _ThemeController(ref));

class _ThemeController {
  final Ref _ref;
  _ThemeController(this._ref);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString('theme_mode');
    if (v == null) return;
    switch (v) {
      case 'light':
        _ref.read(themeModeProvider.notifier).state = ThemeMode.light;
        break;
      case 'dark':
        _ref.read(themeModeProvider.notifier).state = ThemeMode.dark;
        break;
      default:
        _ref.read(themeModeProvider.notifier).state = ThemeMode.system;
    }
  }

  Future<void> set(ThemeMode mode) async {
    _ref.read(themeModeProvider.notifier).state = mode;
    final prefs = await SharedPreferences.getInstance();
    final str = mode == ThemeMode.light ? 'light' : mode == ThemeMode.dark ? 'dark' : 'system';
    await prefs.setString('theme_mode', str);
  }
}

// Audio editions (Qari) dynamic from API with a few defaults
class AudioEditionDisplay {
  final String id;
  final String name;
  const AudioEditionDisplay(this.id, this.name);
}

final defaultAudioEditions = <AudioEditionDisplay>[
  AudioEditionDisplay('ar.alafasy', 'Mishary Rashid Alafasy'),
  AudioEditionDisplay('ar.abdulbasitmurattal', 'Abdul Basit (Murattal)'),
  AudioEditionDisplay('ar.ghamadi', 'Saad Al-Ghamidi'),
  AudioEditionDisplay('ar.husary', 'Al-Husary'),
];

final audioEditionsProvider = FutureProvider<List<AudioEditionDisplay>>((ref) async {
  final api = ref.read(apiProvider);
  try {
    final raw = await api.fetchAudioEditions();
    final list = raw.map((e) {
      final m = e as Map<String, dynamic>;
      return AudioEditionDisplay(m['identifier'] as String, m['name'] as String);
    }).toList();
    // Merge defaults at top, unique by id
    final byId = <String, AudioEditionDisplay>{
      for (final d in list) d.id: d,
    };
    for (final d in defaultAudioEditions) {
      byId[d.id] = d; // prefer friendly names for defaults
    }
    // Ensure defaults appear first, then others sorted by name
    final others = byId.values.where((e) => !defaultAudioEditions.any((d) => d.id == e.id)).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final ordered = [
      ...defaultAudioEditions,
      ...others,
    ];
    return ordered;
  } catch (_) {
    // Fallback to defaults if API fails
    return defaultAudioEditions;
  }
});

// Surah info text (Quran.com) in Indonesian, with simple HTML cleanup
final surahInfoProvider = FutureProvider.family<String?, int>((ref, surahNumber) async {
  final api = ref.read(quranComApiProvider);
  final html = await api.fetchChapterInfoText(surahNumber, language: 'id');
  if (html == null) return null;
  // Simple cleanup: replace <br> and block tags with newlines, strip remaining tags, decode basic entities
  String text = html
      .replaceAll(RegExp(r'<\s*br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</\s*p\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</\s*h[1-6]\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
  // Normalize multiple newlines
  text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  return text;
});

final selectedEditionProvider = StateProvider<AudioEditionDisplay>((ref) => defaultAudioEditions.first);

// Surah list provider
final surahListProvider = FutureProvider<List<SurahSummary>>((ref) async {
  final api = ref.read(apiProvider);
  final raw = await api.fetchSurahList();
  return raw.map((e) => SurahSummary.fromJson(e as Map<String, dynamic>)).toList();
});

// Search query state
final searchQueryProvider = StateProvider<String>((ref) => '');

// Filtered list based on search
final filteredSurahListProvider = Provider<List<SurahSummary>>((ref) {
  final list = ref.watch(surahListProvider).maybeWhen(data: (d) => d, orElse: () => <SurahSummary>[]);
  final q = ref.watch(searchQueryProvider).toLowerCase();
  if (q.isEmpty) return list;
  return list.where((s) =>
    s.number.toString().contains(q) ||
    s.name.toLowerCase().contains(q) ||
    s.englishName.toLowerCase().contains(q)
  ).toList();
});

// Surah details provider combining Arabic, transliteration (optional), Indonesian translation, and audio URLs
class SurahDetailState {
  final SurahSummary summary;
  final List<AyahComposite> ayahs;
  SurahDetailState({required this.summary, required this.ayahs});
}

final surahDetailProvider = FutureProvider.family<SurahDetailState, int>((ref, number) async {
  final api = ref.read(apiProvider);
  // Editions
  const arabic = 'quran-uthmani';
  const translit = 'en.transliteration'; // English transliteration (fallback)
  const translationId = 'id.indonesian'; // Indonesian translation (fallback)
  final qari = ref.watch(selectedEditionProvider).id;

  // Fetch editions in parallel
  final results = await Future.wait([
    api.fetchSurahEdition(number, arabic),
    api.fetchSurahEdition(number, translit),
    api.fetchSurahEdition(number, translationId),
    api.fetchSurahEdition(number, qari),
  ]);

  final meta = results[0];
  final summary = SurahSummary(
    number: meta['number'] as int,
    name: meta['name'] as String,
    englishName: meta['englishName'] as String,
    revelationType: meta['revelationType'] as String,
    numberOfAyahs: meta['numberOfAyahs'] as int,
  );

  List<dynamic> a = (results[0]['ayahs'] as List<dynamic>);
  List<dynamic> tlat = (results[1]['ayahs'] as List<dynamic>);
  List<dynamic> trId = (results[2]['ayahs'] as List<dynamic>);
  List<dynamic> aud = (results[3]['ayahs'] as List<dynamic>);

  final ayahs = <AyahComposite>[];
  for (var i = 0; i < a.length; i++) {
    final ar = a[i] as Map<String, dynamic>;
    final tl = i < tlat.length ? tlat[i] as Map<String, dynamic> : {};
    final tr = i < trId.length ? trId[i] as Map<String, dynamic> : {};
    final au = i < aud.length ? aud[i] as Map<String, dynamic> : {};
    final primaryAudio = (au['audio'] as String?)?.trim();
    final secondaryList = (au['audioSecondary'] is List) ? (au['audioSecondary'] as List) : const [];
    final secondaryAudio = secondaryList.isNotEmpty ? (secondaryList.first as String?) : null;
    ayahs.add(AyahComposite(
      numberInSurah: ar['numberInSurah'] as int,
      arabic: (ar['text'] ?? '') as String,
      transliteration: tl['text'] as String?,
      translationId: tr['text'] as String?,
      audioUrl: (primaryAudio != null && primaryAudio.isNotEmpty)
          ? primaryAudio
          : (secondaryAudio != null && secondaryAudio.isNotEmpty ? secondaryAudio : null),
    ));
  }

  return SurahDetailState(summary: summary, ayahs: ayahs);
});

// Juz details provider combining Arabic, transliteration, Indonesian translation, and audio URLs
class JuzDetailState {
  final int juz;
  final List<JuzAyah> ayahs;
  JuzDetailState({required this.juz, required this.ayahs});
}

final juzDetailProvider = FutureProvider.family<JuzDetailState, int>((ref, juzNumber) async {
  final api = ref.read(apiProvider);
  const arabic = 'quran-uthmani';
  const translit = 'en.transliteration';
  const translationId = 'id.indonesian';
  final qari = ref.watch(selectedEditionProvider).id;

  final results = await Future.wait([
    api.fetchJuzEdition(juzNumber, arabic),
    api.fetchJuzEdition(juzNumber, translit),
    api.fetchJuzEdition(juzNumber, translationId),
    api.fetchJuzEdition(juzNumber, qari),
  ]);

  List<dynamic> a = (results[0]['ayahs'] as List<dynamic>);
  List<dynamic> tlat = (results[1]['ayahs'] as List<dynamic>);
  List<dynamic> trId = (results[2]['ayahs'] as List<dynamic>);
  List<dynamic> aud = (results[3]['ayahs'] as List<dynamic>);

  final list = <JuzAyah>[];
  final len = a.length;
  for (var i = 0; i < len; i++) {
    final ar = a[i] as Map<String, dynamic>;
    final tl = i < tlat.length ? tlat[i] as Map<String, dynamic> : const {};
    final tr = i < trId.length ? trId[i] as Map<String, dynamic> : const {};
    final au = i < aud.length ? aud[i] as Map<String, dynamic> : const {};

    final surahMeta = (ar['surah'] as Map<String, dynamic>);
    final primaryAudio = (au['audio'] as String?)?.trim();
    final secondaryList = (au['audioSecondary'] is List) ? (au['audioSecondary'] as List) : const [];
    final secondaryAudio = secondaryList.isNotEmpty ? (secondaryList.first as String?) : null;

    list.add(JuzAyah(
      surahNumber: surahMeta['number'] as int,
      surahName: surahMeta['name'] as String,
      numberInSurah: ar['numberInSurah'] as int,
      arabic: (ar['text'] ?? '') as String,
      transliteration: tl['text'] as String?,
      translationId: tr['text'] as String?,
      audioUrl: (primaryAudio != null && primaryAudio.isNotEmpty)
          ? primaryAudio
          : (secondaryAudio != null && secondaryAudio.isNotEmpty ? secondaryAudio : null),
    ));
  }

  return JuzDetailState(juz: juzNumber, ayahs: list);
});

// Audio player provider (single instance)
final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(() => player.dispose());
  return player;
});

// Bookmark (last read)
class LastRead {
  final int surah;
  final int ayah;
  LastRead(this.surah, this.ayah);
}

final lastReadProvider = FutureProvider<LastRead?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final s = prefs.getInt('last_read_surah');
  final a = prefs.getInt('last_read_ayah');
  if (s != null && a != null) return LastRead(s, a);
  return null;
});

final lastReadControllerProvider = Provider((ref) => _LastReadController());

class _LastReadController {
  Future<void> save(int surah, int ayah) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_read_surah', surah);
    await prefs.setInt('last_read_ayah', ayah);
  }
}

// Bookmarks list (multiple entries)
class Bookmark {
  final int surah;
  final int ayah;
  final String? surahName;
  final DateTime? savedAt;
  const Bookmark(this.surah, this.ayah, {this.surahName, this.savedAt});

  Map<String, dynamic> toJson() => {
        'surah': surah,
        'ayah': ayah,
        if (surahName != null) 'surahName': surahName,
        if (savedAt != null) 'savedAt': savedAt!.toIso8601String(),
      };
  factory Bookmark.fromJson(Map<String, dynamic> j) => Bookmark(
        j['surah'] as int,
        j['ayah'] as int,
        surahName: j['surahName'] as String?,
        savedAt: j['savedAt'] != null ? DateTime.tryParse(j['savedAt'] as String) : null,
      );

  @override
  bool operator ==(Object other) => other is Bookmark && other.surah == surah && other.ayah == ayah;
  @override
  int get hashCode => Object.hash(surah, ayah);
}

final bookmarksProvider = FutureProvider<List<Bookmark>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getStringList('bookmarks') ?? <String>[];
  final list = <Bookmark>[];
  for (final s in raw) {
    try {
      final m = jsonDecode(s) as Map<String, dynamic>;
      list.add(Bookmark.fromJson(m));
    } catch (_) {}
  }
  return list;
});

final bookmarkControllerProvider = Provider((ref) => _BookmarkController(ref));

class _BookmarkController {
  final Ref _ref;
  _BookmarkController(this._ref);

  Future<List<Bookmark>> _get() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('bookmarks') ?? <String>[];
    return raw.map((s) {
      try { return Bookmark.fromJson(jsonDecode(s) as Map<String, dynamic>); } catch (_) { return null; }
    }).whereType<Bookmark>().toList();
  }

  Future<void> _save(List<Bookmark> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = items.map((b) => jsonEncode(b.toJson())).toList();
    await prefs.setStringList('bookmarks', raw);
    _ref.invalidate(bookmarksProvider);
  }

  Future<void> add(Bookmark b) async {
    final list = await _get();
    if (!list.contains(b)) {
      list.add(b);
      await _save(list);
    }
  }

  Future<void> remove(Bookmark b) async {
    final list = await _get();
    list.remove(b);
    await _save(list);
  }

  Future<void> toggle(Bookmark b) async {
    final list = await _get();
    if (list.contains(b)) {
      list.remove(b);
    } else {
      list.add(b);
    }
    await _save(list);
  }

  Future<void> toggleWithMeta({required int surah, required int ayah, String? surahName}) async {
    final list = await _get();
    final probe = Bookmark(surah, ayah);
    final idx = list.indexOf(probe);
    if (idx >= 0) {
      list.removeAt(idx);
    } else {
      list.add(Bookmark(surah, ayah, surahName: surahName, savedAt: DateTime.now()));
    }
    await _save(list);
  }

  Future<void> clearAll() async {
    await _save([]);
  }
}

// Recommended surah numbers for quick access
final recommendedSurahNumbers = [1, 2, 18, 19, 36, 55, 56, 67, 112, 113, 114];

class _NotesController {
  Future<List<int>> _getIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('notes_surah_index') ?? <String>[];
    return raw.map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toList();
  }

  Future<void> _setIndex(List<int> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('notes_surah_index', list.map((e) => e.toString()).toList());
  }

  Future<String?> getSurah(int surah) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('note_surah_$surah');
  }

  Future<void> setSurah(int surah, String text) async {
    final prefs = await SharedPreferences.getInstance();
    if (text.trim().isEmpty) {
      await prefs.remove('note_surah_$surah');
      final idx = await _getIndex();
      idx.remove(surah);
      await _setIndex(idx);
    } else {
      await prefs.setString('note_surah_$surah', text);
      final idx = await _getIndex();
      if (!idx.contains(surah)) {
        idx.add(surah);
        idx.sort();
        await _setIndex(idx);
      } else {
        await _setIndex(idx);
      }
    }
  }

  Future<List<int>> listSurahWithNotes() async {
    return _getIndex();
  }
}

final notesControllerProvider = Provider((ref) => _NotesController());

final surahNoteProvider = FutureProvider.family<String?, int>((ref, surah) async {
  final ctrl = ref.read(notesControllerProvider);
  return ctrl.getSurah(surah);
});

final surahNotesIndexProvider = FutureProvider<List<int>>((ref) async {
  final ctrl = ref.read(notesControllerProvider);
  return ctrl.listSurahWithNotes();
});
