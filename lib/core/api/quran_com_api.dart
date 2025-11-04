import 'dart:convert';
import 'package:http/http.dart' as http;

class QuranComApi {
  static const String baseUrl = 'https://api.quran.com/api/v4';
  final http.Client _client;
  QuranComApi({http.Client? client}) : _client = client ?? http.Client();

  Future<String?> fetchChapterInfoText(int chapterId, {String language = 'id'}) async {
    final uri = Uri.parse('$baseUrl/chapters/$chapterId/info?language=$language');
    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      return null;
    }
    final data = json.decode(res.body) as Map<String, dynamic>;
    final chapterInfo = data['chapter_info'] as Map<String, dynamic>?;
    final text = chapterInfo != null ? chapterInfo['text'] as String? : null;
    return text;
  }
}
