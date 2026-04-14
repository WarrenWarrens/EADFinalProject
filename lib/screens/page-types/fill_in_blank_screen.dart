import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class FillInBlank extends StatefulWidget {
  final String question;
  final List<dynamic> parts;
  final VoidCallback onNext;

  const FillInBlank({
    super.key,
    required this.question,
    required this.parts,
    required this.onNext,
  });

  @override
  State<FillInBlank> createState() => _FillInBlankState();
}

class _FillInBlankState extends State<FillInBlank> {
  final Map<int, TextEditingController> controllers = {};

  bool hasSubmitted = false;
  bool isCorrect = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers for blanks
    for (int i = 0; i < widget.parts.length; i++) {
      if (widget.parts[i]['type'] == 'blank') {
        final controller = TextEditingController();

        // rebuild UI when typing
        controller.addListener(() {
          setState(() {});
        });

        controllers[i] = controller;
      }
    }
  }

  @override
  void dispose() {
    for (var c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // Button enabled when ALL blanks filled
  bool get hasInput {
    return controllers.values.every((c) => c.text.trim().isNotEmpty);
  }

  // Check answers
  void _onCheck() {
    if (!hasSubmitted) {
      bool allCorrect = true;

      for (int i = 0; i < widget.parts.length; i++) {
        final part = widget.parts[i];

        if (part['type'] == 'blank') {
          final user =
          controllers[i]!.text.trim().toLowerCase();
          final correct =
          part['answer'].toString().toLowerCase();

          if (user != correct) {
            allCorrect = false;
            break;
          }
        }
      }

      setState(() {
        isCorrect = allCorrect;
        hasSubmitted = true;
      });
    } else {
      widget.onNext();
    }
  }

  // Auto-size blank width
  double _getWidth(String answer) {
    return (answer.length * 12).clamp(60, 160).toDouble();
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

                  // Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Question
                  Text(
                    widget.question,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),

                  const SizedBox(height: 24),

                  // Sentence with blanks
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 8,
                    children: List.generate(widget.parts.length, (index) {
                      final part = widget.parts[index];
                      if (part['type'] == 'text') {
                        return Text(
                          part['value'],
                          style: const TextStyle(fontSize: 20),
                        );
                      }

                      if (part['type'] == 'blank') {
                        return SizedBox(
                          width: _getWidth(part['answer']),
                          child: TextField(
                            onChanged: (_) => setState(() {}),
                            controller: controllers[index],
                            enabled: !hasSubmitted,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: "answer",
                              filled: true,
                              fillColor: hasSubmitted
                                  ? (isCorrect
                                  ? Colors.green.shade100
                                  : Colors.red.shade100)
                                  : Colors.white,
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        );

                        // TODO: ADD CORRECT ANSWER AND FIX TEXT FIELD SIZE
                      }

                      return const SizedBox();
                    }),
                  ),

                  const SizedBox(height: 24),

                  // Feedback
                  if (hasSubmitted)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isCorrect
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: isCorrect
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isCorrect ? "Correct!" : "Incorrect",
                          style: TextStyle(
                            color: isCorrect
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: hasInput ? _onCheck : null,
              child: Text(hasSubmitted ? "Continue" : "Check"),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}