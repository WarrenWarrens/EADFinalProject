import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vocab_record.dart';

/// Persists per-word learning data to SharedPreferences.
///
/// Each word is stored as a JSON blob keyed by its wordId inside a
/// single SharedPreferences string ('vocab_records'). This keeps reads
/// and writes simple and atomic.
///
/// Vocal attempts can now optionally include the heard/reference IPA
/// strings from the phoneme scorer. When provided, they're appended to
/// the record's `phoneticHistory`, enabling the stats page to draw
/// pronunciation-over-time charts and surface phoneme-level drift.
class VocabTrackingService {
  static const String _storageKey = 'vocab_records';

  // ── In-memory cache ────────────────────────────────────────────────────────
  Map<String, VocabRecord>? _cache;

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
  /// continuous 0.0–1.0 from the phoneme scorer. Pass `heardIpa` and
  /// `referenceIpa` when available so the phonetic history is populated
  /// for trend analysis on the stats page.
  Future<void> recordVocalAttempt({
    required String wordId,
    required String displayText,
    required double score,
    String source = 'vocal',
    String? heardIpa,
    String? referenceIpa,
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
    record.addVocalScore(
      score,
      heardIpa: heardIpa,
      referenceIpa: referenceIpa,
      attemptSource: source,
    );
    await _persist();
  }

  /// Record a non-vocal (MC, matching, fill-in-blank) attempt.
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

  /// Get all tracked words, sorted by rolling average ascending
  /// (hardest first).
  Future<List<VocabRecord>> getAllRecords() async {
    final all = await _loadAll();
    final list = all.values.toList()
      ..sort((a, b) => a.rollingAverage.compareTo(b.rollingAverage));
    return list;
  }

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

  // ── Phonetic history queries ───────────────────────────────────────────
  //
  // These are the new public surface for "how is my pronunciation doing
  // over time". They flatten phonetic attempts across words so the stats
  // page can draw a single overall pronunciation timeline, or zoom into
  // one word.

  /// Every vocal attempt the user has ever made, oldest first, across
  /// all words. Useful for an overall pronunciation-over-time chart.
  Future<List<PhoneticAttempt>> getAllPhoneticAttempts() async {
    final all = await _loadAll();
    final list = <PhoneticAttempt>[];
    for (final r in all.values) {
      list.addAll(r.phoneticHistory);
    }
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }

  /// Phonetic attempts for one word, oldest first.
  Future<List<PhoneticAttempt>> getPhoneticHistory(String wordId) async {
    final all = await _loadAll();
    final r = all[wordId];
    if (r == null) return const [];
    return List<PhoneticAttempt>.from(r.phoneticHistory);
  }

  /// Daily-average pronunciation score across all words in the given
  /// rolling window (default last 30 days). Returns a list of
  /// (day, average, attemptCount) tuples sorted ascending by day. Days
  /// with no attempts are skipped — the consumer can interpolate or
  /// treat gaps as missing data as it sees fit.
  Future<List<({DateTime day, double avg, int count})>>
  getDailyPronunciationTrend({int windowDays = 30}) async {
    final attempts = await getAllPhoneticAttempts();
    if (attempts.isEmpty) return [];
    final cutoff = DateTime.now().subtract(Duration(days: windowDays));
    final buckets = <String, List<double>>{};
    for (final a in attempts) {
      if (a.timestamp.isBefore(cutoff)) continue;
      final key =
          '${a.timestamp.year}-${a.timestamp.month}-${a.timestamp.day}';
      buckets.putIfAbsent(key, () => []).add(a.score);
    }
    final out = <({DateTime day, double avg, int count})>[];
    buckets.forEach((k, scores) {
      final parts = k.split('-').map(int.parse).toList();
      final day = DateTime(parts[0], parts[1], parts[2]);
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      out.add((day: day, avg: avg, count: scores.length));
    });
    out.sort((a, b) => a.day.compareTo(b.day));
    return out;
  }

  /// Words whose pronunciation is most-improved (positive trend) in
  /// the recent window. Useful for "wins" UI.
  Future<List<({VocabRecord record, double delta})>>
  getMostImprovedPronunciation({int limit = 5}) async {
    final all = await _loadAll();
    final scored = <({VocabRecord record, double delta})>[];
    for (final r in all.values) {
      final t = r.pronunciationTrend();
      if (t == null) continue;
      scored.add((record: r, delta: t));
    }
    scored.sort((a, b) => b.delta.compareTo(a.delta));
    return scored.take(limit).toList();
  }

  /// Words whose pronunciation is regressing — surface for review.
  Future<List<({VocabRecord record, double delta})>>
  getStrugglingPronunciation({int limit = 5}) async {
    final all = await _loadAll();
    final scored = <({VocabRecord record, double delta})>[];
    for (final r in all.values) {
      final t = r.pronunciationTrend();
      if (t == null) continue;
      scored.add((record: r, delta: t));
    }
    scored.sort((a, b) => a.delta.compareTo(b.delta));
    return scored.take(limit).toList();
  }

  /// Clear the in-memory cache (e.g. after a profile reset).
  void clearCache() => _cache = null;
}