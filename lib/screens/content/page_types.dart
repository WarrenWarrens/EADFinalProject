import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/lessons.dart'; // adjust import to your model path

class TextPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onNext;

  const TextPage({
    super.key,
    required this.data,
    required this.onNext,
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
                Text(
                  data['text'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 20
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text("Continue"),
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class CharacterPage extends StatelessWidget{
  final Map<String, dynamic> data;
  final VoidCallback onNext;

  const CharacterPage({
    super.key,
    required this.data,
    required this.onNext,
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

                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Audio feature will be implemented later!"),
                          showCloseIcon: true,
                        )
                    );
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            data['letter'],
                            style: const TextStyle(
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        Positioned(
                          top: 10,
                          right: 10,
                          child: Icon(
                            Icons.volume_up_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  data['description'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 20
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text("Continue"),
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

}

class ExercisePage extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onNext;

  const ExercisePage({
    super.key,
    required this.data,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    switch (data['exerciseType']) {
      case 'multiple_choice':
        return MultipleChoice(
          question: data['question'],
          options: List<Map<String, dynamic>>.from(data['options']),
          onNext: onNext,
        );
      default:
        return const Center(child: Text('Unknown exercise type'));
    }
  }
}

class MultipleChoice extends StatefulWidget {
  final String question;
  final List<Map<String, dynamic>> options;
  final VoidCallback onNext;

  const MultipleChoice({
    super.key,
    required this.question,
    required this.options,
    required this.onNext,
  });

  @override
  State<MultipleChoice> createState() => _MultipleChoiceState();
}

class _MultipleChoiceState extends State<MultipleChoice> {
  int? selectedIndex;
  bool hasSubmitted = false;

  bool get hasSelected{
    return selectedIndex != null;
  }

  bool get isCorrect{
    return hasSubmitted && widget.options[selectedIndex!]['correct'] == true;
  }

  Color _optionColor(int index) {

    if (!hasSubmitted) {
      return index == selectedIndex ? AppColors.primaryLight : Colors.transparent;
    }

    if (index == selectedIndex) {
      return isCorrect ? Colors.green.shade100 : Colors.red.shade100;
    }

    if (widget.options[index]['correct'] == true) {
      return Colors.green.shade100;
    }

    return Colors.transparent;
  }

  Color _optionBorderColor(int index) {
    if (!hasSubmitted) {
      return index == selectedIndex ? AppColors.primary : AppColors.primaryLight;
    }

    if (index == selectedIndex) {
      return isCorrect ? Colors.green : Colors.red;
    }

    if (widget.options[index]['correct'] == true) {
      return Colors.green;
    }

    return AppColors.primaryLight;
  }

  void _onCheck() {
    if (!hasSelected) {
      return;
    }

    if (!hasSubmitted) {
      setState(() {
        hasSubmitted = true;
      });
    }
    else {
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.quiz_rounded,
                        size: 60,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    widget.question,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.5,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ...List.generate(widget.options.length, (index) {
                    final option = widget.options[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: hasSubmitted
                            ? null
                            : () => setState(() => selectedIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          decoration: BoxDecoration(
                            color: _optionColor(index),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _optionBorderColor(index),
                              width: 2,
                            ),
                          ),
                          child: Text(
                            option['text'],
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 18,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  if (hasSubmitted) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isCorrect ? Icons.check_circle : Icons.cancel,
                          color: isCorrect ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isCorrect ? 'Correct!' : 'Incorrect, try next time!',
                          style: TextStyle(
                            color: isCorrect ? Colors.green : Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: hasSelected ? _onCheck : null,
              child: Text(hasSubmitted ? 'Continue' : 'Check'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
