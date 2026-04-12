// lib/services/tts_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

const String kElevenLabsApiKey  = 'YOUR_ELEVENLABS_API_KEY_HERE';
const String kElevenLabsVoiceId = '21m00Tcm4TlvDq8ikWAM';

class TtsService {

  // ── On-device TTS (flutter_tts) ────────────────────────────────────────────
  //
  // Used for Klingon and as a general fallback when no community recordings
  // exist.  Speaks directly through the device speaker — no file needed.
  // Speech rate is slowed so the engine attempts to sound out syllables rather
  // than spelling individual letters.

  static FlutterTts? _flutterTts;

  // null = not yet attempted; true = engine OK; false = engine unavailable.
  // Once false, all on-device TTS calls are silently skipped rather than
  // retrying a broken binder (e.g. DeadObjectException on certain AVDs).
  static bool? _ttsAvailable;

  static Future<FlutterTts?> _ensureTts() async {
    if (_ttsAvailable == false) return null;
    if (_flutterTts != null) return _flutterTts!;
    try {
      _flutterTts = FlutterTts();
      await _flutterTts!.setLanguage('en-US');
      await _flutterTts!.setSpeechRate(0.4);   // slow — helps with alien words
      await _flutterTts!.setPitch(0.95);
      await _flutterTts!.setVolume(1.0);
      _ttsAvailable = true;
      return _flutterTts!;
    } catch (e) {
      print('[TTS] Engine init failed (TTS binder unavailable?): $e');
      _flutterTts = null;
      _ttsAvailable = false;
      return null;
    }
  }

  /// Initialise the on-device TTS engine without speaking anything. Call this
  /// ahead of the first real [speak] to avoid cold-start latency on the first
  /// tap. Safe to call repeatedly — subsequent calls are no-ops once the
  /// engine is ready.
  ///
  /// Note: do NOT use `speak('')` for warm-up — on some platforms an empty
  /// speak never fires its completion handler, leaving the engine blocked
  /// for the next real call.
  static Future<void> warmUp() async {
    await _ensureTts();
  }

  /// Speak [text] directly through the device speaker.
  /// Returns immediately once speech starts.  Call [stop] to cancel.
  /// Silently no-ops if the on-device TTS engine is unavailable.
  static Future<void> speak(String text) async {
    try {
      final tts = await _ensureTts();
      await tts?.speak(text);
    } catch (e) {
      print('[TTS] Device speak error: $e');
      _ttsAvailable = false;
      _flutterTts = null;
    }
  }

  /// Stop any in-progress device TTS playback.
  static Future<void> stop() async {
    try {
      await _flutterTts?.stop();
    } catch (_) {}
  }

  /// Whether the device TTS engine is currently speaking.
  static bool _isSpeaking = false;
  static bool get isSpeaking => _isSpeaking;

  /// Initialise completion tracking so callers can observe speaking state.
  /// Returns without registering handlers if the engine is unavailable.
  static Future<void> initListeners({
    void Function()? onStart,
    void Function()? onComplete,
  }) async {
    final tts = await _ensureTts();
    if (tts == null) return;
    tts.setStartHandler(() {
      _isSpeaking = true;
      onStart?.call();
    });
    tts.setCompletionHandler(() {
      _isSpeaking = false;
      onComplete?.call();
    });
    tts.setCancelHandler(() {
      _isSpeaking = false;
      onComplete?.call();
    });
    tts.setErrorHandler((msg) {
      _isSpeaking = false;
      onComplete?.call();
      print('[TTS] Engine error: $msg');
    });
  }

  /// Reset the engine availability flag so the next call retries init.
  /// Useful if the app is foregrounded after a TTS service restart.
  static void resetEngine() {
    _flutterTts = null;
    _ttsAvailable = null;
  }

  // ── Public entry point (Na'vi — Reykunyu + fallback) ───────────────────────
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
    return _googleTranslate(ttsHint);
  }

  // ── Single-word audio (for per-word phrase fetching) ───────────────────────
  //
  // Fetches audio for a single Na'vi word. Used when splitting phrases into
  // individual words. Tries Reykunyu direct Na'vi search first, then TTS hint.

  static Future<String?> getSingleWordAudio({
    required String naviWord,
    required String ttsHint,
  }) async {
    // Try Reykunyu with direct Na'vi search
    final reykunyuPath = await _reykunyuDirect(naviWord);
    if (reykunyuPath != null) return reykunyuPath;
    print('[TTS] No Reykunyu audio for word "$naviWord" — using TTS hint');
    return _googleTranslate(ttsHint);
  }

  // ── Plain TTS (no Na'vi / Reykunyu processing) ────────────────────────────

  /// Synthesise [text] to a file using Google Translate TTS.
  /// For Klingon dictionary results, prefer [speak] instead — it uses the
  /// on-device engine which sounds out words rather than spelling them.
  static Future<String?> synthesise(String text) => _googleTranslate(text);

  // ── Reykunyu direct Na'vi search ───────────────────────────────────────────

  static Future<String?> _reykunyuDirect(String naviWord) async {
    if (naviWord.trim().contains(' ')) return null;

    try {
      final uri = Uri(
        scheme: 'https',
        host: 'reykunyu.lu',
        path: '/api/fwew-search',
        queryParameters: {
          'query': naviWord,
          'language': 'navi',
        },
      );

      print('[TTS] Querying Reykunyu (direct): $uri');

      final res = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        print('[TTS] Reykunyu direct HTTP ${res.statusCode}');
        return null;
      }

      final data = jsonDecode(res.body);
      if (data is! Map) return null;

      final fromNavi = data["fromNa\u2019vi"] ?? data["fromNa'vi"];
      if (fromNavi is! List || fromNavi.isEmpty) return null;

      const sieyng = 's\u00ec\u2019eyng';
      final naviLower = naviWord.toLowerCase();

      for (final envelope in fromNavi) {
        if (envelope is! Map) continue;

        final wordList = envelope[sieyng] ?? envelope["sì'eyng"];
        if (wordList is! List) continue;

        for (final wordObj in wordList) {
          if (wordObj is! Map) continue;

          final resultNavi = (wordObj["na\u2019vi"] ?? wordObj["na'vi"] ?? '')
              .toString()
              .toLowerCase();

          if (resultNavi != naviLower) continue;

          final audioPath = await _extractAudio(wordObj, naviWord);
          if (audioPath != null) return audioPath;
        }
      }

      return null;
    } catch (e) {
      print('[TTS] Reykunyu direct error for "$naviWord": $e');
      return null;
    }
  }

  // ── Reykunyu community audio ───────────────────────────────────────────────

  static Future<String?> _reykunyu({
    required String naviWord,
    required String english,
  }) async {
    if (naviWord.trim().contains(' ')) {
      print('[TTS] Skipping Reykunyu for phrase "$naviWord" — using TTS');
      return null;
    }

    try {
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

      final toNavi = data["toNa\u2019vi"] ?? data["toNa'vi"];
      if (toNavi is! List || toNavi.isEmpty) return null;

      final naviLower = naviWord.toLowerCase();
      for (final wordObj in toNavi) {
        if (wordObj is! Map) continue;

        final resultNavi = (wordObj["na\u2019vi"] ?? wordObj["na'vi"] ?? '')
            .toString()
            .toLowerCase();

        if (resultNavi != naviLower) continue;

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

  // ── Google Translate TTS (file-based, for Na'vi fallback) ──────────────────

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

  static Future<String> _saveTempFile(Uint8List bytes, String ext) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await File(path).writeAsBytes(bytes);
    return path;
  }
}