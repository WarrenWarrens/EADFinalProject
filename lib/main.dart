import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'persistent_bar.dart';
import 'screens/landing_page.dart';
import 'screens/setup/profile_setup_page.dart';
import 'screens/home/homeScreen.dart';
import 'services/local_storage_service.dart';
import 'services/music_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LinguaLoreApp());
}

class LinguaLoreApp extends StatefulWidget {
  const LinguaLoreApp({super.key});

  @override
  State<LinguaLoreApp> createState() => _LinguaLoreAppState();
}

class _LinguaLoreAppState extends State<LinguaLoreApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    MusicService().dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final music = MusicService();
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        music.pause();
      case AppLifecycleState.resumed:
        if (music.currentTrack != null) music.resume();
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LinguaLore',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      home: const _StartupRouter(),
      builder: (context, child) {
        return PersistentBarWrapper(child: child ?? const SizedBox.shrink());
      },
      routes: {
        '/setup': (_) => const ProfileSetupPage(),
        '/home': (_) => const HomeScreen(),
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
      PersistentBarController.instance.show();
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}