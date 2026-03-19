import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/local_storage_service.dart';
<<<<<<< Updated upstream
// import 'package:flutter/material.dart';
// import '../../../models/user_profile.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common_widgets.dart';
=======
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../data/navi_lesson_audio.dart';
import '../lessons/audio_mimicry_screen.dart';// For content
import '../lessons/simulation.dart';
import 'lessonPage.dart';
import '../../services/lessonService.dart';

>>>>>>> Stashed changes

/// ProfileSetupPage — linear multi-step onboarding flow matching Scenario Two.
/// Steps: Username → Language → Learning Goals → Account Settings → Home
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenSate();
}

class _HomeScreenSate extends State<HomeScreen> {
  UserProfile? _profile;
  final _storage = LocalStorageService();

  //TODO: load exisitng profile content
  @override
  void initState() {
    super.initState();
    // _loadExistingProfile();
  }

<<<<<<< Updated upstream
=======
  void _goToAudioMimicry() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AudioMimicryScreen(lesson: naviAudioLesson),
      ),
    );
  }

  void _goToSim() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SimScreen(),
      ),
    );
  }


>>>>>>> Stashed changes
  // TODO: go to lesson
  void _startLesson() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NextPage()),
    );
  }

<<<<<<< Updated upstream
  // // TODO: need to load content
  // Future<void> _loadExistingProfile() async {
  //   final saved = await _storage.loadProfile();
  //   final step = await _storage.getSavedSetupStep();
  //   if (mounted) {
  //     setState(() {
  //       _profile = saved ?? UserProfile(createdAt: DateTime.now());
  //       _currentStep = step;
  //     });
  //   }
  // }


=======
>>>>>>> Stashed changes

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center( child:
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,

            children: [
              const Spacer(flex: 2),

              // Logo / Title
              Title(
                child: Text('Welcome!',
                    style: TextStyle(height: 5, fontSize: 50)
                ),
                color: AppColors.textPrimary,
              ),

              const Spacer(flex: 3),

              // Lesson button
              LessonButton(
                  label: 'Lesson1',
<<<<<<< Updated upstream
                  onTap: () {}
=======
                  onTap: (){
                    _startLesson(1);
                  },
>>>>>>> Stashed changes
              ),
              const SizedBox(height: 16),

              LessonButton(
                  label: 'Lesson2',
                  onTap: () {}
              ),
              const SizedBox(height: 16),

              LessonButton(
<<<<<<< Updated upstream
                  label: 'Lesson3',
                  onTap: () {}
=======
                label: 'Lesson 3\nConversation',
                onTap: _goToSim
>>>>>>> Stashed changes
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      )
      )
    );
    }

}

class NextPage extends StatelessWidget {

  const NextPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Next Page'),),
      body: Center(
        child: Text('GeeksForGeeks'),
      ),
    );
  }
}
