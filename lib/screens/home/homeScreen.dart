import 'package:flutter/material.dart';
import '../../models/lessons.dart';
import '../../models/user_profile.dart';
import '../../services/local_storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../data/navi_lesson_audio.dart';
import '../lessons/audio_mimicry_screen.dart';
import 'lessonPage.dart';
import '../../services/lessonService.dart';


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

  void _goToAudioMimicry() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AudioMimicryScreen(lesson: naviAudioLesson),
      ),
    );
  }

  // Navigate to a JSON-based lesson
  void _startLesson(int lessonNumber) async {
    // Grab the corresponding json file for the lesson
    Lesson lesson = await loadLesson('lesson$lessonNumber.json');

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LessonPage(lesson: lesson)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child:
      SafeArea(
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

              // Lesson 1 — Word Match (coming soon)
              LessonButton(
                label: 'Lesson1',
                onTap: (){
                  print('tapped');
                  _startLesson(1);
                },
              ),
              const SizedBox(height: 20),

              // Lesson 2 — Audio Mimicry
              LessonButton(
                label: 'Lesson 2\nAudio Mimicry',
                onTap: _goToAudioMimicry,
              ),
              const SizedBox(height: 20),

              // Lesson 3 — Conversation (coming soon)
              LessonButton(
                label: 'Lesson 3\nConversation',
                onTap: () {
                  // TODO: navigate to Conversational Simulation screen
                },
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