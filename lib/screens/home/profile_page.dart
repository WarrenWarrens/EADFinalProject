
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_scatter/flutter_scatter.dart';
import '../../models/user_profile.dart';
import '../../models/vocab_record.dart';
import '../../services/local_storage_service.dart';
import '../../services/vocab_tracking_service.dart';
import '../../theme/app_theme.dart';
import 'stats_page.dart';
import 'settings_page.dart';

const List<Map<String, String>> _kGoals = [
  {'id': 'native', 'label': 'Native', 'color': 'red'},
  {'id': 'intermediate', 'label': 'Intermediate', 'color': 'orange'},
  {'id': 'beginner', 'label': 'Basic', 'color': 'green'},
];

const List<Map<String, dynamic>> _kLanguages = [
  {'id': 'navi', 'label': "Na'vi", 'emoji': '🌿', 'enabled': true},
  {'id': 'klingon', 'label': 'Klingon', 'emoji': '🖖', 'enabled': false},
  {'id': 'sindarin', 'label': 'Sindarin', 'emoji': '🌙', 'enabled': false},
];

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _storage = LocalStorageService();
  final _tracker = VocabTrackingService();
  UserProfile? _profile;
  List<VocabRecord> _vocabRecords = [];
  bool _loading = true;

  final _nameController = TextEditingController();
  bool _editingName = false;

  final List<String> _avatarOptions = [
    'assets/avatars/avatar_1.png',
    'assets/avatars/avatar_2.png',
    'assets/avatars/avatar_3.png',
    'assets/avatars/avatar_4.png',
    'assets/avatars/avatar_5.png',
    'assets/avatars/avatar_6.png',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final profile = await _storage.loadProfile();
    final records = await _tracker.getAllRecords();
    if (mounted) {
      setState(() {
        _profile = profile;
        _vocabRecords = records;
        _nameController.text = profile?.username ?? '';
        _loading = false;
      });
    }
  }

  Future<void> _save(UserProfile updated) async {
    await _storage.saveProfile(updated);
    if (mounted) setState(() => _profile = updated);
  }


  void _saveName() {
    final trimmed = _nameController.text.trim();
    if (trimmed.isNotEmpty && _profile != null) {
      _save(_profile!.copyWith(username: trimmed));
    }
    setState(() => _editingName = false);
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select language',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ..._kLanguages.map((lang) {
                final enabled = lang['enabled'] as bool;
                final id = lang['id'] as String;
                final isSelected =
                    _profile?.selectedLanguages.contains(id) ?? false;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: enabled
                        ? () {
                      final langs =
                      List<String>.from(_profile!.selectedLanguages);
                      if (isSelected) {
                        langs.remove(id);
                      } else {
                        langs.add(id);
                      }
                      _save(_profile!.copyWith(selectedLanguages: langs));
                      Navigator.pop(context);
                    }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: !enabled
                            ? AppTheme.of(context).surfaceAlt
                            : isSelected
                            ? AppColors.primary
                            : AppTheme.of(context).surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.of(context).border),
                      ),
                      child: Row(
                        children: [
                          Text(lang['emoji'] as String,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 12),
                          Text(
                            lang['label'] as String,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: !enabled
                                  ? AppColors.textSecondary
                                  : isSelected
                                  ? Colors.white
                                  : AppTheme.of(context).textPrimary,
                            ),
                          ),
                          if (!enabled) ...[
                            const Spacer(),
                            const Text('Coming soon',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontStyle: FontStyle.italic)),
                          ],
                          if (isSelected && enabled) ...[
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
            ],
          ),
        );
      },
    );
  }

  void _showGoalPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Learning goal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ..._kGoals.map((goal) {
                final id = goal['id']!;
                final isSelected = _profile?.learningGoal == id;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () {
                      _save(_profile!.copyWith(learningGoal: id));
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppTheme.of(context).surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.of(context).border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _goalColor(goal['color']!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            goal['label']!,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.of(context).textPrimary,
                            ),
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
            ],
          ),
        );
      },
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: GridView.builder(
          shrinkWrap: true,
          itemCount: _avatarOptions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemBuilder: (_, i) {
            final isSelected = _profile?.avatarPath == _avatarOptions[i];
            return GestureDetector(
              onTap: () {
                _save(_profile!.copyWith(avatarPath: _avatarOptions[i]));
                Navigator.pop(context);
              },
              child: CircleAvatar(
                radius: 36,
                backgroundColor:
                isSelected ? AppColors.primary : AppColors.primaryLight,
                child: Icon(
                  Icons.person,
                  size: 32,
                  color: isSelected ? Colors.white : AppColors.primary,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _goalColor(String key) {
    switch (key) {
      case 'red':    return AppColors.error;
      case 'orange': return AppColors.warning;
      case 'green':  return AppColors.success;
      default:       return AppColors.primary;
    }
  }

  String _goalLabel(String? id) {
    final match = _kGoals.where((g) => g['id'] == id);
    return match.isNotEmpty ? match.first['label']! : 'Not set';
  }

  String _languageLabel() {
    if (_profile == null || _profile!.selectedLanguages.isEmpty) {
      return 'None selected';
    }
    return _profile!.selectedLanguages.map((id) {
      final match = _kLanguages.where((l) => l['id'] == id);
      return match.isNotEmpty ? match.first['label'] as String : id;
    }).join(', ');
  }


  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          children: [
            GestureDetector(
              onTap: _showAvatarPicker,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: AppColors.primaryLight,
                    child: const Icon(Icons.person,
                        size: 52, color: AppColors.primary),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border:
                        Border.all(color: AppColors.surface, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _SettingsCard(
              icon: Icons.person_outline_rounded,
              label: 'Username',
              child: _editingName
                  ? Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      autofocus: true,
                      style: const TextStyle(
                          fontSize: 15),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      onSubmitted: (_) => _saveName(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _saveName,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              )
                  : GestureDetector(
                onTap: () => setState(() => _editingName = true),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _profile?.username ?? 'Tap to set',
                        style: TextStyle(
                          fontSize: 15,
                          color: _profile?.username != null
                              ? AppTheme.of(context).textPrimary
                              : AppTheme.of(context).textSecondary,
                        ),
                      ),
                    ),
                    Icon(Icons.edit_rounded,
                        size: 18, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            _SettingsCard(
              icon: Icons.translate_rounded,
              label: 'Language',
              child: GestureDetector(
                onTap: _showLanguagePicker,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _languageLabel(),
                        style: const TextStyle(
                            fontSize: 15),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 20, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            _SettingsCard(
              icon: Icons.flag_rounded,
              label: 'Learning Goal',
              child: GestureDetector(
                onTap: _showGoalPicker,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _goalLabel(_profile?.learningGoal),
                        style: const TextStyle(
                            fontSize: 15),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 20, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatsPage()),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.of(context).surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.of(context).border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cloud_rounded,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Your Word Cloud',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right_rounded,
                            size: 20, color: AppColors.textSecondary),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _vocabRecords.isEmpty
                        ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          Icon(Icons.cloud_outlined,
                              size: 40,
                              color: AppColors.textSecondary
                                  .withOpacity(0.3)),
                          const SizedBox(height: 8),
                          Text(
                            'Complete some lessons\nto see your words here!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    )
                        : _MiniWordCloud(records: _vocabRecords),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),
            Text(
              'Tap to view full stats',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  const _SettingsCard({
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: palette.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Mini word cloud (profile preview)
// ═══════════════════════════════════════════════════════════════════════════════

class _MiniWordCloud extends StatelessWidget {
  final List<VocabRecord> records;
  const _MiniWordCloud({required this.records});

  /// Smaller log scale for the mini preview — min 11, max 28.
  double _fontSize(int attempts, int maxAttempts) {
    if (maxAttempts <= 1) return 16.0;
    final logAttempts = log(attempts.clamp(1, maxAttempts).toDouble());
    final logMax = log(maxAttempts.toDouble());
    final t = (logAttempts / logMax).clamp(0.0, 1.0);
    return 11.0 + t * 17.0;
  }

  @override
  Widget build(BuildContext context) {
    final display = records.take(15).toList();
    if (display.isEmpty) return const SizedBox.shrink();

    final maxAttempts =
    display.map((r) => r.totalAttempts).reduce((a, b) => a > b ? a : b);

    final children = display.map((r) {
      final size = _fontSize(r.totalAttempts, maxAttempts);
      // Reuse the color logic from the full word cloud on stats page
      final color = WordCloud.scoreColor(r.rollingAverage);
      return Text(
        r.displayText,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      );
    }).toList();

    return SizedBox(
      height: 140,
      width: double.infinity,
      child: Center(
        child: Scatter(
          fillGaps: true,
          delegate: ArchimedeanSpiralScatterDelegate(ratio: 0.5),
          children: children,
        ),
      ),
    );
  }
}