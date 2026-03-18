import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/local_storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../data/navi_lesson_audio.dart';
import '../lessons/audio_mimicry_screen.dart';
/// ProfileSetupPage — linear multi-step onboarding flow matching Scenario Two.
/// Steps: Username → Language → Learning Goals → Account Settings → Home
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
    // _loadExistingProfile();
  }

  void _goToAudioMimicry() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AudioMimicryScreen(lesson: naviAudioLesson),
      ),
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
                label: 'Lesson 1\nWord Match',
                onTap: () {
                  // TODO: navigate to Word Match screen
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