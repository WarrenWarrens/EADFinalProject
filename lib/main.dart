import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/landing_page.dart';
import 'screens/setup/profile_setup_page.dart';
import 'screens/home/homeScreen.dart';
import 'services/local_storage_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: await Firebase.initializeApp(); — when adding Firebase
  runApp(const LinguaLoreApp());
}

class LinguaLoreApp extends StatelessWidget {
  const LinguaLoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LinguaLore',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const _StartupRouter(),
      routes: {
        '/setup': (_) => const ProfileSetupPage(),
        '/home': (_) => const HomeScreen(),  // add when built
      },
    );
  }
}

/// Decides where to start based on saved local state:
///   • No profile saved        → LandingPage
///   • Profile saved, not done → ProfileSetupPage (resumes at saved step)
///   • Onboarding complete     → HomeScreen
class _StartupRouter extends StatefulWidget {
  const _StartupRouter();

  @override
  State<_StartupRouter> createState() => _StartupRouterState();
}

class _StartupRouterState extends State<_StartupRouter> {
  final _storage = LocalStorageService();

  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final profile = await _storage.loadProfile();
    final onboarded = await _storage.isOnboardingComplete();
    if (!mounted) return;

    if (profile == null) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LandingPage()));
    } else if (!onboarded) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProfileSetupPage()));
    } else {
      // TODO: Replace with HomeScreen
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LandingPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
