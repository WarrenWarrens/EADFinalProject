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
          Text(data['text']),
          const Spacer(),

          // Start Button
          ElevatedButton(
            onPressed: onNext,
            child: const Text("Continue"),
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
          // Highlight the character
          Text(
            data['letter'],
            style: TextStyle(
                fontWeight: FontWeight(20),
              fontSize: 20
            ),
          ),

          Text(data['description']),

          const Spacer(),

          // Start Button
          ElevatedButton(
            onPressed: onNext,
            child: const Text("Continue"),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// This page will reroute to the correct widget depending on the exerciseType
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
  int? selectedIndex; // Which option has been selected
  bool hasSubmitted = false; // If the user has submitted the answer

  bool get hasSelected{
    // Returns true if the user has selected an option
    return selectedIndex != null;
  }

  bool get isCorrect{
    return hasSubmitted && widget.options[selectedIndex!]['correct'] == true;
  }

  // Method to return option ui color
  Color _optionColor(int index) {

    // On selection, before submission
    if (!hasSubmitted) {
      return index == selectedIndex ? AppColors.primaryLight : Colors.transparent;
    }

    // Correct or incorrect highlight based on what user selected, after submission
    if (index == selectedIndex) {
      return isCorrect ? Colors.green.shade100 : Colors.red.shade100;
    }

    // Highlights the actual correct answer
    if (widget.options[index]['correct'] == true) {
      return Colors.green.shade100;
    }

    return Colors.transparent;
  }

  // Method to return option ui border colour
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
    // Ensure user has selected an option
    if (!hasSelected) {
      return;
    }

    // First button click action
    if (!hasSubmitted) {
      setState(() {
        hasSubmitted = true;
      });
    }
    // Second button click action
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

          const SizedBox(height: 20),

          // Top icon
          Center(
            child: Container(
              width: 120,
              height: 120,
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

          // Question
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

          // List of options
          ...List.generate(widget.options.length, (index) {
            final option = widget.options[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                  onTap: hasSubmitted ? null
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

          // Feedback on submission
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

          const Spacer(),

          // Continue or check button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: hasSelected ? _onCheck : null,
              child: Text(hasSubmitted ? 'Continue': 'Check'),
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
