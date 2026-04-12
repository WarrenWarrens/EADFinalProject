import '../widgets/app_language.dart';

/// A single downloaded audio recording for a dictionary result.
class DictionaryAudio {
  final String localPath; // absolute path in app documents dir (persistent)
  final String speaker;

  const DictionaryAudio({required this.localPath, required this.speaker});

  Map<String, dynamic> toJson() => {
        'localPath': localPath,
        'speaker': speaker,
      };

  factory DictionaryAudio.fromJson(Map<String, dynamic> j) => DictionaryAudio(
        localPath: j['localPath'] as String,
        speaker: j['speaker'] as String? ?? 'unknown',
      );
}

/// One word/phrase returned by a dictionary lookup.
class DictionaryResult {
  /// The Na'vi (or Klingon) word.
  final String word;

  /// Part-of-speech tag from Reykunyu, e.g. 'n', 'vtr', 'inter'.
  final String wordType;

  /// Primary English translation.
  final String translation;

  /// Syllabified form from Reykunyu's pronunciation object, e.g. "kal-txì".
  /// null when the API does not supply one.
  final String? syllables;

  /// IPA transcription — Forest Na'vi dialect (FN) from Reykunyu.
  /// e.g. "[ɾ(u~ʊ)n]"
  final String? ipa;

  /// All audio recordings available for this word, one per speaker.
  final List<DictionaryAudio> audio;

  const DictionaryResult({
    required this.word,
    this.wordType = '',
    required this.translation,
    this.syllables,
    this.ipa,
    this.audio = const [],
  });

  Map<String, dynamic> toJson() => {
        'word': word,
        'wordType': wordType,
        'translation': translation,
        if (syllables != null) 'syllables': syllables,
        if (ipa != null) 'ipa': ipa,
        'audio': audio.map((a) => a.toJson()).toList(),
      };

  factory DictionaryResult.fromJson(Map<String, dynamic> j) => DictionaryResult(
        word: j['word'] as String,
        wordType: j['wordType'] as String? ?? '',
        translation: j['translation'] as String,
        syllables: j['syllables'] as String?,
        ipa: j['ipa'] as String?,
        audio: (j['audio'] as List<dynamic>?)
                ?.map((a) => DictionaryAudio.fromJson(a as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

/// A completed dictionary search — stored in the history ring-buffer.
class DictionaryEntry {
  final String query;
  final AppLanguage language;
  final DateTime searchedAt;
  final List<DictionaryResult> results;

  const DictionaryEntry({
    required this.query,
    required this.language,
    required this.searchedAt,
    required this.results,
  });

  Map<String, dynamic> toJson() => {
        'query': query,
        'language': language.name,
        'searchedAt': searchedAt.toIso8601String(),
        'results': results.map((r) => r.toJson()).toList(),
      };

  factory DictionaryEntry.fromJson(Map<String, dynamic> j) => DictionaryEntry(
        query: j['query'] as String,
        language: AppLanguage.values.firstWhere(
          (l) => l.name == (j['language'] as String),
          orElse: () => AppLanguage.navi,
        ),
        searchedAt: DateTime.parse(j['searchedAt'] as String),
        results: (j['results'] as List<dynamic>?)
                ?.map((r) => DictionaryResult.fromJson(r as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
