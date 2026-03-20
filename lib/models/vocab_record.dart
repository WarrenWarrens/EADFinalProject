/// Tracks a single word/sound the user has encountered across lessons.
///
/// [recentScores] holds the last 20 scores (0.0–1.0) in chronological order.
/// The rolling average of this list drives the colour in the word cloud.
/// [totalAttempts] drives the size (frequency).
class VocabRecord {
  final String wordId;        // unique key — e.g. 'nv_01' or 'char_ä'
  final String displayText;   // what appears in the cloud — e.g. 'Kaltxì' or 'ä'
  final String source;        // 'audio_mimicry' | 'lesson'
  int totalAttempts;
  double cumulativeScore;     // sum of all scores ever
  List<double> recentScores;  // last 20 — newest at end

  static const int kRecentWindow = 20;

  VocabRecord({
    required this.wordId,
    required this.displayText,
    this.source = 'unknown',
    this.totalAttempts = 0,
    this.cumulativeScore = 0.0,
    List<double>? recentScores,
  }) : recentScores = recentScores ?? [];

  /// Record a new attempt score (0.0–1.0).
  void addScore(double score) {
    final s = score.clamp(0.0, 1.0);
    totalAttempts++;
    cumulativeScore += s;
    recentScores.add(s);
    if (recentScores.length > kRecentWindow) {
      recentScores = recentScores.sublist(recentScores.length - kRecentWindow);
    }
  }

  /// Rolling average of the last 20 attempts (drives colour).
  double get rollingAverage {
    if (recentScores.isEmpty) return 0.0;
    return recentScores.reduce((a, b) => a + b) / recentScores.length;
  }

  /// Lifetime average score.
  double get lifetimeAverage {
    if (totalAttempts == 0) return 0.0;
    return cumulativeScore / totalAttempts;
  }

  Map<String, dynamic> toJson() => {
    'wordId': wordId,
    'displayText': displayText,
    'source': source,
    'totalAttempts': totalAttempts,
    'cumulativeScore': cumulativeScore,
    'recentScores': recentScores,
  };

  factory VocabRecord.fromJson(Map<String, dynamic> json) => VocabRecord(
    wordId: json['wordId'] as String,
    displayText: json['displayText'] as String,
    source: json['source'] as String? ?? 'unknown',
    totalAttempts: json['totalAttempts'] as int? ?? 0,
    cumulativeScore: (json['cumulativeScore'] as num?)?.toDouble() ?? 0.0,
    recentScores: (json['recentScores'] as List<dynamic>?)
        ?.map((e) => (e as num).toDouble())
        .toList() ??
        [],
  );
}
