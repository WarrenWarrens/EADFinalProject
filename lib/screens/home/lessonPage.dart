import 'package:flutter/material.dart';
import '../../screens/content/page_types.dart';
import '../../models/lessons.dart';
import '../../theme/app_theme.dart';

class LessonPage extends StatefulWidget {
  final Lesson lesson;

  const LessonPage({super.key, required this.lesson});

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {

  int currentContentIndex = 0;
  late final List<Content> content = widget.lesson.content;
  late final int lessonLength = widget.lesson.content.length;



  void nextSlide() {
    if (currentContentIndex < lessonLength+1) {
      setState(() {
        currentContentIndex++;
      });
    }
  }

  Widget buildContentPage() {
    final contentObject = content.firstWhere((c) => c.id == currentContentIndex);


    Map<String, dynamic> dataAttrs = contentObject.data;


    switch (contentObject.type) {
      case 'text':
        return TextPage(key: ValueKey(contentObject.id), data: dataAttrs, onNext: nextSlide);
      case 'character':
        return CharacterPage(key: ValueKey(contentObject.id), data: dataAttrs, onNext: nextSlide);
      case 'word':
        return WordPage(key: ValueKey(contentObject.id), data: dataAttrs, onNext: nextSlide);
      case 'phrase':
        return PhrasePage(key: ValueKey(contentObject.id), data: dataAttrs, onNext: nextSlide);
      case 'exercise':
        return ExercisePage(key: ValueKey(contentObject.id), data: dataAttrs, onNext: nextSlide);
      default:
        return const Placeholder();
    }
  }

  double get progress{
    return currentContentIndex / (lessonLength+1);
  }

  @override
  Widget build(BuildContext context) {

    Widget body;

    if (currentContentIndex == 0) {
      body = LessonIntroPage(
        lesson: widget.lesson,
        onStart: nextSlide,
      );
    }

    else if (currentContentIndex == lessonLength+1){
      body = LessonCompletePage(
          lessonTitle: widget.lesson.title,
          onContinue: (){
            Navigator.pop(
              context,
            );
          }
      );
    }

    else{

      body = buildContentPage();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Lesson ${widget.lesson.id} - ${widget.lesson.title}'),
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
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            )
        ),
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

          Text(
            lesson.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            lesson.objective,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),

          const Spacer(),

          ElevatedButton(
            onPressed: onStart,
            child: const Text("Start Lesson"),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class LessonCompletePage extends StatelessWidget {
  final String lessonTitle;
  final VoidCallback onContinue;

  const LessonCompletePage({
    super.key,
    required this.lessonTitle,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

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
                  "Lesson Complete!",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                Text(
                  lessonTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                const Text(
                  "Great job! You're one step closer to mastering the language.",
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onContinue,
              child: const Text("Back to Home"),
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}