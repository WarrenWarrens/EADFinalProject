import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/local_storage_service.dart';
import '../../services/lessonService.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../data/navi_lesson_audio.dart';
import '../lessons/audio_mimicry_screen.dart';
import '../lessons/simulation.dart';
import 'lessonPage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserProfile? _profile;
  final _storage = LocalStorageService();

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final saved = await _storage.loadProfile();
    if (mounted) {
      setState(() => _profile = saved);
    }
  }

  Future<void> _goToLesson1() async {
    final lesson = await loadLesson('lesson1.json');
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LessonPage(lesson: lesson)),
    );
  }

  void _goToAudioMimicry() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AudioMimicryScreen(lesson: naviAudioLesson),
      ),
    );
  }

  void _goToSimulation() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SimScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                Text(
                  _profile?.username != null
                      ? 'Welcome,\n${_profile!.username}!'
                      : 'Welcome!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                const Spacer(flex: 3),

                // Lesson 1 — Na'vi Vowels
                LessonButton(
                  label: "Lesson 1\nNa'vi Vowels",
                  onTap: _goToLesson1,
                ),
                const SizedBox(height: 20),

                // Lesson 2 — Audio Mimicry
                LessonButton(
                  label: 'Lesson 2\nAudio Mimicry',
                  onTap: _goToAudioMimicry,
                ),
                const SizedBox(height: 20),

                // Lesson 3 — Conversation Simulation
                LessonButton(
                  label: 'Lesson 3\nConversation',
                  onTap: _goToSimulation,
                ),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}