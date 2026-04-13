/// Tracks a single word the user has encountered across lessons.
///
/// Maintains two independent rolling buffers (last 20 each) so the stats
/// page can surface where the user struggles: pronunciation (vocal) vs.
/// recall/recognition (non-vocal). Overall score is a 50/50 blend when
/// both exist; otherwise falls back to whichever one has data.
///
/// In addition to numeric scores, vocal attempts now keep a richer
/// `phoneticHistory` — every mimicry attempt stores its score, the IPA
/// the model heard, the IPA reference it was scored against, and a
/// timestamp. This lets the stats page draw a pronunciation timeline
/// and surface specific phoneme drift over weeks of practice.
class PhoneticAttempt {
  final DateTime timestamp;
  final double score;        // 0.0–1.0
  final String? heardIpa;    // what the model heard
  final String? referenceIpa;// what we scored against
  final String? source;      // 'audio_mimicry' | 'page_types_mimicry' | …

  PhoneticAttempt({
    required this.timestamp,
    required this.score,
    this.heardIpa,
    this.referenceIpa,
    this.source,
  });

  Map<String, dynamic> toJson() => {
    't': timestamp.millisecondsSinceEpoch,
    's': score,
    if (heardIpa != null) 'h': heardIpa,
    if (referenceIpa != null) 'r': referenceIpa,
    if (source != null) 'src': source,
  };

  factory PhoneticAttempt.fromJson(Map<String, dynamic> j) => PhoneticAttempt(
    timestamp: DateTime.fromMillisecondsSinceEpoch(j['t'] as int),
    score: (j['s'] as num).toDouble(),
    heardIpa: j['h'] as String?,
    referenceIpa: j['r'] as String?,
    source: j['src'] as String?,
  );
}

class VocabRecord {
  final String wordId;
  final String displayText;
  final String source;         // 'audio_mimicry' | 'lesson' etc. — first source we saw

  int totalAttempts;
  double cumulativeScore;

  List<double> vocalScores;    // last 20 mimicry scores (0.0–1.0 continuous)
  List<double> nonVocalScores; // last 20 MC/match/fill scores (0.0 or 1.0)

  /// Full phonetic history for vocal attempts. Capped at
  /// [kPhoneticHistoryMax] entries (oldest dropped first) to keep
  /// SharedPreferences blob small. Newest entry is last.
  List<PhoneticAttempt> phoneticHistory;

  static const int kRecentWindow = 20;
  static const int kPhoneticHistoryMax = 200;

  VocabRecord({
    required this.wordId,
    required this.displayText,
    this.source = 'unknown',
    this.totalAttempts = 0,
    this.cumulativeScore = 0.0,
    List<double>? vocalScores,
    List<double>? nonVocalScores,
    List<PhoneticAttempt>? phoneticHistory,
  })  : vocalScores = vocalScores ?? [],
        nonVocalScores = nonVocalScores ?? [],
        phoneticHistory = phoneticHistory ?? [];

  /// Record a vocal attempt with optional IPA detail. The IPA fields are
  /// optional so legacy call sites that only have a score still work,
  /// but new code should pass both `heardIpa` and `referenceIpa` so the
  /// stats page can show concrete phonetic drift.
  void addVocalScore(
      double score, {
        String? heardIpa,
        String? referenceIpa,
        String? attemptSource,
        DateTime? timestamp,
      }) {
    final s = score.clamp(0.0, 1.0);
    totalAttempts++;
    cumulativeScore += s;
    vocalScores.add(s);
    _trim(vocalScores);

    phoneticHistory.add(PhoneticAttempt(
      timestamp: timestamp ?? DateTime.now(),
      score: s,
      heardIpa: heardIpa,
      referenceIpa: referenceIpa,
      source: attemptSource,
    ));
    if (phoneticHistory.length > kPhoneticHistoryMax) {
      phoneticHistory.removeRange(
          0, phoneticHistory.length - kPhoneticHistoryMax);
    }
  }

  /// Record a non-vocal attempt (binary: pass = 1.0, fail = 0.0).
  void addNonVocalScore(bool correct) {
    final s = correct ? 1.0 : 0.0;
    totalAttempts++;
    cumulativeScore += s;
    nonVocalScores.add(s);
    _trim(nonVocalScores);
  }

  void _trim(List<double> buf) {
    if (buf.length > kRecentWindow) {
      buf.removeRange(0, buf.length - kRecentWindow);
    }
  }

  double? _avgOrNull(List<double> buf) {
    if (buf.isEmpty) return null;
    return buf.reduce((a, b) => a + b) / buf.length;
  }

  /// Rolling vocal average, or null if no vocal attempts.
  double? get vocalAverage => _avgOrNull(vocalScores);

  /// Rolling non-vocal average, or null if no non-vocal attempts.
  double? get nonVocalAverage => _avgOrNull(nonVocalScores);

  /// 50/50 blend when both sides have data; whichever exists if only one;
  /// 0.0 if neither (shouldn't happen for tracked records).
  double get rollingAverage {
    final v = vocalAverage;
    final n = nonVocalAverage;
    if (v != null && n != null) return (v + n) / 2;
    if (v != null) return v;
    if (n != null) return n;
    return 0.0;
  }

  double get lifetimeAverage =>
      totalAttempts == 0 ? 0.0 : cumulativeScore / totalAttempts;

  // ── Pronunciation trend helpers ──────────────────────────────────────
  //
  // These power "are you getting better at this word?" UI on the stats
  // page. They look at the phoneticHistory rather than the rolling buffer
  // because we want the answer to span the full history when available.

  /// Average score of the most recent [n] vocal attempts.
  double? recentVocalAverage([int n = 5]) {
    if (phoneticHistory.isEmpty) return null;
    final start = (phoneticHistory.length - n).clamp(0, phoneticHistory.length);
    final slice = phoneticHistory.sublist(start);
    return slice.map((a) => a.score).reduce((a, b) => a + b) / slice.length;
  }

  /// Difference between the most recent [recent] attempts' average and the
  /// preceding [baseline] attempts' average. Positive = improving.
  /// Returns null if there isn't enough history to compare.
  double? pronunciationTrend({int recent = 5, int baseline = 10}) {
    if (phoneticHistory.length < recent + 1) return null;
    final recentSlice = phoneticHistory.sublist(phoneticHistory.length - recent);
    final beforeStart =
    (phoneticHistory.length - recent - baseline).clamp(0, phoneticHistory.length);
    final beforeEnd = phoneticHistory.length - recent;
    final beforeSlice = phoneticHistory.sublist(beforeStart, beforeEnd);
    if (beforeSlice.isEmpty) return null;
    final r = recentSlice.map((a) => a.score).reduce((a, b) => a + b) /
        recentSlice.length;
    final b = beforeSlice.map((a) => a.score).reduce((a, b) => a + b) /
        beforeSlice.length;
    return r - b;
  }

  Map<String, dynamic> toJson() => {
    'wordId': wordId,
    'displayText': displayText,
    'source': source,
    'totalAttempts': totalAttempts,
    'cumulativeScore': cumulativeScore,
    'vocalScores': vocalScores,
    'nonVocalScores': nonVocalScores,
    'phoneticHistory': phoneticHistory.map((a) => a.toJson()).toList(),
  };

  /// Backwards-compatible: old records stored a single `recentScores` list
  /// from the mimicry-only era — migrate those into `vocalScores`.
  /// Older records also won't have `phoneticHistory` — start it empty.
  factory VocabRecord.fromJson(Map<String, dynamic> json) {
    final legacy = (json['recentScores'] as List<dynamic>?)
        ?.map((e) => (e as num).toDouble())
        .toList();
    final vocal = (json['vocalScores'] as List<dynamic>?)
        ?.map((e) => (e as num).toDouble())
        .toList() ??
        legacy ??
        <double>[];
    final nonVocal = (json['nonVocalScores'] as List<dynamic>?)
        ?.map((e) => (e as num).toDouble())
        .toList() ??
        <double>[];

    final history = (json['phoneticHistory'] as List<dynamic>?)
        ?.map((e) => PhoneticAttempt.fromJson(e as Map<String, dynamic>))
        .toList() ??
        <PhoneticAttempt>[];

    return VocabRecord(
      wordId: json['wordId'] as String,
      displayText: json['displayText'] as String,
      source: json['source'] as String? ?? 'unknown',
      totalAttempts: json['totalAttempts'] as int? ?? 0,
      cumulativeScore: (json['cumulativeScore'] as num?)?.toDouble() ?? 0.0,
      vocalScores: vocal,
      nonVocalScores: nonVocal,
      phoneticHistory: history,
    );
  }
}