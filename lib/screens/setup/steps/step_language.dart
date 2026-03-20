import 'package:flutter/material.dart';
import '../../../models/user_profile.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common_widgets.dart';

/// Available fictional languages — extend this list as you add content.
const List<Map<String, String>> kLanguages = [
  {'id': 'navi', 'label': '"Na\'vi" (Avatar)', 'emoji': '🌿'},
  {'id': 'klingon', 'label': '"Klingon" (Star Trek) 🚧', 'emoji': '🖖'},
  {'id': 'sindarin', 'label': '"Sindarin" (LOTR) 🚧', 'emoji': '🌙'},
];

class StepLanguage extends StatefulWidget {
  final UserProfile profile;
  final Future<void> Function(UserProfile) onNext;
  final VoidCallback onBack;

  const StepLanguage({
    super.key,
    required this.profile,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<StepLanguage> createState() => _StepLanguageState();
}

class _StepLanguageState extends State<StepLanguage> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.profile.selectedLanguages);
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _next() {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select at least one language')));
      return;
    }
    widget.onNext(
        widget.profile.copyWith(selectedLanguages: _selected.toList()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              const Text(
                'Please select a\nlanguage to start!',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                '(More can be selected later!)',
                style:
                    TextStyle(fontSize: 13, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              ...kLanguages.map((lang) => _LanguageChip(
                    label: lang['label']!,
                    emoji: lang['emoji']!,
                    selected: _selected.contains(lang['id']),
                    onTap: () => _toggle(lang['id']!),
                  )),

              const Spacer(),

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
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageChip({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.buttonSoft,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color:
                      selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (selected)
                const Icon(Icons.check_circle,
                    color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
