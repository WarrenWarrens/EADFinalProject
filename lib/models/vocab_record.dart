/// Tracks a single word the user has encountered across lessons.
///
/// Maintains two independent rolling buffers (last 20 each) so the stats
/// page can surface where the user struggles: pronunciation (vocal) vs.
/// recall/recognition (non-vocal). Overall score is a 50/50 blend when
/// both exist; otherwise falls back to whichever one has data.
class VocabRecord {
  final String wordId;
  final String displayText;
  final String source;         // 'audio_mimicry' | 'lesson' etc. — first source we saw

  int totalAttempts;
  double cumulativeScore;

  List<double> vocalScores;    // last 20 mimicry scores (0.0–1.0 continuous)
  List<double> nonVocalScores; // last 20 MC/match/fill scores (0.0 or 1.0)

  static const int kRecentWindow = 20;

  VocabRecord({
    required this.wordId,
    required this.displayText,
    this.source = 'unknown',
    this.totalAttempts = 0,
    this.cumulativeScore = 0.0,
    List<double>? vocalScores,
    List<double>? nonVocalScores,
  })  : vocalScores = vocalScores ?? [],
        nonVocalScores = nonVocalScores ?? [];

  /// Record a vocal attempt (continuous 0.0–1.0 from the phoneme scorer).
  void addVocalScore(double score) {
    final s = score.clamp(0.0, 1.0);
    totalAttempts++;
    cumulativeScore += s;
    vocalScores.add(s);
    _trim(vocalScores);
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

  Map<String, dynamic> toJson() => {
    'wordId': wordId,
    'displayText': displayText,
    'source': source,
    'totalAttempts': totalAttempts,
    'cumulativeScore': cumulativeScore,
    'vocalScores': vocalScores,
    'nonVocalScores': nonVocalScores,
  };

  /// Backwards-compatible: old records stored a single `recentScores` list
  /// from the mimicry-only era — migrate those into `vocalScores`.
  factory VocabRecord.fromJson(Map<String, dynamic> json) {
    final legacy = (json['recentScores'] as List<dynamic>?)
        ?.map((e) => (e as num).toDouble())
        .toList();
    final vocal = (json['vocalScores'] as List<dynamic>?)
        ?.map((e) => (e as num).toDouble())
        .toList() ??
        legacy ?? // migration path
        <double>[];
    final nonVocal = (json['nonVocalScores'] as List<dynamic>?)
        ?.map((e) => (e as num).toDouble())
        .toList() ??
        <double>[];

    return VocabRecord(
      wordId: json['wordId'] as String,
      displayText: json['displayText'] as String,
      source: json['source'] as String? ?? 'unknown',
      totalAttempts: json['totalAttempts'] as int? ?? 0,
      cumulativeScore: (json['cumulativeScore'] as num?)?.toDouble() ?? 0.0,
      vocalScores: vocal,
      nonVocalScores: nonVocal,
    );
  }
}