// lib/services/dictionary_service.dart
//
// Dictionary lookup backed by bundled JSON assets:
//   • Na'vi  — assets/dict/navi_reykunyu.json  (CC-BY-SA-NC 3.0, from reykunyu.lu)
//   • Klingon — assets/dict/klingon_boqwi.json (Apache 2.0, from De7vID/klingon-assistant-data)
//
// Both dictionaries are loaded once from assets and cached in memory for the
// session.  Searches match against the target-language word AND the English
// definition (case-insensitive), with results ranked: exact → prefix → substring.
//
// Audio:
//   • Na'vi  — downloaded on demand from reykunyu.lu/fam/ and cached to disk.
//   • Klingon — no pre-generated audio.  The study page uses on-device TTS
//              (flutter_tts) when the user taps the pronunciation button.
//
// History is stored in SharedPreferences (ring-buffer of 25 entries, newest first).

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dictionary_entry.dart';
import '../widgets/app_language.dart';

class DictionaryService {
  static const _historyKey = 'dictionary_history';
  static const _maxHistory = 25;

  // ── Asset paths ────────────────────────────────────────────────────────────

  static const _naviAssetPath = 'assets/dict/navi_reykunyu.json';
  static const _klingonAssetPath = 'assets/dict/klingon_boqwi.json';

  // ── In-memory caches (loaded once per session) ─────────────────────────────

  static List<Map<String, dynamic>>? _naviDictCache;
  static List<Map<String, dynamic>>? _klingonDictCache;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Look up a single word by exact ref for use in lessons.
  /// Does NOT save to history. Returns the first exact-matching result, or null.
  Future<DictionaryResult?> lookupWord(String ref, AppLanguage language) async {
    final results = language == AppLanguage.navi
        ? await _searchNavi(ref.trim())
        : await _searchKlingon(ref.trim());
    final refLower = ref.trim().toLowerCase();
    for (final r in results) {
      if (r.word.toLowerCase() == refLower) return r;
    }
    return results.isEmpty ? null : results.first;
  }

  /// Search [query] for [language].
  ///
  /// Saves to history automatically when results are non-empty.
  /// Never throws — returns an entry with an empty result list on failure.
  Future<DictionaryEntry> search(String query, AppLanguage language) async {
    final q = query.trim();
    if (q.isEmpty) {
      return DictionaryEntry(
        query: q,
        language: language,
        searchedAt: DateTime.now(),
        results: [],
      );
    }

    final results = language == AppLanguage.navi
        ? await _searchNavi(q)
        : await _searchKlingon(q);

    final entry = DictionaryEntry(
      query: q,
      language: language,
      searchedAt: DateTime.now(),
      results: results,
    );

    if (results.isNotEmpty) await _addToHistory(entry);
    return entry;
  }

  // ── History ────────────────────────────────────────────────────────────────

  /// Load saved history, newest first.
  Future<List<DictionaryEntry>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((e) => DictionaryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> deleteEntry(int index) async {
    final history = await getHistory();
    if (index < 0 || index >= history.length) return;
    history.removeAt(index);
    await _saveHistory(history);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  // ── Asset loading ──────────────────────────────────────────────────────────

  /// Load a JSON array from a bundled asset.  Returns null on failure.
  Future<List<Map<String, dynamic>>?> _loadAsset(String path) async {
    try {
      final raw = await rootBundle.loadString(path);
      final data = jsonDecode(raw);
      if (data is! List) return null;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      print('[Dictionary] Failed to load $path: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> _loadNaviDict() async {
    if (_naviDictCache != null) return _naviDictCache;
    _naviDictCache = await _loadAsset(_naviAssetPath);
    if (_naviDictCache != null) {
      print("[Dictionary] Na'vi dict loaded: ${_naviDictCache!.length} entries");
    }
    return _naviDictCache;
  }

  Future<List<Map<String, dynamic>>?> _loadKlingonDict() async {
    if (_klingonDictCache != null) return _klingonDictCache;
    _klingonDictCache = await _loadAsset(_klingonAssetPath);
    if (_klingonDictCache != null) {
      print('[Dictionary] Klingon dict loaded: ${_klingonDictCache!.length} entries');
    }
    return _klingonDictCache;
  }

  // ── Na'vi search ───────────────────────────────────────────────────────────

  /// Search the bundled Na'vi dictionary by Na'vi word or English definition.
  ///
  /// Results ranked: exact → prefix → substring.  Caps at 20.
  /// Audio files are downloaded on demand from reykunyu.lu and cached locally.
  Future<List<DictionaryResult>> _searchNavi(String query) async {
    final dict = await _loadNaviDict();
    if (dict == null) return [];

    final qLower = query.toLowerCase();

    final exact = <DictionaryResult>[];
    final prefix = <DictionaryResult>[];
    final contains = <DictionaryResult>[];

    for (final entry in dict) {
      final word = (entry['w'] as String?) ?? '';
      final pos = (entry['p'] as String?) ?? '';
      final defn = (entry['d'] as String?) ?? '';

      final wLower = word.toLowerCase();
      final dLower = defn.toLowerCase();

      final bool isMatch = wLower.contains(qLower) || dLower.contains(qLower);
      if (!isMatch) continue;

      // Extract pronunciation data.
      String? syllables;
      String? ipa;
      final audioList = <DictionaryAudio>[];

      final pr = entry['pr'];
      if (pr is Map) {
        syllables = (pr['s'] as String?);

        // IPA (may be absent in bundled data — populated by Reykunyu API only).
        final ipaObj = pr['i'];
        if (ipaObj is Map) {
          ipa = (ipaObj['FN'] ?? ipaObj['RN'])?.toString();
        }

        // Download audio on demand from reykunyu.lu.
        final audios = pr['a'];
        if (audios is List) {
          for (final a in audios) {
            if (a is! Map) continue;
            final file = (a['f'] as String?) ?? '';
            final speaker = (a['sp'] as String?) ?? 'unknown';
            if (file.isEmpty) continue;
            final localPath = await _downloadNaviAudio(file);
            if (localPath != null) {
              audioList.add(DictionaryAudio(localPath: localPath, speaker: speaker));
            }
          }
        }
      }

      final result = DictionaryResult(
        word: word,
        wordType: pos,
        translation: defn,
        syllables: syllables,
        ipa: ipa,
        audio: audioList,
      );

      if (wLower == qLower || dLower == qLower) {
        exact.add(result);
      } else if (wLower.startsWith(qLower) || dLower.startsWith(qLower)) {
        prefix.add(result);
      } else {
        contains.add(result);
      }

      if (exact.length + prefix.length + contains.length >= 20) break;
    }

    return [...exact, ...prefix, ...contains];
  }

  /// Download a Na'vi audio file from Reykunyu and cache it permanently.
  /// Returns the local path, or null on failure.
  Future<String?> _downloadNaviAudio(String filename) async {
    try {
      final dir = await getApplicationDocumentsDirectory();

      // Sanitise the filename for local storage (Na'vi words contain glottal
      // stops and other characters that are tricky on some file systems).
      final sanitized =
      filename.replaceAll(RegExp(r'[^a-zA-Z0-9_.\-/]'), '_');
      final path = '${dir.path}/dict_$sanitized';

      if (await File(path).exists()) return path; // cache hit

      final url = Uri.parse('https://reykunyu.lu/fam/$filename');
      final res = await http.get(url).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        print('[Dictionary] Na\'vi audio download failed ($filename): ${res.statusCode}');
        return null;
      }

      // Ensure parent directory exists (files are in speaker sub-folders).
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(res.bodyBytes);
      print('[Dictionary] Cached Na\'vi audio: $path');
      return path;
    } catch (e) {
      print('[Dictionary] Na\'vi audio download error: $e');
      return null;
    }
  }

  // ── Klingon search ─────────────────────────────────────────────────────────

  /// Search the bundled boQwI' dictionary by Klingon word or English definition.
  ///
  /// Results ranked: exact → prefix → substring.  Caps at 20.
  /// Audio is NOT pre-generated — the study page uses on-device TTS
  /// (via TtsService.speak) when the user taps the pronunciation button.
  Future<List<DictionaryResult>> _searchKlingon(String query) async {
    final dict = await _loadKlingonDict();
    if (dict == null) return [];

    final qLower = query.toLowerCase();

    final exact = <DictionaryResult>[];
    final prefix = <DictionaryResult>[];
    final contains = <DictionaryResult>[];

    for (final entry in dict) {
      final word = (entry['w'] as String?) ?? '';
      final pos = (entry['p'] as String?) ?? '';
      final defn = (entry['d'] as String?) ?? '';
      final tags = (entry['t'] as String?) ?? '';

      final wLower = word.toLowerCase();
      final dLower = defn.toLowerCase();
      final tLower = tags.toLowerCase();

      final bool isMatch = wLower.contains(qLower) ||
          dLower.contains(qLower) ||
          tLower.contains(qLower);
      if (!isMatch) continue;

      final result = DictionaryResult(
        word: word,
        wordType: pos,
        translation: defn,
        audio: [], // no pre-generated audio — handled by on-device TTS
      );

      if (wLower == qLower || dLower == qLower) {
        exact.add(result);
      } else if (wLower.startsWith(qLower) || dLower.startsWith(qLower)) {
        prefix.add(result);
      } else {
        contains.add(result);
      }

      if (exact.length + prefix.length + contains.length >= 20) break;
    }

    return [...exact, ...prefix, ...contains];
  }

  // ── History persistence ────────────────────────────────────────────────────

  Future<void> _addToHistory(DictionaryEntry entry) async {
    final history = await getHistory();
    // Remove duplicate (same query + language) before re-inserting at top.
    history.removeWhere(
          (e) =>
      e.query.toLowerCase() == entry.query.toLowerCase() &&
          e.language == entry.language,
    );
    history.insert(0, entry);
    if (history.length > _maxHistory) {
      history.removeRange(_maxHistory, history.length);
    }
    await _saveHistory(history);
  }

  Future<void> _saveHistory(List<DictionaryEntry> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _historyKey,
      jsonEncode(history.map((e) => e.toJson()).toList()),
    );
  }
}