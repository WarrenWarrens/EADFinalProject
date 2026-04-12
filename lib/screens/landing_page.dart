import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/local_storage_service.dart';
import '../services/music_service.dart';
import '../models/user_profile.dart';
import 'auth/login_page.dart';
import 'auth/signup_page.dart';
import 'setup/profile_setup_page.dart';
import '../widgets/common_widgets.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  void initState() {
    super.initState();
    //MusicService().play(MusicTrack.landing);
  }

  Future<void> _continueAsGuest(BuildContext context) async {
    final storage = LocalStorageService();
    final guest = UserProfile.guest();
    await storage.saveProfile(guest);
    await storage.saveSetupStep(0);
    await storage.setOnboardingComplete(false);
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

            // ── Logo ──────────────────────────────────────────────
            Image.asset(
              'assets/Logo/Lingualogo.png',
              width: 320,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),

            // ── Tagline ───────────────────────────────────────────
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

            // ── Begin Your Journey (Sign Up) — filled purple ──────
            _LandingButton(
              label: 'Begin Your Journey',
              style: _ButtonStyle.filled,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SignupPage()),
              ),
            ),
            const SizedBox(height: 30),

            // ── Resume Your Adventure (Login) — gold-bordered ─────
            _LandingButton(
              label: 'Resume Your Adventure',
              style: _ButtonStyle.outlined,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginPage()),
              ),
            ),
            const SizedBox(height: 30),

            // ── Continue as Guest — parchment fill ────────────────
            _LandingButton(
              label: 'Continue as Guest',
              style: _ButtonStyle.soft,
              onTap: () => _continueAsGuest(context),
            ),

            const SizedBox(height: 40),

            const SizedBox(height: 44),
          ],
        ),
      ),
    );
  }

  Widget _flourishLine(bool leftToRight) {
    return Container(
      width: 32,
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: leftToRight ? Alignment.centerLeft : Alignment.centerRight,
          end: leftToRight ? Alignment.centerRight : Alignment.centerLeft,
          colors: [
            AppColors.parchmentAccent.withOpacity(0.0),
            AppColors.parchmentAccent,
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Landing button — three visual styles, all equally prominent
// ═══════════════════════════════════════════════════════════════════════════════

enum _ButtonStyle { filled, outlined, soft }

class _LandingButton extends StatelessWidget {
  final String label;
  final _ButtonStyle style;
  final VoidCallback onTap;

  const _LandingButton({
    required this.label,
    required this.style,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color fgColor;
    final BorderSide border;

    switch (style) {
      case _ButtonStyle.filled:
        bgColor = AppColors.primary;
        fgColor = Colors.white;
        border = BorderSide.none;
      case _ButtonStyle.outlined:
        bgColor = Colors.transparent;
        fgColor = AppColors.goldDark;
        border = BorderSide(color: AppColors.parchmentAccent, width: 1.5);
      case _ButtonStyle.soft:
        bgColor = AppColors.parchmentDark.withOpacity(0.6);
        fgColor = AppColors.goldDark;
        border = BorderSide.none;
    }

    return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
                side: border,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
            onPressed: onTap,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            )
        )
    );

  }
}