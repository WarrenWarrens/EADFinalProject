import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vocab_record.dart';

/// Persists per-word learning data to SharedPreferences.
///
/// Each word is stored as a JSON blob keyed by its wordId inside a
/// single SharedPreferences string ('vocab_records'). This keeps reads
/// and writes simple and atomic.
class VocabTrackingService {
  static const String _storageKey = 'vocab_records';

  // ── In-memory cache ────────────────────────────────────────────────────────
  Map<String, VocabRecord>? _cache;

  /// Load all records (lazy, cached after first call).
  Future<Map<String, VocabRecord>> _loadAll() async {
    if (_cache != null) return _cache!;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) {
      _cache = {};
      return _cache!;
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _cache = map.map((k, v) =>
          MapEntry(k, VocabRecord.fromJson(v as Map<String, dynamic>)));
    } catch (_) {
      _cache = {};
    }
    return _cache!;
  }

  Future<void> _persist() async {
    if (_cache == null) return;
    final prefs = await SharedPreferences.getInstance();
    final map = _cache!.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString(_storageKey, jsonEncode(map));
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Record a vocal (mimicry/conversation) attempt. Score is the
  /// continuous 0.0–1.0 from the phoneme scorer.
  Future<void> recordVocalAttempt({
    required String wordId,
    required String displayText,
    required double score,
    String source = 'vocal',
  }) async {
    final all = await _loadAll();
    final record = all.putIfAbsent(
      wordId,
          () => VocabRecord(
        wordId: wordId,
        displayText: displayText,
        source: source,
      ),
    );
    record.addVocalScore(score);
    await _persist();
  }

  /// Record a non-vocal (MC, matching, fill-in-blank) attempt.
  /// Binary pass/fail per your design.
  Future<void> recordNonVocalAttempt({
    required String wordId,
    required String displayText,
    required bool correct,
    String source = 'non_vocal',
  }) async {
    final all = await _loadAll();
    final record = all.putIfAbsent(
      wordId,
          () => VocabRecord(
        wordId: wordId,
        displayText: displayText,
        source: source,
      ),
    );
    record.addNonVocalScore(correct);
    await _persist();
  }

  /// Get all tracked words, sorted by rolling average ascending (hardest first).
  /// Hardest words appear largest in the word cloud and tend to land centrally
  /// in the scatter layout.
  Future<List<VocabRecord>> getAllRecords() async {
    final all = await _loadAll();
    final list = all.values.toList()
      ..sort((a, b) => a.rollingAverage.compareTo(b.rollingAverage));
    return list;
  }

  /// Get a single record by id (or null).
  Future<VocabRecord?> getRecord(String wordId) async {
    final all = await _loadAll();
    return all[wordId];
  }

  /// Summary stats for the stats page header.
  Future<({int totalWords, int totalAttempts, double overallAvg})>
      getSummary() async {
    final all = await _loadAll();
    if (all.isEmpty) {
      return (totalWords: 0, totalAttempts: 0, overallAvg: 0.0);
    }
    final totalWords = all.length;
    final totalAttempts =
        all.values.fold<int>(0, (sum, r) => sum + r.totalAttempts);
    final totalScore =
        all.values.fold<double>(0.0, (sum, r) => sum + r.cumulativeScore);
    final overallAvg = totalAttempts > 0 ? totalScore / totalAttempts : 0.0;
    return (
      totalWords: totalWords,
      totalAttempts: totalAttempts,
      overallAvg: overallAvg,
    );
  }

  /// Clear the in-memory cache (e.g. after a profile reset).
  void clearCache() => _cache = null;
}
