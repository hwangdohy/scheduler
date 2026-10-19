import 'dart:convert';
import 'package:http/http.dart' as http;

/// Wraps the Gemini API call used to compress a diary entry into 2-3
/// keywords (e.g. "workout, reading, tired").
///
/// Requires the user to paste their own Gemini API key in Settings —
/// this app never ships with a bundled key. Get one at
/// https://aistudio.google.com/apikey
class GeminiService {
  GeminiService({this.model = 'gemini-2.5-flash'});

  /// Model name is kept configurable in one place in case Google
  /// renames/retires a model.
  final String model;

  Uri _endpoint(String apiKey) => Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
      );

  /// Returns a short comma-separated keyword summary of [diaryText].
  /// Falls back to a naive local heuristic if no API key is configured
  /// or the request fails, so the app keeps working offline.
  Future<String> summarizeDiary(String diaryText, {required String apiKey}) async {
    final trimmed = diaryText.trim();
    if (trimmed.isEmpty) return '';

    if (apiKey.isEmpty) {
      return _localFallbackSummary(trimmed);
    }

    try {
      final prompt =
          'Summarize the following diary entry into exactly 2 to 3 short '
          'keywords capturing mood/activities, comma-separated, lowercase, '
          'no punctuation, no explanation. Diary entry:\n"""$trimmed"""';

      final response = await http
          .post(
            _endpoint(apiKey),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
              'generationConfig': {
                'temperature': 0.4,
                'maxOutputTokens': 32,
              },
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return _localFallbackSummary(trimmed);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        return _localFallbackSummary(trimmed);
      }
      final content = candidates.first['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      final text = parts?.first['text'] as String?;
      if (text == null || text.trim().isEmpty) {
        return _localFallbackSummary(trimmed);
      }
      return text.trim().replaceAll('\n', ' ');
    } catch (_) {
      return _localFallbackSummary(trimmed);
    }
  }

  /// Very small offline fallback: picks the longest words as "keywords"
  /// so the feature still produces something without network/API key.
  String _localFallbackSummary(String text) {
    final words = text
        .replaceAll(RegExp(r'[.,!?~\n]'), ' ')
        .split(' ')
        .map((w) => w.trim())
        .where((w) => w.length >= 2)
        .toSet()
        .toList();
    words.sort((a, b) => b.length.compareTo(a.length));
    final keywords = words.take(3).toList();
    return keywords.join(', ');
  }
}
