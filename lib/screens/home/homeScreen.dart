import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/local_storage_service.dart';
// import 'package:flutter/material.dart';
// import '../../../models/user_profile.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common_widgets.dart';

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

  // TODO: go to lesson
  void _startLesson() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NextPage()),
    );
  }

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
                  onTap: () {}
              ),
              const SizedBox(height: 16),

              LessonButton(
                  label: 'Lesson2',
                  onTap: () {}
              ),
              const SizedBox(height: 16),

              LessonButton(
                  label: 'Lesson3',
                  onTap: () {}
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
