import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/local_storage_service.dart';
import '../services/music_service.dart';
import '../models/user_profile.dart';
import 'setup/profile_setup_page.dart';
import '../widgets/common_widgets.dart';

/// Landing page after the model bootstrap finishes.
///
/// Single entry point: tap "Begin Your Adventure" → a guest profile is
/// created locally and the user lands in profile setup. There is no
/// remote auth, no login page, no signup page, and no email verification
/// flow. Identification details (name, email, etc.) are collected later
/// in setup if the user wants to set them.
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _storage = LocalStorageService();
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    //MusicService().play(MusicTrack.landing);
  }

  Future<void> _begin(BuildContext context) async {
    if (_starting) return;
    setState(() => _starting = true);

    // If there's already a profile on disk, just resume it — don't
    // overwrite the user's progress with a fresh guest. Onboarded users
    // skip setup entirely; partially-set-up users land back where they
    // left off.
    final existing = await _storage.loadProfile();
    if (existing == null) {
      final guest = UserProfile.guest();
      await _storage.saveProfile(guest);
      await _storage.saveSetupStep(0);
      await _storage.setOnboardingComplete(false);
    }

    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ProfileSetupPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parchment,
      body: ResponsiveFormLayout(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 3),

            Image.asset(
              'assets/Logo/Lingualogo.png',
              width: 320,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),

            Text(
              'Learn through magic and play',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.goldDark,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),

            const Spacer(flex: 4),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                onPressed: _starting ? null : () => _begin(context),
                child: _starting
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                    AlwaysStoppedAnimation(Colors.white),
                  ),
                )
                    : const Text(
                  'Begin Your Adventure',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 84),
          ],
        ),
      ),
    );
  }
}