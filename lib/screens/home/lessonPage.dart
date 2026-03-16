import 'package:flutter/material.dart';
import '../../models/lessons.dart';
import '../../theme/app_theme.dart';

class LessonPage extends StatefulWidget {
  final Lesson lesson;

  const LessonPage({super.key, required this.lesson});

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {

  int currentContentIndex = -1; // -1 means intro page

  void nextSlide() {
    if (currentContentIndex < widget.lesson.content.length - 1) {
      setState(() {
        currentContentIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    Widget body;

    // Intro page
    if (currentContentIndex == -1) {
      body = LessonIntroPage(
        lesson: widget.lesson,
        onStart: nextSlide,
      );
    }
    else{
      body = Text("hi");
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Lesson ${widget.lesson.id} - ${widget.lesson.title}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: body,
    );
  }
}

class LessonIntroPage extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onStart;

  const LessonIntroPage({
    super.key,
    required this.lesson,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          const SizedBox(height: 20),

          // Lesson Icon
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 60,
                color: AppColors.primary,
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Lesson Title
          Text(
            lesson.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // Objective
          Text(
            lesson.objective,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const Spacer(),

          // Start Button
          ElevatedButton(
            onPressed: null,
            child: const Text("Start Lesson"),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}