import 'package:flutter/material.dart';
import '../../../models/user_profile.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common_widgets.dart';

const List<Map<String, String>> kGoals = [
  {
    'id': 'native',
    'label': 'Native',
    'sub': '(~15 questions/lesson)',
    'color': 'red',
  },
  {
    'id': 'intermediate',
    'label': 'Intermediate Speaker',
    'sub': '(~10 questions/lesson)',
    'color': 'orange',
  },
  {
    'id': 'beginner',
    'label': 'Basic',
    'sub': '(~5 questions/lesson)',
    'color': 'green',
  },
];

class StepGoals extends StatefulWidget {
  final UserProfile profile;
  final Future<void> Function(UserProfile) onNext;
  final VoidCallback onBack;

  const StepGoals({
    super.key,
    required this.profile,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<StepGoals> createState() => _StepGoalsState();
}

class _StepGoalsState extends State<StepGoals> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.profile.learningGoal;
  }

  void _next() {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a learning goal')));
      return;
    }
    widget.onNext(widget.profile.copyWith(learningGoal: _selected));
  }

  Color _goalColor(String colorKey) {
    switch (colorKey) {
      case 'red':
        return const Color(0xFFE53935);
      case 'orange':
        return const Color(0xFFFF9800);
      case 'green':
        return const Color(0xFF4CAF50);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: ResponsiveFormLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            const Text(
              'Please select your\nlearning goal!',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              '(Can be adjusted at any point!)',
              style:
              TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            ...kGoals.map((goal) {
              final isSelected = _selected == goal['id'];
              final dotColor = _goalColor(goal['color']!);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => setState(() => _selected = goal['id']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.buttonSoft,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                            radius: 10,
                            backgroundColor: dotColor),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal['label']!,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              goal['sub']!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? Colors.white70
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (isSelected) ...[
                          const Spacer(),
                          const Icon(Icons.check_circle,
                              color: Colors.white, size: 18),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),

            const Spacer(flex: 3),

            Row(
              children: [
                NavButton(icon: Icons.arrow_back, onTap: widget.onBack),
                const Spacer(),
                NavButton(icon: Icons.arrow_forward, onTap: _next),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}