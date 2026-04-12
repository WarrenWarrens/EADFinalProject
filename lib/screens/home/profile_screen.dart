import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_scatter/flutter_scatter.dart';

import '../../models/user_profile.dart';
import '../../models/vocab_record.dart';
import '../../services/local_storage_service.dart';
import '../../services/music_service.dart';
import '../../services/volume_service.dart';
import '../../theme/app_theme.dart';
import 'study_page.dart';
import '../../services/vocab_tracking_service.dart';
import '../../widgets/app_nav_bar.dart';
import '../../widgets/app_language.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  ProfileScreen — unified Profile / Stats / Settings screen.
//
//  The top tile selector mirrors the difficulty selector on HomeScreen.
//  The bottom AppNavBar highlights Profile (index 0).
//
//  Pass [initialLanguage] and [onLanguageChange] so language state can
//  propagate back to HomeScreen when the user switches language here.
// ═══════════════════════════════════════════════════════════════════════════════

class ProfileScreen extends StatefulWidget {
  final AppLanguage initialLanguage;
  final ValueChanged<AppLanguage>? onLanguageChange;

  const ProfileScreen({
    super.key,
    this.initialLanguage = AppLanguage.navi,
    this.onLanguageChange,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTab = 0;
  late AppLanguage _language;

  UserProfile? _profile;
  List<VocabRecord> _vocabRecords = [];
  bool _loading = true;

  static const _tabLabels = ['Profile', 'Stats', 'Settings'];
  static const _tabIcons = [
    Icons.person_rounded,
    Icons.bar_chart_rounded,
    Icons.settings_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _language = widget.initialLanguage;
    _load();
  }

  Future<void> _load() async {
    final storage = LocalStorageService();
    final tracker = VocabTrackingService();
    final profile = await storage.loadProfile();
    final records = await tracker.getAllRecords();
    if (mounted) {
      setState(() {
        _profile = profile;
        _vocabRecords = records;
        _loading = false;
      });
    }
  }

  Future<void> _saveProfile(UserProfile updated) async {
    final storage = LocalStorageService();
    await storage.saveProfile(updated);
    if (mounted) setState(() => _profile = updated);
  }


  void _onNavTap(int index) {
    if (index == 0) return; // already on Profile
    if (index == 1) {
      // Study — replace this route so back-stack stays clean.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StudyPage(selectedLanguage: _language),
        ),
      );
      return;
    }
    // index == 2: Courses (the underlying home screen)
    Navigator.pop(context);
  }

  void _onLanguageSelect(AppLanguage lang) {
    setState(() => _language = lang);
    widget.onLanguageChange?.call(lang);
  }


  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? Center(
          child: CircularProgressIndicator(
            color: _language.accentColor,
          ),
        )
            : Column(
          children: [
            _TabSelector(
              selected: _selectedTab,
              labels: _tabLabels,
              icons: _tabIcons,
              accentColor: _language.accentColor,
              onSelect: (i) => setState(() => _selectedTab = i),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppNavBar(
        selectedIndex: 0,
        selectedLanguage: _language,
        onTap: _onNavTap,
        onLanguageSelect: _onLanguageSelect,
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0:
        return _ProfileTab(
          key: const ValueKey('profile'),
          profile: _profile,
          accentColor: _language.accentColor,
          onSave: _saveProfile,
        );
      case 1:
        return _StatsTab(
          key: ValueKey('stats_${_language.name}'),
          language: _language,
          vocabRecords: _vocabRecords,
          accentColor: _language.accentColor,
        );
      case 2:
      default:
        return _SettingsTab(
          key: const ValueKey('settings'),
          profile: _profile,
          accentColor: _language.accentColor,
          onSave: _saveProfile,
        );
    }
  }
}


class _TabSelector extends StatelessWidget {
  final int selected;
  final List<String> labels;
  final List<IconData> icons;
  final Color accentColor;
  final ValueChanged<int> onSelect;

  const _TabSelector({
    required this.selected,
    required this.labels,
    required this.icons,
    required this.accentColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.of(context);
    return Container(
      color: palette.background,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: List.generate(3, (i) {
          final on = selected == i;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 72,
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: on ? accentColor : palette.border,
                          width: on ? 2.5 : 1.5,
                        ),
                        boxShadow: on
                            ? [
                          BoxShadow(
                            color: accentColor.withOpacity(0.25),
                            blurRadius: 12,
                          ),
                        ]
                            : null,
                      ),
                      child: Center(
                        child: Icon(
                          icons[i],
                          color: on ? accentColor : palette.textMuted,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                        on ? FontWeight.w600 : FontWeight.w400,
                        color:
                        on ? palette.textPrimary : palette.textMuted,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 3,
                      width: on ? 32 : 0,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}


class _ProfileTab extends StatelessWidget {
  final UserProfile? profile;
  final Color accentColor;
  final Future<void> Function(UserProfile) onSave;

  const _ProfileTab({
    super.key,
    required this.profile,
    required this.accentColor,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.dark.surfaceAlt,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                        color: accentColor.withOpacity(0.35), width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: profile?.avatarPath != null
                        ? Image.asset(profile!.avatarPath!, fit: BoxFit.cover)
                        : Center(
                      child: Icon(
                        Icons.person_rounded,
                        size: 60,
                        color: const Color(0xFF555555),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppTheme.dark.background, width: 2.5),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          _ProfileInfoTile(
            icon: Icons.person_outline_rounded,
            label: 'Username',
            value: profile?.username ?? 'Not set',
            accentColor: accentColor,
            onTap: profile == null ? null : () => _editUsername(context),
          ),
          const SizedBox(height: 12),

          _ProfileInfoTile(
            icon: Icons.email_outlined,
            label: 'Email',
            value: profile?.email ?? 'Not set',
            accentColor: accentColor,
            onTap: profile == null ? null : () => _editEmail(context),
          ),
          const SizedBox(height: 12),

          _ProfileInfoTile(
            icon: Icons.flag_outlined,
            label: 'Learning Goal',
            value: _goalLabel(profile?.learningGoal),
            accentColor: accentColor,
            onTap: profile == null ? null : () => _editLearningGoal(context),
          ),
        ],
      ),
    );
  }

  String _goalLabel(String? id) {
    switch (id) {
      case 'native':
        return 'Native';
      case 'intermediate':
        return 'Intermediate Speaker';
      case 'beginner':
        return 'Basic';
      default:
        return 'Not set';
    }
  }

  Future<void> _editUsername(BuildContext context) async {
    final result = await _showTextEditDialog(
      context,
      title: 'Edit Username',
      initial: profile?.username ?? '',
      hint: 'Username',
    );
    if (result != null && result != profile?.username) {
      await onSave(profile!.copyWith(username: result));
    }
  }

  Future<void> _editEmail(BuildContext context) async {
    final result = await _showTextEditDialog(
      context,
      title: 'Edit Email',
      initial: profile?.email ?? '',
      hint: 'name@example.com',
      keyboardType: TextInputType.emailAddress,
      validator: (v) {
        if (v.isEmpty) return 'Email cannot be empty';
        // Pragmatic RFC-5322-ish: local@domain.tld, no spaces, TLD ≥ 2 chars.
        final re = RegExp(
            r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$");
        if (!re.hasMatch(v)) return 'Enter a valid email address';
        return null;
      },
    );
    if (result != null && result != profile?.email) {
      await onSave(profile!.copyWith(email: result));
    }
  }

  Future<String?> _showTextEditDialog(
      BuildContext context, {
        required String title,
        required String initial,
        required String hint,
        TextInputType keyboardType = TextInputType.text,
        String? Function(String value)? validator,
      }) {
    final controller = TextEditingController(text: initial);
    String? errorText;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          backgroundColor: AppTheme.dark.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text(title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white),
            onChanged: (_) {
              if (errorText != null) {
                setLocalState(() => errorText = null);
              }
            },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF666666)),
              errorText: errorText,
              filled: true,
              fillColor: AppTheme.dark.surfaceAlt,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: const Color(0xFF333333)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accentColor, width: 1.5),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFF999999))),
            ),
            TextButton(
              onPressed: () {
                final trimmed = controller.text.trim();
                final err = validator?.call(trimmed);
                if (err != null) {
                  setLocalState(() => errorText = err);
                  return;
                }
                Navigator.pop(ctx, trimmed);
              },
              child: Text('Save', style: TextStyle(color: accentColor)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editLearningGoal(BuildContext context) async {
    const goals = [
      ('beginner', 'Basic'),
      ('intermediate', 'Intermediate Speaker'),
      ('native', 'Native'),
    ];
    final current = profile?.learningGoal;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.dark.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Learning Goal',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (id, label) in goals)
              RadioListTile<String>(
                value: id,
                groupValue: current,
                activeColor: accentColor,
                title: Text(label,
                    style: const TextStyle(color: Colors.white)),
                onChanged: (v) => Navigator.pop(ctx, v),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF999999))),
          ),
        ],
      ),
    );
    if (result != null && result != current) {
      await onSave(profile!.copyWith(learningGoal: result));
    }
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final VoidCallback? onTap;

  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF999999),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF111111),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: const Color(0xFFBBBBBB),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


class _StatsTab extends StatelessWidget {
  final AppLanguage language;
  final List<VocabRecord> vocabRecords;
  final Color accentColor;

  const _StatsTab({
    super.key,
    required this.language,
    required this.vocabRecords,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _ExpandableStatCard(
          icon: Icons.cloud_rounded,
          title: 'Your Word Cloud',
          accentColor: accentColor,
          initiallyExpanded: true,
          child: _WordCloudContent(
            language: language,
            records: vocabRecords,
            accentColor: accentColor,
          ),
        ),
        const SizedBox(height: 10),

        _ExpandableStatCard(
          icon: Icons.menu_book_rounded,
          title: 'Your Dictionary',
          accentColor: accentColor,
          initiallyExpanded: false,
          child: _DictionaryContent(
            language: language,
            accentColor: accentColor,
          ),
        ),
        const SizedBox(height: 10),

        _ExpandableStatCard(
          icon: Icons.check_circle_outline_rounded,
          title: 'Completed Lessons',
          accentColor: accentColor,
          initiallyExpanded: false,
          child: _LessonsContent(
            language: language,
            accentColor: accentColor,
          ),
        ),
      ],
    );
  }
}


class _ExpandableStatCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final Color accentColor;
  final bool initiallyExpanded;
  final Widget child;

  const _ExpandableStatCard({
    required this.icon,
    required this.title,
    required this.accentColor,
    required this.initiallyExpanded,
    required this.child,
  });

  @override
  State<_ExpandableStatCard> createState() => _ExpandableStatCardState();
}

class _ExpandableStatCardState extends State<_ExpandableStatCard>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _ctrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: _expanded ? 1.0 : 0.0,
    );
    _expandAnim = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: widget.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.accentColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _expanded
                          ? widget.accentColor
                          : const Color(0xFF888888),
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            SizeTransition(
              sizeFactor: _expandAnim,
              axisAlignment: -1,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.dark.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: widget.child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _WordCloudContent extends StatelessWidget {
  final AppLanguage language;
  final List<VocabRecord> records;
  final Color accentColor;

  const _WordCloudContent({
    required this.language,
    required this.records,
    required this.accentColor,
  });

  static Color _scoreColor(double avg) {
    if (avg >= 0.75) {
      final t = ((avg - 0.75) / 0.25).clamp(0.0, 1.0);
      return Color.lerp(
          const Color(0xFF8BC34A), const Color(0xFF2E7D32), t)!;
    } else if (avg >= 0.45) {
      final t = ((avg - 0.45) / 0.30).clamp(0.0, 1.0);
      return Color.lerp(
          AppColors.warning, const Color(0xFF8BC34A), t)!;
    } else {
      final t = (avg / 0.45).clamp(0.0, 1.0);
      return Color.lerp(
          const Color(0xFFB71C1C), AppColors.warning, t)!;
    }
  }

  static double _fontSize(int attempts, int maxAttempts) {
    if (maxAttempts <= 1) return 20.0;
    final logAttempts =
    log(attempts.clamp(1, maxAttempts).toDouble());
    final logMax = log(maxAttempts.toDouble());
    final t = (logAttempts / logMax).clamp(0.0, 1.0);
    return 13.0 + t * 22.0;
  }

  @override
  Widget build(BuildContext context) {
    if (language != AppLanguage.navi || records.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.cloud_outlined,
                size: 36,
                color: accentColor.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(
              language == AppLanguage.navi
                  ? 'Complete lessons to fill\nyour word cloud!'
                  : 'No ${language.label} words tracked yet.\nComplete a lesson to get started!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF888888),
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    final maxAttempts = records
        .map((r) => r.totalAttempts)
        .reduce((a, b) => a > b ? a : b);

    final children = records.map((r) {
      return Tooltip(
        message:
        '${r.displayText} · ${r.totalAttempts}× · ${(r.rollingAverage * 100).round()}%',
        child: Text(
          r.displayText,
          style: TextStyle(
            fontSize: _fontSize(r.totalAttempts, maxAttempts),
            fontWeight: FontWeight.w700,
            color: _scoreColor(r.rollingAverage),
          ),
        ),
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 180,
        width: double.infinity,
        child: Center(
          child: Scatter(
            fillGaps: true,
            delegate: ArchimedeanSpiralScatterDelegate(ratio: 0.5),
            children: children,
          ),
        ),
      ),
    );
  }
}


class _DictionaryContent extends StatelessWidget {
  final AppLanguage language;
  final Color accentColor;

  const _DictionaryContent({
    required this.language,
    required this.accentColor,
  });

  List<Map<String, String>> get _words {
    switch (language) {
      case AppLanguage.klingon:
        return [
          {'word': 'nuqneH', 'meaning': 'What do you want?'},
          {'word': "Qapla'", 'meaning': 'Success / Farewell'},
          {'word': 'tlhIngan', 'meaning': 'Klingon (person)'},
          {'word': 'batlh', 'meaning': 'Honor'},
          {'word': 'Heghlu\'meH QaQ jajvam', 'meaning': 'Today is a good day to die'},
        ];
      case AppLanguage.highValyrian:
        return [
          {'word': 'Rytsas', 'meaning': 'Hello'},
          {'word': 'Kirimvose', 'meaning': 'Thank you'},
          {'word': 'Zaldrīzes', 'meaning': 'Dragon'},
          {'word': 'Valar Morghulis', 'meaning': 'All men must die'},
          {'word': 'Valar Dohaeris', 'meaning': 'All men must serve'},
        ];
      case AppLanguage.navi:
      default:
        return [
          {"word": "Kaltxì", "meaning": "Hello"},
          {"word": "Irayo", "meaning": "Thank you"},
          {"word": "Srane", "meaning": "Yes"},
          {"word": "Kehe", "meaning": "No"},
          {"word": "Oel ngati kameie", "meaning": "I see you"},
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = _words;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: words.asMap().entries.map((e) {
          final i = e.key;
          final w = e.value;
          return Padding(
            padding: EdgeInsets.only(bottom: i < words.length - 1 ? 8 : 0),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Text(
                    w['word']!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    w['meaning']!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFAAAAAA),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}


class _LessonsContent extends StatelessWidget {
  final AppLanguage language;
  final Color accentColor;

  const _LessonsContent({
    required this.language,
    required this.accentColor,
  });

  List<Map<String, dynamic>> get _lessons {
    switch (language) {
      case AppLanguage.klingon:
        return [
          {'title': 'Introduction', 'score': 88, 'done': true},
          {'title': 'Warrior Greetings', 'score': 74, 'done': true},
          {'title': 'Battle Vocabulary', 'score': 0, 'done': false},
        ];
      case AppLanguage.highValyrian:
        return [
          {'title': 'Introduction', 'score': 91, 'done': true},
          {'title': 'Noble Greetings', 'score': 83, 'done': true},
          {'title': 'Dragon Vocabulary', 'score': 0, 'done': false},
        ];
      case AppLanguage.navi:
      default:
        return [
          {'title': 'Introduction', 'score': 85, 'done': true},
          {'title': 'Vowels', 'score': 72, 'done': true},
          {'title': 'Vocabulary', 'score': 0, 'done': false},
          {'title': 'Introductions', 'score': 0, 'done': false},
        ];
    }
  }

  Color _scoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return const Color(0xFF666666);
  }

  @override
  Widget build(BuildContext context) {
    final lessons = _lessons;
    final completed = lessons.where((l) => l['done'] == true).length;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$completed / ${lessons.length}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'lessons completed',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF888888),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...lessons.map((l) {
            final done = l['done'] as bool;
            final score = l['score'] as int;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    done
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: done ? accentColor : const Color(0xFF444444),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l['title'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: done ? Colors.white : const Color(0xFF555555),
                      ),
                    ),
                  ),
                  if (done)
                    Text(
                      '$score%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _scoreColor(score),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}


class _SettingsTab extends StatefulWidget {
  final UserProfile? profile;
  final Color accentColor;
  final Future<void> Function(UserProfile) onSave;

  const _SettingsTab({
    super.key,
    required this.profile,
    required this.accentColor,
    required this.onSave,
  });

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  late bool _shareData;
  late bool _notifications;
  late bool _microphone;
  late bool _camera;
  late double _musicVolume;
  late double _voiceVolume;

  @override
  void initState() {
    super.initState();
    _shareData = widget.profile?.shareData ?? false;
    _notifications = widget.profile?.notifications ?? true;
    _microphone = widget.profile?.allowMicrophone ?? false;
    _camera = widget.profile?.allowCamera ?? false;
    _musicVolume = VolumeService().musicVolume;
    _voiceVolume = VolumeService().voiceVolume;
  }

  void _setMusicVolume(double v) {
    setState(() => _musicVolume = v);
    MusicService().setMusicVolume(v);
  }

  void _setVoiceVolume(double v) {
    setState(() => _voiceVolume = v);
    VolumeService().setVoiceVolume(v);
  }

  // 0 = dark, 1 = light — matches AppTheme.themes indices.
  String _themeLabel(int idx) => idx == 0 ? 'Dark' : 'Light';

  Future<void> _showThemePicker(BuildContext context, Color accent) async {
    final current = appThemeIndex.value;
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.dark.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Theme',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < AppTheme.themes.length; i++)
              RadioListTile<int>(
                value: i,
                groupValue: current,
                activeColor: accent,
                title: Text(_themeLabel(i),
                    style: const TextStyle(color: Colors.white)),
                onChanged: (v) => Navigator.pop(ctx, v),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF999999))),
          ),
        ],
      ),
    );
    if (result != null) {
      appThemeIndex.value = result;
      if (mounted) setState(() {}); // refresh subtitle text
    }
  }

  void _toggle(String field, bool value) {
    if (widget.profile == null) return;
    setState(() {
      switch (field) {
        case 'share':
          _shareData = value;
          break;
        case 'notif':
          _notifications = value;
          break;
        case 'mic':
          _microphone = value;
          break;
        case 'cam':
          _camera = value;
          break;
      }
    });
    widget.onSave(widget.profile!.copyWith(
      shareData: _shareData,
      notifications: _notifications,
      allowMicrophone: _microphone,
      allowCamera: _camera,
    ));
  }

  void _showResetConfirm() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.dark.surface,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset all data?',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: Colors.white)),
        content: const Text(
          'This will clear your profile, progress, and all lesson data. '
              'This cannot be undone.',
          style: TextStyle(color: Color(0xFF888888)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () async {
              final storage = LocalStorageService();
              await storage.clearAll();
              if (!mounted) return;
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: const Text('Reset',
                style: TextStyle(color: Color(0xFFE53935))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _SettingsSectionHeader(label: 'Audio'),
        _SliderTile(
          icon: Icons.volume_up_rounded,
          label: 'Music Volume',
          subtitle: 'Background music level',
          value: _musicVolume,
          accentColor: accent,
          onChanged: _setMusicVolume,
        ),
        const SizedBox(height: 8),
        _SliderTile(
          icon: Icons.record_voice_over_rounded,
          label: 'Voice Volume',
          subtitle: 'Spoken word and TTS level',
          value: _voiceVolume,
          accentColor: accent,
          onChanged: _setVoiceVolume,
        ),

        const SizedBox(height: 16),

        _SettingsSectionHeader(label: 'Appearance'),
        _ActionTile(
          icon: Icons.palette_outlined,
          label: 'Theme',
          subtitle: _themeLabel(appThemeIndex.value),
          accentColor: accent,
          isDanger: false,
          onTap: () => _showThemePicker(context, accent),
        ),

        const SizedBox(height: 16),

        _SettingsSectionHeader(label: 'Permissions'),
        _ToggleTile(
          icon: Icons.mic_rounded,
          label: 'Microphone',
          subtitle: 'Allow microphone to record',
          value: _microphone,
          accentColor: accent,
          onChanged: (v) => _toggle('mic', v),
        ),
        const SizedBox(height: 8),
        _ToggleTile(
          icon: Icons.camera_alt_rounded,
          label: 'Camera',
          subtitle: 'Allow camera to capture pictures',
          value: _camera,
          accentColor: accent,
          onChanged: (v) => _toggle('cam', v),
        ),
        const SizedBox(height: 8),
        _ToggleTile(
          icon: Icons.notifications_rounded,
          label: 'Notifications',
          subtitle: 'Daily reminders and lesson updates',
          value: _notifications,
          accentColor: accent,
          onChanged: (v) => _toggle('notif', v),
        ),
        const SizedBox(height: 8),
        _ToggleTile(
          icon: Icons.share_rounded,
          label: 'Share Data',
          subtitle: 'Help us improve with anonymous usage data',
          value: _shareData,
          accentColor: accent,
          onChanged: (v) => _toggle('share', v),
        ),

        const SizedBox(height: 16),

        _SettingsSectionHeader(label: 'Account'),
        _ActionTile(
          icon: Icons.email_outlined,
          label: 'Email',
          subtitle: widget.profile?.email ?? 'Not set',
          accentColor: accent,
        ),
        const SizedBox(height: 8),
        _ActionTile(
          icon: Icons.badge_rounded,
          label: 'Account Type',
          subtitle: (widget.profile?.isGuest ?? true)
              ? 'Guest'
              : 'Registered',
          accentColor: accent,
        ),

        const SizedBox(height: 16),

        _SettingsSectionHeader(label: 'Data'),
        _ActionTile(
          icon: Icons.delete_outline_rounded,
          label: 'Reset All Data',
          subtitle: 'Clear progress and start fresh',
          accentColor: AppColors.error,
          isDanger: true,
          onTap: _showResetConfirm,
        ),
      ],
    );
  }
}


class _SettingsSectionHeader extends StatelessWidget {
  final String label;
  const _SettingsSectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF888888),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}


class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final Color accentColor;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111111))),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF999999))),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: accentColor,
          ),
        ],
      ),
    );
  }
}


class _SliderTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final double value;
  final Color accentColor;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111111))),
                    Text('${(value * 100).round()}%',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF666666))),
                  ],
                ),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF999999))),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14),
                    activeTrackColor: accentColor,
                    inactiveTrackColor: const Color(0xFFE0E0E0),
                    thumbColor: accentColor,
                    overlayColor: accentColor.withOpacity(0.15),
                  ),
                  child: Slider(
                    value: value.clamp(0.0, 1.0),
                    min: 0,
                    max: 1,
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color accentColor;
  final bool isDanger;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accentColor,
    this.isDanger = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: accentColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDanger
                          ? AppColors.error
                          : const Color(0xFF111111),
                    ),
                  ),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF999999))),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: const Color(0xFFBBBBBB)),
          ],
        ),
      ),
    );
  }
}