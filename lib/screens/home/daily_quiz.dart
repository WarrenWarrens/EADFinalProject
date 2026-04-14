import 'package:flutter/material.dart';
import '../../screens/page-types/page_types.dart';
import '../../models/lessons.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class DailyQuizPage extends StatefulWidget {
  final int? streak;
  final int? questionCount;
  final Quiz quiz;

  const DailyQuizPage({
    super.key,
    required this.streak,
    required this.questionCount,
    required this.quiz,
  });

  @override
  State<DailyQuizPage> createState() => _DailyQuizPageState();
}

class _DailyQuizPageState extends State<DailyQuizPage> {
  int currentContentIndex = 0;

  late final List<Content> content = widget.quiz.questions;
  late final int lessonLength = widget.quiz.questions.length;

  // ── Progress ─────────────────────────────────────────────
  double get progress {
    return currentContentIndex / (lessonLength + 1);
  }

  // ── Navigation ───────────────────────────────────────────
  void nextSlide() {
    if (currentContentIndex < lessonLength + 1) {
      setState(() {
        currentContentIndex++;
      });
    }
  }

  // ── Build dynamic content (same as LessonPage) ───────────
  Widget buildContentPage() {
    final contentObject =
    content.firstWhere((c) => c.id == currentContentIndex);

    Map<String, dynamic> dataAttrs = contentObject.data;

    // final exerciseType = contentObject.type;

    return ExercisePage(
        data: dataAttrs,
        onNext: nextSlide
    );
  }

  // ── UI ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final String today =
    DateFormat('EEEE, MMM d').format(DateTime.now());

    Widget body;

    // ── INTRO PAGE ─────────────────────────────────────────
    if (currentContentIndex == 0) {
      body = _QuizIntroPage(
        streak: widget.streak,
        questionCount: widget.questionCount,
        today: today,
        onStart: nextSlide,
      );
    }

    // ── COMPLETE PAGE ──────────────────────────────────────
    else if (currentContentIndex == lessonLength + 1) {
      body = _QuizCompletePage(
        onFinish: ()  {
          Navigator.pop(context, true);
        },
      );
    }

    // ── QUIZ CONTENT ───────────────────────────────────────
    else {
      body = buildContentPage();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Quiz"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,

        // Progress bar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.primaryLight,
                valueColor:
                AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
        ),
      ),
      body: body,
    );
  }
}

//
// ───────────────────────────────────────────────────────────
// INTRO PAGE
// ───────────────────────────────────────────────────────────
//

class _QuizIntroPage extends StatelessWidget {
  final int? streak;
  final int? questionCount;
  final String today;
  final VoidCallback onStart;

  const _QuizIntroPage({
    required this.streak,
    required this.questionCount,
    required this.today,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),

          const Icon(
            Icons.quiz_rounded,
            size: 80,
            color: AppColors.primary,
          ),

          const SizedBox(height: 30),

          const Text(
            "Daily Quiz",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            today,
            style: const TextStyle(color: AppColors.textSecondary),
          ),

          const SizedBox(height: 40),

          Text(
            "🔥 ${streak ?? 0} day streak",
            style: const TextStyle(fontSize: 18),
          ),

          const SizedBox(height: 10),

          Text(
            "🧠 ${questionCount ?? 0} questions",
            style: const TextStyle(fontSize: 18),
          ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onStart,
              child: const Text("Start Quiz"),
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

//
// ───────────────────────────────────────────────────────────
// COMPLETE PAGE
// ───────────────────────────────────────────────────────────
//

class _QuizCompletePage extends StatelessWidget {
  final VoidCallback onFinish;

  const _QuizCompletePage({required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),

          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              size: 60,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 32),

          const Text(
            "Quiz Complete!",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            "Come back tomorrow to keep your streak going!",
            textAlign: TextAlign.center,
          ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onFinish,
              child: const Text("Back to Home"),
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}