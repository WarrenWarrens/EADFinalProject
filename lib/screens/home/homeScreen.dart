import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/local_storage_service.dart';
import '../../services/lessonService.dart';
import '../../services/music_service.dart';
import '../../theme/app_theme.dart';
import '../../data/navi_lesson_audio.dart';
import '../../persistent_bar.dart';
import '../lessons/audio_mimicry_screen.dart';
import '../lessons/simulation.dart';
import 'lessonPage.dart';
import 'stats_page.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  Lesson data structure
// ═══════════════════════════════════════════════════════════════════════════════

class _LessonEntry {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool unlocked;
  final void Function(BuildContext context)? onTap;

  const _LessonEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.unlocked = false,
    this.onTap,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Home screen
// ═══════════════════════════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  UserProfile? _profile;
  final _storage = LocalStorageService();
  final _music = MusicService();
  final _bar = PersistentBarController.instance;
  late TabController _tabController;

  static const _tabLabels = ['Word Match', 'Audio Mimicry', 'Conversation'];
  static const _tabIcons = [
    Icons.menu_book_rounded,
    Icons.headphones_rounded,
    Icons.chat_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _bar.show(); // make the persistent bar visible
    _loadExistingProfile();
    _music.crossfadeTo(MusicTrack.home);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingProfile() async {
    final saved = await _storage.loadProfile();
    if (mounted) setState(() => _profile = saved);
  }

  // ── Lesson navigation ──────────────────────────────────────────────────────

  Future<void> _enterLesson(Future<void> Function() navigate) async {
    _bar.enterLesson();
    _music.fadeToWhisper();
    await navigate();
    if (mounted) {
      _bar.exitLesson();
      _music.fadeBack();
    }
  }

  Future<void> _goToLesson1(BuildContext ctx) async {
    await _enterLesson(() async {
      final lesson = await loadLesson('lesson1.json');
      if (!mounted) return;
      await Navigator.push(
        ctx,
        MaterialPageRoute(builder: (_) => LessonPage(lesson: lesson)),
      );
    });
  }

  Future<void> _goToAudioMimicry(BuildContext ctx) async {
    await _enterLesson(() async {
      await Navigator.push(
        ctx,
        MaterialPageRoute(
          builder: (_) => AudioMimicryScreen(lesson: naviAudioLesson),
        ),
      );
    });
  }

  Future<void> _goToSimulation(BuildContext ctx) async {
    await _enterLesson(() async {
      await Navigator.push(
        ctx,
        MaterialPageRoute(builder: (_) => const SimScreen()),
      );
    });
  }

  // ── Word Match lessons ─────────────────────────────────────────────────────

  List<List<_LessonEntry>> _wordMatchLessons() => [
    [
      _LessonEntry(id: 'wm_b1', title: "Na'vi Vowels", subtitle: 'Learn the 7 vowel sounds', icon: Icons.menu_book_rounded, unlocked: true, onTap: _goToLesson1),
      _LessonEntry(id: 'wm_b2', title: 'Consonants', subtitle: 'Ejectives & digraphs', icon: Icons.abc_rounded),
      _LessonEntry(id: 'wm_b3', title: 'Basic Nouns', subtitle: 'People & nature', icon: Icons.forest_rounded),
      _LessonEntry(id: 'wm_b4', title: 'Pronouns', subtitle: 'I, you, we, they', icon: Icons.people_rounded),
      _LessonEntry(id: 'wm_b5', title: 'Numbers', subtitle: 'Octal counting', icon: Icons.pin_rounded),
      _LessonEntry(id: 'wm_b6', title: 'Colours', subtitle: 'Describing the world', icon: Icons.palette_rounded),
      _LessonEntry(id: 'wm_b7', title: 'Family Terms', subtitle: 'Clan & kinship', icon: Icons.family_restroom_rounded),
      _LessonEntry(id: 'wm_b8', title: 'Basic Verbs', subtitle: 'Common actions', icon: Icons.directions_run_rounded),
    ],
    [
      _LessonEntry(id: 'wm_i1', title: 'Case System', subtitle: 'Subject & object', icon: Icons.swap_horiz_rounded),
      _LessonEntry(id: 'wm_i2', title: 'Adjectives', subtitle: 'Describing things', icon: Icons.star_rounded),
      _LessonEntry(id: 'wm_i3', title: 'Adpositions', subtitle: 'Location & direction', icon: Icons.explore_rounded),
      _LessonEntry(id: 'wm_i4', title: 'Questions', subtitle: 'How to ask', icon: Icons.help_outline_rounded),
      _LessonEntry(id: 'wm_i5', title: 'Negation', subtitle: 'Saying no', icon: Icons.block_rounded),
      _LessonEntry(id: 'wm_i6', title: 'Tense & Aspect', subtitle: 'Past, present, future', icon: Icons.schedule_rounded),
      _LessonEntry(id: 'wm_i7', title: 'Compounds', subtitle: 'Building words', icon: Icons.construction_rounded),
      _LessonEntry(id: 'wm_i8', title: 'Word Roots', subtitle: 'Etymology patterns', icon: Icons.account_tree_rounded),
    ],
    [
      _LessonEntry(id: 'wm_a1', title: 'Infixes', subtitle: 'Verb mood markers', icon: Icons.code_rounded),
      _LessonEntry(id: 'wm_a2', title: 'Relative Clauses', subtitle: 'Complex sentences', icon: Icons.account_tree_rounded),
      _LessonEntry(id: 'wm_a3', title: 'Idioms', subtitle: 'Cultural expressions', icon: Icons.auto_awesome_rounded),
      _LessonEntry(id: 'wm_a4', title: 'Formal Register', subtitle: 'Ceremonial speech', icon: Icons.local_fire_department_rounded),
      _LessonEntry(id: 'wm_a5', title: 'Loan Words', subtitle: 'Borrowed vocabulary', icon: Icons.translate_rounded),
      _LessonEntry(id: 'wm_a6', title: 'Poetry Vocab', subtitle: 'Literary terms', icon: Icons.auto_stories_rounded),
      _LessonEntry(id: 'wm_a7', title: 'Scientific Terms', subtitle: 'Flora & fauna', icon: Icons.biotech_rounded),
      _LessonEntry(id: 'wm_a8', title: 'Mastery Quiz', subtitle: 'Prove your vocabulary', icon: Icons.emoji_events_rounded),
    ],
  ];

  // ── Audio Mimicry lessons ──────────────────────────────────────────────────

  List<List<_LessonEntry>> _audioMimicryLessons() => [
    [
      _LessonEntry(id: 'am_b1', title: 'Greetings & Basics', subtitle: 'Core words every speaker needs', icon: Icons.record_voice_over_rounded, unlocked: true, onTap: _goToAudioMimicry),
      _LessonEntry(id: 'am_b2', title: 'Vowel Drills', subtitle: 'Nail the 7 vowels', icon: Icons.graphic_eq_rounded),
      _LessonEntry(id: 'am_b3', title: 'Ejective Sounds', subtitle: 'tx, px, kx practice', icon: Icons.surround_sound_rounded),
      _LessonEntry(id: 'am_b4', title: 'Simple Phrases', subtitle: 'Two-word combos', icon: Icons.short_text_rounded),
      _LessonEntry(id: 'am_b5', title: 'Numbers Aloud', subtitle: "Count in Na'vi", icon: Icons.pin_rounded),
      _LessonEntry(id: 'am_b6', title: 'Nature Words', subtitle: 'Forest & sky', icon: Icons.forest_rounded),
      _LessonEntry(id: 'am_b7', title: 'Feelings', subtitle: 'Express emotions', icon: Icons.mood_rounded),
      _LessonEntry(id: 'am_b8', title: 'Farewells', subtitle: 'Parting phrases', icon: Icons.waving_hand_rounded),
    ],
    [
      _LessonEntry(id: 'am_i1', title: 'Longer Phrases', subtitle: 'Three+ word sequences', icon: Icons.notes_rounded),
      _LessonEntry(id: 'am_i2', title: 'Verb Pronunciation', subtitle: 'Infixed forms', icon: Icons.directions_run_rounded),
      _LessonEntry(id: 'am_i3', title: 'Stress Patterns', subtitle: 'Syllable emphasis', icon: Icons.music_note_rounded),
      _LessonEntry(id: 'am_i4', title: 'Question Intonation', subtitle: 'Rising pitch', icon: Icons.help_outline_rounded),
      _LessonEntry(id: 'am_i5', title: 'Fast Speech', subtitle: 'Natural tempo', icon: Icons.speed_rounded),
      _LessonEntry(id: 'am_i6', title: 'Cluster Drills', subtitle: 'Hard consonant combos', icon: Icons.fitness_center_rounded),
      _LessonEntry(id: 'am_i7', title: 'Echoed Sentences', subtitle: 'Listen & repeat', icon: Icons.hearing_rounded),
      _LessonEntry(id: 'am_i8', title: 'Proverbs', subtitle: 'Wisdom phrases', icon: Icons.format_quote_rounded),
    ],
    [
      _LessonEntry(id: 'am_a1', title: 'Storytelling', subtitle: 'Narrate with feeling', icon: Icons.auto_stories_rounded),
      _LessonEntry(id: 'am_a2', title: 'Song Lyrics', subtitle: 'Weaving Song excerpts', icon: Icons.music_note_rounded),
      _LessonEntry(id: 'am_a3', title: 'Ceremonial Speech', subtitle: 'Ritual intonation', icon: Icons.local_fire_department_rounded),
      _LessonEntry(id: 'am_a4', title: 'Rapid Dialogue', subtitle: 'Full-speed exchange', icon: Icons.forum_rounded),
      _LessonEntry(id: 'am_a5', title: 'Whispered Register', subtitle: 'Quiet forest speech', icon: Icons.volume_down_rounded),
      _LessonEntry(id: 'am_a6', title: 'Emotional Range', subtitle: 'Anger, joy, sorrow', icon: Icons.theater_comedy_rounded),
      _LessonEntry(id: 'am_a7', title: 'Poetry Recital', subtitle: 'Rhythm & metre', icon: Icons.auto_awesome_rounded),
      _LessonEntry(id: 'am_a8', title: 'Fluency Test', subtitle: 'Prove your accent', icon: Icons.emoji_events_rounded),
    ],
  ];

  // ── Conversation lessons ───────────────────────────────────────────────────

  List<List<_LessonEntry>> _conversationLessons() => [
    [
      _LessonEntry(id: 'cv_b1', title: 'First Meeting', subtitle: 'Introduce yourself', icon: Icons.handshake_rounded, unlocked: true, onTap: _goToSimulation),
      _LessonEntry(id: 'cv_b2', title: 'At the Village', subtitle: 'Ask for directions', icon: Icons.holiday_village_rounded),
      _LessonEntry(id: 'cv_b3', title: 'Sharing a Meal', subtitle: 'Food & drink talk', icon: Icons.restaurant_rounded),
      _LessonEntry(id: 'cv_b4', title: 'Making Friends', subtitle: 'Small talk', icon: Icons.people_rounded),
      _LessonEntry(id: 'cv_b5', title: 'The Forest', subtitle: 'Nature walk dialogue', icon: Icons.forest_rounded),
      _LessonEntry(id: 'cv_b6', title: 'Daily Routines', subtitle: 'Morning & evening', icon: Icons.wb_twilight_rounded),
      _LessonEntry(id: 'cv_b7', title: 'Shopping', subtitle: 'Trade & barter', icon: Icons.storefront_rounded),
      _LessonEntry(id: 'cv_b8', title: 'Saying Goodbye', subtitle: 'Parting conversation', icon: Icons.waving_hand_rounded),
    ],
    [
      _LessonEntry(id: 'cv_i1', title: 'Telling Stories', subtitle: 'Share an experience', icon: Icons.auto_stories_rounded),
      _LessonEntry(id: 'cv_i2', title: 'Asking Favours', subtitle: 'Polite requests', icon: Icons.volunteer_activism_rounded),
      _LessonEntry(id: 'cv_i3', title: 'Disagreements', subtitle: 'Respectful debate', icon: Icons.gavel_rounded),
      _LessonEntry(id: 'cv_i4', title: 'Hunting Party', subtitle: 'Coordinate a plan', icon: Icons.track_changes_rounded),
      _LessonEntry(id: 'cv_i5', title: 'Teaching a Child', subtitle: 'Simple explanations', icon: Icons.child_care_rounded),
      _LessonEntry(id: 'cv_i6', title: 'Healing & Care', subtitle: 'Comfort & medicine', icon: Icons.healing_rounded),
      _LessonEntry(id: 'cv_i7', title: 'Celebrations', subtitle: 'Festival dialogue', icon: Icons.celebration_rounded),
      _LessonEntry(id: 'cv_i8', title: 'Travel Plans', subtitle: 'Journey discussion', icon: Icons.flight_takeoff_rounded),
    ],
    [
      _LessonEntry(id: 'cv_a1', title: 'Council Meeting', subtitle: 'Formal debate', icon: Icons.groups_rounded),
      _LessonEntry(id: 'cv_a2', title: 'Dream Sharing', subtitle: 'Deep personal talk', icon: Icons.nightlight_rounded),
      _LessonEntry(id: 'cv_a3', title: 'Conflict Resolution', subtitle: 'Mediate a dispute', icon: Icons.balance_rounded),
      _LessonEntry(id: 'cv_a4', title: 'Ritual Ceremony', subtitle: 'Sacred exchange', icon: Icons.local_fire_department_rounded),
      _LessonEntry(id: 'cv_a5', title: 'Teaching Elders', subtitle: 'Knowledge transfer', icon: Icons.school_rounded),
      _LessonEntry(id: 'cv_a6', title: 'Negotiation', subtitle: 'High-stakes talk', icon: Icons.handshake_rounded),
      _LessonEntry(id: 'cv_a7', title: 'Love & Bonding', subtitle: 'Tsaheylu dialogue', icon: Icons.favorite_rounded),
      _LessonEntry(id: 'cv_a8', title: 'Mastery Dialogue', subtitle: 'Free-form fluency', icon: Icons.emoji_events_rounded),
    ],
  ];

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final name = _profile?.username;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      name != null ? 'Welcome,\n$name!' : 'Welcome!',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StatsPage()),
                    ),
                    icon: const Icon(Icons.bar_chart_rounded),
                    color: AppColors.primary,
                    tooltip: 'Your Progress',
                    iconSize: 28,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Tabs — lesson types ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.parchmentDark,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
                  labelPadding: EdgeInsets.zero,
                  tabs: [
                    for (var i = 0; i < 3; i++)
                      Tab(
                        height: 40,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_tabIcons[i], size: 16),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                _tabLabels[i],
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Tab content ──────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _LessonPanel(sections: _wordMatchLessons(), initiallyOpen: 0),
                  _LessonPanel(sections: _audioMimicryLessons(), initiallyOpen: 0),
                  _LessonPanel(sections: _conversationLessons(), initiallyOpen: 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════════════════
//  Lesson panel — three collapsible sections (accordion: one open at a time)
// ═══════════════════════════════════════════════════════════════════════════════

class _LessonPanel extends StatefulWidget {
  final List<List<_LessonEntry>> sections;
  final int? initiallyOpen;

  const _LessonPanel({
    required this.sections,
    this.initiallyOpen,
  });

  @override
  State<_LessonPanel> createState() => _LessonPanelState();
}

class _LessonPanelState extends State<_LessonPanel> {
  late int? _expandedIndex;

  static const _sectionLabels = ['Basics', 'Intermediate', 'Advanced'];
  static const _sectionIcons = [
    Icons.spa_rounded,
    Icons.local_fire_department_rounded,
    Icons.bolt_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _expandedIndex = widget.initiallyOpen;
  }

  void _onToggle(int index) {
    setState(() {
      // If tapping the already-open section, close it. Otherwise open it
      // (which implicitly closes the previous one).
      _expandedIndex = (_expandedIndex == index) ? null : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        for (var i = 0; i < widget.sections.length; i++)
          _CollapsibleSection(
            label: _sectionLabels[i],
            icon: _sectionIcons[i],
            lessons: widget.sections[i],
            isExpanded: _expandedIndex == i,
            onToggle: () => _onToggle(i),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Collapsible section with smooth animation (controlled by parent)
// ═══════════════════════════════════════════════════════════════════════════════

class _CollapsibleSection extends StatefulWidget {
  final String label;
  final IconData icon;
  final List<_LessonEntry> lessons;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _CollapsibleSection({
    required this.label,
    required this.icon,
    required this.lessons,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: widget.isExpanded ? 1.0 : 0.0,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(_CollapsibleSection old) {
    super.didUpdateWidget(old);
    if (widget.isExpanded != old.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unlockedCount = widget.lessons.where((l) => l.unlocked).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.inputBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onToggle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(widget.icon, size: 20, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(
                        widget.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (unlockedCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$unlockedCount / ${widget.lessons.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      const Spacer(),
                      RotationTransition(
                        turns: _rotateAnimation,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textSecondary,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizeTransition(
              sizeFactor: _expandAnimation,
              axisAlignment: -1.0,
              child: Column(
                children: [
                  Divider(height: 1, color: AppColors.inputBorder),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                    child: Column(
                      children: widget.lessons.map((l) => _LessonTile(lesson: l)).toList(),
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

// ═══════════════════════════════════════════════════════════════════════════════
//  Individual lesson tile
// ═══════════════════════════════════════════════════════════════════════════════

class _LessonTile extends StatelessWidget {
  final _LessonEntry lesson;
  const _LessonTile({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final locked = !lesson.unlocked;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: locked ? null : () => lesson.onTap?.call(context),
          child: Opacity(
            opacity: locked ? 0.45 : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: locked ? Colors.transparent : AppColors.primary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: locked
                          ? AppColors.inputBorder.withOpacity(0.5)
                          : AppColors.primaryLight,
                    ),
                    child: Icon(
                      locked ? Icons.lock_outline_rounded : lesson.icon,
                      size: 18,
                      color: locked ? AppColors.textSecondary : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: locked ? AppColors.textSecondary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lesson.subtitle,
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    locked ? Icons.lock_outline_rounded : Icons.chevron_right_rounded,
                    size: 18,
                    color: locked
                        ? AppColors.textSecondary.withOpacity(0.5)
                        : AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}