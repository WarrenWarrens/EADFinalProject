// =====================
// LESSON
// =====================
class Lesson {
  final int id;
  final int languageId;
  final String title;
  final String objective;
  final List<Content> content;

  const Lesson({
    required this.id,
    required this.languageId,
    required this.title,
    required this.objective,
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'languageId': languageId,
      'title': title,
      'objective': objective,
      'content' : content,
    };
  }

  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      id: map['id'],
      languageId: map['languageId'],
      title: map['title'],
      objective: map['objective'],
      content: (map['content'] as List)
          .map((c) => Content.fromMap(c))
          .toList(),
    );
  }
}

// ===================
// CONTENT
// ===================
class Content {
  final int id;
  final String type;
  final Map<String, dynamic> data; // Depending on the content type, the data will have different attributes

  const Content({
    required this.id,
    required this.type,
    required this.data,
  });

  // Only a fromMap method since you cannot write to content data
  factory Content.fromMap(Map<String, dynamic> map) {
    return Content(
      id: map['id'],
      type: map['type'],
      data: map['data'] ?? {},
    );
  }
}

// ====================
// EXERCISE
// ====================
class Exercise {
  final String exerciseType;
  final String question;
  final List<ExerciseOption> options;

  const Exercise({
    required this.exerciseType,
    required this.question,
    required this.options,
  });

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      exerciseType: map['exerciseType'],
      question: map['question'],
      options: (map['options'] as List)
          .map((o) => ExerciseOption.fromMap(o))
          .toList(),
    );
  }
}

class ExerciseOption {
  final String text;
  final bool correct;

  const ExerciseOption({
    required this.text,
    required this.correct,
  });

  factory ExerciseOption.fromMap(Map<String, dynamic> map) {
    return ExerciseOption(
      text: map['text'],
      correct: map['correct'],
    );
  }
}
