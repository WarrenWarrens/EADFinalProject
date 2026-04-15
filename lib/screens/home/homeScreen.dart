import 'dart:io';

import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/local_storage_service.dart';
import '../../services/lessonService.dart';
import '../../services/music_service.dart';
import '../../persistent_bar.dart';
import '../../data/navi_lesson_audio.dart';
import '../../widgets/app_nav_bar.dart';
import '../../widgets/app_language.dart';
import '../../widgets/lesson_card.dart';
import '../../theme/app_theme.dart';
import '../lessons/audio_mimicry_screen.dart';
import '../lessons/simulation.dart';
import 'lessonPage.dart';
import 'profile_screen.dart';
import 'study_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserProfile? _profile;
  final _storage = LocalStorageService();
  final _music = MusicService();
  final _bar = PersistentBarController.instance;

  int _selectedDifficulty = 0;
  int _selectedNav = 2;
  AppLanguage _selectedLanguage = AppLanguage.navi;
  // Index of the currently expanded lesson card (-1 = none). Only one
  // card may be expanded at a time within the list.
  int _expandedLessonIndex = -1;

  static const _difficultyLabels = ['Fundamental', 'Intermediate', 'Advanced'];
  static const _difficultyIcons = [
    Icons.auto_awesome_rounded,
    Icons.local_fire_department_rounded,
    Icons.bolt_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _bar.show();
    _loadExistingProfile();
    _music.crossfadeTo(MusicTrack.home);
  }

  Future<void> _loadExistingProfile() async {
    final saved = await _storage.loadProfile();
    if (mounted) setState(() => _profile = saved);
  }

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

  Future<void> _goToLesson2(BuildContext ctx) async {
    await _enterLesson(() async {
      final lesson = await loadLesson('lesson2_vocabulary.json');
      if (!mounted) return;
      await Navigator.push(
        ctx,
        MaterialPageRoute(builder: (_) => LessonPage(lesson: lesson)),
      );
    });
  }

  Future<void> _goToLesson3(BuildContext ctx) async {
    await _enterLesson(() async {
      final lesson = await loadLesson('lesson3_introductions.json');
      if (!mounted) return;
      await Navigator.push(
        ctx,
        MaterialPageRoute(builder: (_) => LessonPage(lesson: lesson)),
      );
    });
  }

  Future<void> _goToLesson4(BuildContext ctx) async {
    await _enterLesson(() async {
      final lesson = await loadLesson('lesson4_cases.json');
      if (!mounted) return;
      await Navigator.push(
        ctx,
        MaterialPageRoute(builder: (_) => LessonPage(lesson: lesson)),
      );
    });
  }
  Future<void> _goToLesson5(BuildContext ctx) async {
    await _enterLesson(() async {
      final lesson = await loadLesson('lesson5_adjectives.json');
      if (!mounted) return;
      await Navigator.push(
        ctx,
        MaterialPageRoute(builder: (_) => LessonPage(lesson: lesson)),
      );
    });
  }
  
  Future<void> _goToLesson6(BuildContext ctx) async {
    await _enterLesson(() async {
      final lesson = await loadLesson('lesson6_questions.json');
      if (!mounted) return;
      await Navigator.push(
        ctx,
        MaterialPageRoute(builder: (_) => LessonPage(lesson: lesson)),
      );
    });
  }

  Future<void> _goToKlingonLesson1(BuildContext ctx) async {
    await _enterLesson(() async {
      final lesson = await loadLesson('klingonlesson1.json');
      if (!mounted) return;
      await Navigator.push(
        ctx,
        MaterialPageRoute(builder: (_) => LessonPage(lesson: lesson)),
      );
    });
  }

  Future<void> _goToKlingonLesson2(BuildContext ctx) async {
    await _enterLesson(() async {
      final lesson = await loadLesson('klingonlesson2.json');
      if (!mounted) return;
      await Navigator.push(
        ctx,
        MaterialPageRoute(builder: (_) => LessonPage(lesson: lesson)),
      );
    });
  }

  Future<void> _goToKlingonLesson3(BuildContext ctx) async {
    await _enterLesson(() async {
      final lesson = await loadLesson('klingonlesson3.json');
      if (!mounted) return;
      await Navigator.push(
        ctx,
        MaterialPageRoute(builder: (_) => LessonPage(lesson: lesson)),
      );
    });
  }

  Future<void> _goToKlingonLesson4(BuildContext ctx) async {
    await _enterLesson(() async {
      final lesson = await loadLesson('klingonlesson4.json');
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
            builder: (_) => AudioMimicryScreen(lesson: naviAudioLesson)),
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


  List<LessonEntry> _getLessons() {
    switch (_selectedLanguage) {
      case AppLanguage.klingon:
        return _klingonLessons();
      case AppLanguage.highValyrian:
        return _highValyrianLessons();
      case AppLanguage.navi:
      default:
        return _naviLessons();
    }
  }


  List<LessonEntry> _naviLessons() {
    switch (_selectedDifficulty) {
      case 0:
        return [
          LessonEntry(
            id: 'nv_intro',
            title: 'Introduction',
            description:
            "Here's what you'll learn:\n- Na'vi script basics\n- Pronunciation rules",
            practiceInfo:
            "Here's how you'll practice:\n- Matching game\n- Memory game",
            unlocked: true,
            onTap: _goToLesson1,
          ),
          LessonEntry(
            id: 'nv_vowels',
            title: 'Vowels',
            description:
            "Here's what you'll learn:\n- Vowels\n- How to pronounce",
            practiceInfo:
            "Here's how you'll practice:\n- Matching game\n- Memory game",
            unlocked: true,
            onTap: _goToLesson1,
          ),
          LessonEntry(
            id: 'nv_vocab',
            title: 'Vocabulary',
            description:
            "Here's what you'll learn:\n- Family words\n- Nature & world words",
            practiceInfo:
            "Here's how you'll practice:\n- Flashcards\n- Audio mimicry",
            unlocked: true,
            onTap: _goToLesson2,
          ),
          LessonEntry(
            id: 'nv_introductions',
            title: 'Introductions',
            description:
            "Here's what you'll learn:\n- Greetings & farewells\n- Self-introductions",
            practiceInfo:
            "Here's how you'll practice:\n- Dialogue exercises\n- Audio mimicry",
            unlocked: true,
            onTap: _goToLesson3,
          ),
        ];
      case 1:
        return [
          LessonEntry(
            id: 'nv_case',
            title: 'Case System',
            description:
            "Here's what you'll learn:\n- Subject & object cases\n- Grammatical roles",
            practiceInfo:
            "Here's how you'll practice:\n- Sentence building\n- Grammar drills",
            unlocked: true,
            onTap: _goToLesson4,
          ),
          LessonEntry(
            id: 'nv_adj',
            title: 'Adjectives',
            description:
            "Here's what you'll learn:\n- Describing people & things\n- Adjective placement",
            practiceInfo:
            "Here's how you'll practice:\n- Error Identification",
            unlocked: true,
            onTap: _goToLesson5,
          ),
          LessonEntry(
            id: 'nv_questions',
            title: 'Questions',
            description:
            "Here's what you'll learn:\n- Question words\n- Intonation patterns",
            practiceInfo:
            "Here's how you'll practice:\n- Q&A exercises\n- Dialogue practice",
            unlocked: true,
            onTap: _goToLesson6,
          ),
          LessonEntry(
            id: 'nv_tense',
            title: 'Tense & Aspect',
            description:
            "Here's what you'll learn:\n- Past, present, future\n- Aspect markers",
            practiceInfo:
            "Here's how you'll practice:\n- Timeline exercises\n- Story writing",
          ),
        ];
      default:
        return [
          LessonEntry(
            id: 'nv_infixes',
            title: 'Infixes',
            description:
            "Here's what you'll learn:\n- Verb mood markers\n- Complex verb forms",
            practiceInfo:
            "Here's how you'll practice:\n- Transformation drills\n- Story narration",
          ),
          LessonEntry(
            id: 'nv_relative',
            title: 'Relative Clauses',
            description:
            "Here's what you'll learn:\n- Complex sentence structure\n- Clause linking",
            practiceInfo:
            "Here's how you'll practice:\n- Sentence combining\n- Reading passages",
          ),
          LessonEntry(
            id: 'nv_idioms',
            title: 'Idioms',
            description:
            "Here's what you'll learn:\n- Cultural expressions\n- Figurative language",
            practiceInfo:
            "Here's how you'll practice:\n- Context matching\n- Usage exercises",
          ),
          LessonEntry(
            id: 'nv_mastery',
            title: 'Mastery Quiz',
            description:
            "Here's what you'll learn:\n- All advanced topics reviewed\n- Native fluency tested",
            practiceInfo:
            "Here's how you'll practice:\n- Full exam\n- Timed challenges",
          ),
        ];
    }
  }


  List<LessonEntry> _klingonLessons() {
    switch (_selectedDifficulty) {
      case 0:
        return [
          LessonEntry(
            id: 'kl_intro',
            title: 'Introduction',
            description:
            "Here's what you'll learn:\n- Basic, aggressive greetings of the Klingon Empire\n- Pronunciation differences between the harsh, capital 'Q' and the softer, lowercase 'q'.",
            practiceInfo:
            "Here's how you'll practice:\n- Multiple choice question\n- Matching exercise",
            unlocked: true,
            onTap: _goToKlingonLesson1,

          ),
          LessonEntry(
            id: 'kl_greetings',
            title: 'Warrior Greetings',
            description:
            "Here's what you'll learn:\n- Core verbs of conflict and the concept of honor\n- Essential vocabulary for battle, including HIv (to attack)",
            practiceInfo:
            "Here's how you'll practice:\n- Multiple choice\n- Matching exercise",
            unlocked: true,
            onTap: _goToKlingonLesson2,

          ),
          LessonEntry(
            id: 'kl_vocab',
            title: 'Battle Vocabulary',
            description:
            "Here's what you'll learn:\n- Weapons & combat terms\n- Distinction between words like may' (a single battle)",
            practiceInfo:
            "Here's how you'll practice:\n- Multiple choice\n- Matching game",
            unlocked: true,
            onTap: _goToKlingonLesson3,
          ),
          LessonEntry(
            id: 'kl_commands',
            title: 'Commands',
            description:
            "Here's what you'll learn:\n- Use of the prefix 'yI-' to turn a verb into a command\n- Specific command phrases like yIqIm (Pay attention!),",
            practiceInfo:
            "Here's how you'll practice:\n- Multiple choice\n- Fill in the blank",
            unlocked: true,
            onTap: _goToKlingonLesson4,
          ),
        ];
      case 1:
        return [
          LessonEntry(
            id: 'kl_ov',
            title: 'OVS Word Order',
            description:
            "Here's what you'll learn:\n- Object-Verb-Subject structure\n- Sentence building",
            practiceInfo:
            "Here's how you'll practice:\n- Sentence scramble\n- Grammar drills",
          ),
          LessonEntry(
            id: 'kl_prefix',
            title: 'Verb Prefixes',
            description:
            "Here's what you'll learn:\n- Subject/object agreement\n- Prefix chart",
            practiceInfo:
            "Here's how you'll practice:\n- Conjugation tables\n- Fill in the blank",
          ),
          LessonEntry(
            id: 'kl_negation',
            title: 'Negation',
            description:
            "Here's what you'll learn:\n- Saying no in Klingon\n- Negative verb forms",
            practiceInfo:
            "Here's how you'll practice:\n- Sentence transformation\n- Q&A exercises",
          ),
          LessonEntry(
            id: 'kl_honor',
            title: 'Honor & Dishonor',
            description:
            "Here's what you'll learn:\n- Cultural vocabulary\n- Expressions of bravery",
            practiceInfo:
            "Here's how you'll practice:\n- Context matching\n- Dialogue practice",
          ),
        ];
      default:
        return [
          LessonEntry(
            id: 'kl_rovers',
            title: 'Rovers',
            description:
            "Here's what you'll learn:\n- Moveable verb suffixes\n- Emphasis & intensity",
            practiceInfo:
            "Here's how you'll practice:\n- Suffix drills\n- Story narration",
          ),
          LessonEntry(
            id: 'kl_relative',
            title: 'Relative Clauses',
            description:
            "Here's what you'll learn:\n- -bogh clause structure\n- Embedded sentences",
            practiceInfo:
            "Here's how you'll practice:\n- Sentence combining\n- Reading passages",
          ),
          LessonEntry(
            id: 'kl_proverbs',
            title: 'Klingon Proverbs',
            description:
            "Here's what you'll learn:\n- Famous battle proverbs\n- Cultural wisdom",
            practiceInfo:
            "Here's how you'll practice:\n- Memorisation\n- Recital exercises",
          ),
          LessonEntry(
            id: 'kl_mastery',
            title: 'Mastery Quiz',
            description:
            "Here's what you'll learn:\n- Full language review\n- Combat-readiness test",
            practiceInfo:
            "Here's how you'll practice:\n- Full exam\n- Timed challenges",
          ),
        ];
    }
  }


  List<LessonEntry> _highValyrianLessons() {
    switch (_selectedDifficulty) {
      case 0:
        return [
          LessonEntry(
            id: 'hv_intro',
            title: 'Introduction',
            description:
            "Here's what you'll learn:\n- High Valyrian origins\n- Sound system basics",
            practiceInfo:
            "Here's how you'll practice:\n- Audio matching\n- Phoneme drills",
            unlocked: true,
          ),
          LessonEntry(
            id: 'hv_greetings',
            title: 'Noble Greetings',
            description:
            "Here's what you'll learn:\n- Rytsas, Kirimvose\n- Court etiquette phrases",
            practiceInfo:
            "Here's how you'll practice:\n- Dialogue cards\n- Memory game",
            unlocked: true,
          ),
          LessonEntry(
            id: 'hv_vocab',
            title: 'Dragon Vocabulary',
            description:
            "Here's what you'll learn:\n- Fire & dragon terms\n- Royal house words",
            practiceInfo:
            "Here's how you'll practice:\n- Flashcards\n- Fill in the blank",
          ),
          LessonEntry(
            id: 'hv_lunar',
            title: 'Lunar & Solar',
            description:
            "Here's what you'll learn:\n- Day, night, moon, sun\n- Time expressions",
            practiceInfo:
            "Here's how you'll practice:\n- Matching game\n- Dialogue exercises",
          ),
        ];
      case 1:
        return [
          LessonEntry(
            id: 'hv_gender',
            title: 'Noun Genders',
            description:
            "Here's what you'll learn:\n- Lunar, Solar, Terrestrial, Aquatic\n- Agreement rules",
            practiceInfo:
            "Here's how you'll practice:\n- Classification drills\n- Sentence building",
          ),
          LessonEntry(
            id: 'hv_cases',
            title: 'Case Declension',
            description:
            "Here's what you'll learn:\n- Nominative to locative\n- Noun endings",
            practiceInfo:
            "Here's how you'll practice:\n- Declension tables\n- Fill in the blank",
          ),
          LessonEntry(
            id: 'hv_verbs',
            title: 'Verb Conjugation',
            description:
            "Here's what you'll learn:\n- Present & past tense\n- Agreement with subject",
            practiceInfo:
            "Here's how you'll practice:\n- Conjugation drills\n- Story building",
          ),
          LessonEntry(
            id: 'hv_prophecy',
            title: 'Prophecy Phrases',
            description:
            "Here's what you'll learn:\n- Azor Ahai prophecy text\n- Formal speech",
            practiceInfo:
            "Here's how you'll practice:\n- Recital\n- Translation exercises",
          ),
        ];
      default:
        return [
          LessonEntry(
            id: 'hv_subjunctive',
            title: 'Subjunctive Mood',
            description:
            "Here's what you'll learn:\n- Wishes & hypotheticals\n- Complex verb forms",
            practiceInfo:
            "Here's how you'll practice:\n- Mood drills\n- Creative writing",
          ),
          LessonEntry(
            id: 'hv_poetry',
            title: 'Valyrian Poetry',
            description:
            "Here's what you'll learn:\n- Verse structure\n- Literary vocabulary",
            practiceInfo:
            "Here's how you'll practice:\n- Poetry recital\n- Meter analysis",
          ),
          LessonEntry(
            id: 'hv_ceremony',
            title: 'Ceremonial Speech',
            description:
            "Here's what you'll learn:\n- Wedding vows\n- Dragon-binding rituals",
            practiceInfo:
            "Here's how you'll practice:\n- Role play\n- Memorisation",
          ),
          LessonEntry(
            id: 'hv_mastery',
            title: 'Mastery Quiz',
            description:
            "Here's what you'll learn:\n- Complete language review\n- Noble fluency tested",
            practiceInfo:
            "Here's how you'll practice:\n- Full exam\n- Timed challenges",
          ),
        ];
    }
  }


  void _onNavTap(int index) {
    if (index == 2) {
      setState(() => _selectedNav = 2);
      return;
    }
    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(
            initialLanguage: _selectedLanguage,
            onLanguageChange: (lang) => setState(() {
              _selectedLanguage = lang;
              _selectedDifficulty = 0;
            }),
          ),
        ),
      );
      return;
    }
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudyPage(selectedLanguage: _selectedLanguage),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final lessons = _getLessons();
    final accent = _selectedLanguage.accentColor;
    final palette = AppTheme.of(context);




    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _DifficultySelector(
              selected: _selectedDifficulty,
              labels: _difficultyLabels,
              icons: _difficultyIcons,
              accentColor: accent,
              onSelect: (i) => setState(() {
                _selectedDifficulty = i;
                _expandedLessonIndex = -1;
              }),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: lessons.length,
                itemBuilder: (ctx, i) {
                  final entry = lessons[i];
                  return LessonCard(
                    lesson: entry,
                    accentColor: accent,
                    // accentColor: AppLanguage.klingon.accentColor,
                    // onBegin: entry.unlocked ? () => entry.onTap?.call(context) : null,
                    expanded: _expandedLessonIndex == i,
                    onExpansionChanged: () {
                      setState(() {
                        _expandedLessonIndex =
                        _expandedLessonIndex == i ? -1 : i;
                      });
                    },
                    onBegin: entry.unlocked
                        ? () => entry.onTap?.call(context)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppNavBar(
        selectedIndex: _selectedNav,
        selectedLanguage: _selectedLanguage,
        onTap: _onNavTap,
        onLanguageSelect: (lang) {
          setState(() {
            _selectedLanguage = lang;
            _selectedDifficulty = 0;
            _expandedLessonIndex = -1;
          });
        },
      ),
    );
  }
}


class _DifficultySelector extends StatelessWidget {
  final int selected;
  final List<String> labels;
  final List<IconData> icons;
  final Color accentColor;
  final ValueChanged<int> onSelect;

  const _DifficultySelector({
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
          final isSelected = selected == i;
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
                          color: isSelected
                              ? accentColor
                              : palette.border,
                          width: isSelected ? 2.5 : 1.5,
                        ),
                        boxShadow: isSelected
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
                          color: isSelected
                              ? accentColor
                              : palette.textMuted,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? palette.textPrimary
                            : palette.textMuted,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 3,
                      width: isSelected ? 32 : 0,
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