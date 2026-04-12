import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'persistent_bar.dart';
import 'screens/landing_page.dart';
import 'screens/setup/profile_setup_page.dart';
import 'screens/home/homeScreen.dart';
import 'services/local_storage_service.dart';
import 'services/music_service.dart';
import 'services/volume_service.dart';
import 'widgets/app_language.dart';
import 'screens/model_bootstrap_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Safety net: catch unhandled errors that bubble up through the Flutter
  // engine boundary (e.g. DeadObjectException from the flutter_tts plugin
  // when the Android TTS binder dies on certain emulator images).
  PlatformDispatcher.instance.onError = (error, stack) {
    final msg = error.toString();
    if (msg.contains('DeadObjectException') ||
        msg.contains('TextToSpeech') ||
        msg.contains('TTS')) {
      debugPrint('[App] TTS engine error caught at platform boundary: $error');
      return true; // handled — do not crash
    }
    return false;
  };

  await VolumeService().load();
  runApp(const LinguaLoreApp());
}

class LinguaLoreApp extends StatefulWidget {
  const LinguaLoreApp({super.key});

  @override
  State<LinguaLoreApp> createState() => _LinguaLoreAppState();
}

class _LinguaLoreAppState extends State<LinguaLoreApp>
    with WidgetsBindingObserver {
  // ThemeData built once from constants — same object references on every
  // build so Flutter never invalidates the Material tree unnecessarily.
  static final _accent      = AppTheme.accentFor(AppLanguage.navi);
  static final _materialDark  = AppTheme.dark.toMaterialTheme(_accent);
  static final _materialLight = AppTheme.light.toMaterialTheme(_accent);

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
    // ValueListenableBuilder only rebuilds MaterialApp when the user
    // explicitly switches themes in Settings — not on every frame.
    return ValueListenableBuilder<int>(
      valueListenable: appThemeIndex,
      builder: (context, idx, _) {
        final themeMode = AppTheme.themes[idx].isDark
            ? ThemeMode.dark
            : ThemeMode.light;
        return MaterialApp(
          title: 'LinguaLore',
          theme: _materialLight,
          darkTheme: _materialDark,
          themeMode: themeMode,
          debugShowCheckedModeBanner: false,
          navigatorKey: appNavigatorKey,
          //home: const _StartupRouter(),
          home: const _ModelGate(),
          builder: (context, child) {
            return PersistentBarWrapper(
              child: child ?? const SizedBox.shrink(),
            );
          },
          routes: {
            '/setup': (_) => const ProfileSetupPage(),
            '/home': (_) => const HomeScreen(),
          },
        );
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
/// Gates the rest of the app on model availability. On first launch (or
/// after user cleared app data), shows the download UI. Otherwise proceeds
/// immediately to the normal startup routing.
class _ModelGate extends StatefulWidget {
  const _ModelGate();

  @override
  State<_ModelGate> createState() => _ModelGateState();
}

class _ModelGateState extends State<_ModelGate> {
  bool _ready = false;

  @override
  Widget build(BuildContext context) {
    if (_ready) return const _StartupRouter();
    return ModelBootstrapPage(onReady: () => setState(() => _ready = true));
  }
}