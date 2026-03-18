/// Represents a single vocabulary item or phrase in a lesson.
class VocabItem {
  final String id;
  final String navi;       // Na'vi text
  final String ipa;        // IPA transcription  e.g. /kal.tʼɪ/
  final String english;    // English translation
  final String ttsHint;    // Phoneme hint string passed to TTS engine
  final int tier;          // 1 = beginner, 2 = intermediate, 3 = native

  const VocabItem({
    required this.id,
    required this.navi,
    required this.ipa,
    required this.english,
    required this.ttsHint,
    required this.tier,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'navi': navi,
    'ipa': ipa,
    'english': english,
    'ttsHint': ttsHint,
    'tier': tier,
  };

  factory VocabItem.fromJson(Map<String, dynamic> json) => VocabItem(
    id: json['id'],
    navi: json['navi'],
    ipa: json['ipa'],
    english: json['english'],
    ttsHint: json['ttsHint'],
    tier: json['tier'],
  );
}

/// A full lesson containing ordered vocab and metadata.
class Lesson {
  final String id;
  final String language;   // 'navi' | 'klingon' | 'sindarin'
  final String title;
  final String description;
  final List<VocabItem> vocab; // full list — always 15 items for a standard lesson

  const Lesson({
    required this.id,
    required this.language,
    required this.title,
    required this.description,
    required this.vocab,
  });

  /// Returns the subset of vocab appropriate for the user's learning goal.
  ///   'beginner'     → first 5
  ///   'intermediate' → first 10
  ///   'native'       → all 15
  List<VocabItem> itemsForGoal(String? goal) {
    final count = switch (goal) {
      'native'       => 15,
      'intermediate' => 10,
      _              => 5,   // beginner or null
    };
    return vocab.take(count).toList();
  }
}