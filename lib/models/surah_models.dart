class SurahSummary {
  final int number;
  final String name;
  final String englishName;
  final String revelationType;
  final int numberOfAyahs;

  SurahSummary({
    required this.number,
    required this.name,
    required this.englishName,
    required this.revelationType,
    required this.numberOfAyahs,
  });

  factory SurahSummary.fromJson(Map<String, dynamic> json) {
    return SurahSummary(
      number: json['number'] as int,
      name: json['name'] as String,
      englishName: json['englishName'] as String,
      revelationType: json['revelationType'] as String,
      numberOfAyahs: json['numberOfAyahs'] as int,
    );
  }
}

class JuzAyah {
  final int surahNumber;
  final String surahName;
  final int numberInSurah;
  final String arabic;
  final String? transliteration;
  final String? translationId;
  final String? audioUrl;

  JuzAyah({
    required this.surahNumber,
    required this.surahName,
    required this.numberInSurah,
    required this.arabic,
    this.transliteration,
    this.translationId,
    this.audioUrl,
  });
}

class EditionInfo {
  final String identifier;
  final String language;
  final String name;
  final String type;

  EditionInfo({
    required this.identifier,
    required this.language,
    required this.name,
    required this.type,
  });

  factory EditionInfo.fromJson(Map<String, dynamic> json) {
    return EditionInfo(
      identifier: json['identifier'] as String,
      language: json['language'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
    );
  }
}

class AyahComposite {
  final int numberInSurah;
  final String arabic;
  final String? transliteration;
  final String? translationId;
  final String? audioUrl;

  AyahComposite({
    required this.numberInSurah,
    required this.arabic,
    this.transliteration,
    this.translationId,
    this.audioUrl,
  });
}
