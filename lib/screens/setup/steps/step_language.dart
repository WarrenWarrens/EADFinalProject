import 'package:flutter/material.dart';
import '../../../models/user_profile.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common_widgets.dart';

/// Available fictional languages — extend this list as you add content.
const List<Map<String, dynamic>> kLanguages = [
  {'id': 'navi', 'label': '"Na\'vi" (Avatar)', 'emoji': '🌿', 'enabled': true},
  {'id': 'klingon', 'label': '"Klingon" (Star Trek) 🚧', 'emoji': '🖖', 'enabled': false},
  {'id': 'sindarin', 'label': '"Sindarin" (LOTR) 🚧', 'emoji': '🌙', 'enabled': false},
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

              ...kLanguages.map((lang) {
                final enabled = lang['enabled'] as bool;
                return _LanguageChip(
                  label: lang['label'] as String,
                  emoji: lang['emoji'] as String,
                  selected: _selected.contains(lang['id']),
                  enabled: enabled,
                  onTap: enabled ? () => _toggle(lang['id'] as String) : null,
                );
              }),

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
  final bool enabled;
  final VoidCallback? onTap;

  const _LanguageChip({
    required this.label,
    required this.emoji,
    required this.selected,
    this.enabled = true,
    this.onTap,
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
            color: !enabled
                ? Colors.grey.shade200
                : selected
                ? AppColors.primary
                : AppColors.buttonSoft,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Opacity(
                opacity: enabled ? 1.0 : 0.4,
                child: Text(emoji, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: !enabled
                            ? Colors.grey
                            : selected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (!enabled)
                      const Text(
                        'Coming soon',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              if (selected && enabled)
                const Icon(Icons.check_circle,
                    color: Colors.white, size: 18),
              if (!enabled)
                Icon(Icons.lock_outline,
                    color: Colors.grey.shade400, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}