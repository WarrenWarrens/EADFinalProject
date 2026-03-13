import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/local_storage_service.dart';
import '../models/user_profile.dart';
import 'auth/login_page.dart';
import 'auth/signup_page.dart';
import 'setup/profile_setup_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  Future<void> _continueAsGuest(BuildContext context) async {
    final storage = LocalStorageService();
    final guest = UserProfile.guest();
    await storage.saveProfile(guest);
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ProfileSetupPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Logo / Title
              const AppHeader(topPadding: 0),

              const Spacer(flex: 3),

              // Login button
              SoftButton(
                label: 'Login',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                ),
              ),
              const SizedBox(height: 16),

              // Sign Up button
              SoftButton(
                label: 'Sign Up',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignupPage()),
                ),
              ),
              const SizedBox(height: 16),

              // Guest Login button
              SoftButton(
                label: 'Guest Login',
                onTap: () => _continueAsGuest(context),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
