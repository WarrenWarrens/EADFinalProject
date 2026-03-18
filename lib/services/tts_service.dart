// lib/services/tts_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

const TtsProvider kActiveTtsProvider = TtsProvider.googleTranslate;
// const TtsProvider kActiveTtsProvider = TtsProvider.elevenLabs;

const String kElevenLabsApiKey  = 'YOUR_ELEVENLABS_API_KEY_HERE';
const String kElevenLabsVoiceId = '21m00Tcm4TlvDq8ikWAM';

enum TtsProvider { googleTranslate, elevenLabs }

class TtsService {

  // ── Public entry point ─────────────────────────────────────────────────────
  //
  // Pass both the Na'vi word and its English translation.
  // We query Reykunyu via English (language=en) to avoid Na'vi diacritic
  // encoding issues, then match the result back to naviWord.

  static Future<String?> getAudioFile({
    required String naviWord,
    required String english,
    required String ttsHint,
  }) async {
    final reykunyuPath = await _reykunyu(naviWord: naviWord, english: english);
    if (reykunyuPath != null) return reykunyuPath;
    print('[TTS] No Reykunyu audio for "$naviWord" — using TTS fallback');
    return _fallback(ttsHint);
  }

  // ── Reykunyu community audio ───────────────────────────────────────────────
  //
  // Strategy: query the English translation with language=en.
  // Results come back in "toNa'vi" as a list of word objects, each with audio.
  // We find the entry whose na'vi field matches naviWord (case-insensitive).
  //
  // This avoids percent-encoding Na'vi diacritics (ì, ä, etc.) directly,
  // which was causing 400 errors from the server.
  //
  // For phrases: we use the first word of the English translation as the query,
  // since phrases have no single community audio entry anyway and will fall
  // through to TTS.

  static Future<String?> _reykunyu({
    required String naviWord,
    required String english,
  }) async {
    // For phrases, Reykunyu has no per-phrase audio — skip straight to TTS.
    if (naviWord.trim().contains(' ')) {
      print('[TTS] Skipping Reykunyu for phrase "$naviWord" — using TTS');
      return null;
    }

    try {
      // Use the English translation as the search query with language=en.
      // e.g. "Hello" → /api/fwew-search?query=hello&language=en
      // This returns plain ASCII in the URL, no diacritic encoding problems.
      final uri = Uri(
        scheme: 'https',
        host: 'reykunyu.lu',
        path: '/api/fwew-search',
        queryParameters: {
          'query': english.toLowerCase(),
          'language': 'en',
        },
      );

      print('[TTS] Querying Reykunyu: $uri');

      final res = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        print('[TTS] Reykunyu HTTP ${res.statusCode}');
        return null;
      }

      final data = jsonDecode(res.body);
      if (data is! Map) return null;

      // English → Na'vi results live in "toNa'vi".
      final toNavi = data["toNa\u2019vi"]   // right single quote '
          ?? data["toNa'vi"];               // ASCII apostrophe fallback
      if (toNavi is! List || toNavi.isEmpty) return null;

      // Find the entry that matches our Na'vi word (case-insensitive).
      // The "na'vi" field on each result holds the Na'vi spelling.
      final naviLower = naviWord.toLowerCase();
      for (final wordObj in toNavi) {
        if (wordObj is! Map) continue;

        final resultNavi = (wordObj["na\u2019vi"] ?? wordObj["na'vi"] ?? '')
            .toString()
            .toLowerCase();

        if (resultNavi != naviLower) continue;

        // Matched — now extract audio.
        final audioPath = _extractAudio(wordObj, naviWord);
        if (audioPath != null) return audioPath;
      }

      print('[TTS] No matching Na\'vi entry in Reykunyu results for "$naviWord"');
      return null;

    } catch (e) {
      print('[TTS] Reykunyu error for "$naviWord": $e');
      return null;
    }
  }

  // Walks pronunciation → audio for a single word object and fetches the first
  // available mp3. Returns the local file path or null if none found.
  static Future<String?> _extractAudio(Map wordObj, String naviWord) async {
    final pronunciation = wordObj['pronunciation'];
    if (pronunciation is! List || pronunciation.isEmpty) return null;

    for (final pronun in pronunciation) {
      if (pronun is! Map) continue;

      final audioList = pronun['audio'];
      if (audioList is! List || audioList.isEmpty) continue;

      for (final audioEntry in audioList) {
        if (audioEntry is! Map) continue;

        final file = audioEntry['file'];
        if (file is! String || file.isEmpty) continue;

        final audioUrl = 'https://reykunyu.lu/fam/$file';
        final audioRes = await http
            .get(Uri.parse(audioUrl))
            .timeout(const Duration(seconds: 10));

        if (audioRes.statusCode != 200) {
          print('[TTS] Audio fetch failed for $file: ${audioRes.statusCode}');
          continue;
        }

        final speaker = audioEntry['speaker'] ?? 'unknown';
        print('[TTS] Reykunyu audio OK for "$naviWord": $file (speaker: $speaker)');
        return _saveTempFile(audioRes.bodyBytes, 'mp3');
      }
    }
    return null;
  }

  // ── TTS fallback ───────────────────────────────────────────────────────────

  static Future<String?> _fallback(String text) async {
    switch (kActiveTtsProvider) {
      case TtsProvider.googleTranslate:
        return _googleTranslate(text);
      case TtsProvider.elevenLabs:
        return _elevenLabs(text);
    }
  }

  static Future<String?> _googleTranslate(String text) async {
    try {
      final uri = Uri.parse(
        'https://translate.google.com/translate_tts'
            '?ie=UTF-8'
            '&q=${Uri.encodeComponent(text)}'
            '&tl=en'
            '&client=tw-ob',
      );
      final res = await http.get(uri, headers: {
        'User-Agent': 'Mozilla/5.0',
      }).timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        print('[TTS] Google error: ${res.statusCode}');
        return null;
      }
      return _saveTempFile(res.bodyBytes, 'mp3');
    } catch (e) {
      print('[TTS] Google exception: $e');
      return null;
    }
  }

  static Future<String?> _elevenLabs(String text) async {
    if (kElevenLabsApiKey == 'YOUR_ELEVENLABS_API_KEY_HERE') {
      print('[TTS] ElevenLabs key not set');
      return null;
    }
    try {
      final res = await http.post(
        Uri.parse(
            'https://api.elevenlabs.io/v1/text-to-speech/$kElevenLabsVoiceId'),
        headers: {
          'xi-api-key': kElevenLabsApiKey,
          'Content-Type': 'application/json',
          'Accept': 'audio/mpeg',
        },
        body: jsonEncode({
          'text': text,
          'model_id': 'eleven_monolingual_v1',
          'voice_settings': {
            'stability': 0.6,
            'similarity_boost': 0.8,
          },
        }),
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) {
        print('[TTS] ElevenLabs error: ${res.statusCode}');
        return null;
      }
      return _saveTempFile(res.bodyBytes, 'mp3');
    } catch (e) {
      print('[TTS] ElevenLabs exception: $e');
      return null;
    }
  }

  static Future<String> _saveTempFile(Uint8List bytes, String ext) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await File(path).writeAsBytes(bytes);
    return path;
  }
}