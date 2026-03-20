import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/local_storage_service.dart';
import '../../persistent_bar.dart';
import 'steps/step_username.dart';
import 'steps/step_language.dart';
import 'steps/step_goals.dart';
import 'steps/step_account_settings.dart';

/// ProfileSetupPage — linear multi-step onboarding flow matching Scenario Two.
/// Steps: Username → Language → Learning Goals → Account Settings → Home
class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  int _currentStep = 0;
  UserProfile? _profile;
  final _storage = LocalStorageService();

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final saved = await _storage.loadProfile();
    final step = await _storage.getSavedSetupStep();
    if (mounted) {
      setState(() {
        _profile = saved ?? UserProfile(createdAt: DateTime.now());
        _currentStep = step;
      });
    }
  }

  Future<void> _saveAndAdvance(UserProfile updated) async {
    await _storage.saveProfile(updated);
    await _storage.saveSetupStep(_currentStep + 1);
    if (mounted) {
      setState(() {
        _profile = updated;
        _currentStep++;
      });
    }
  }

  Future<void> _finalize(UserProfile updated) async {
    await _storage.saveProfile(updated);
    await _storage.setOnboardingComplete(true);
    await _storage.saveSetupStep(0);
    if (!mounted) return;
    PersistentBarController.instance.show();
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _storage.saveSetupStep(_currentStep);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    switch (_currentStep) {
      case 0:
        return StepUsername(
          profile: _profile!,
          onNext: _saveAndAdvance,
        );
      case 1:
        return StepLanguage(
          profile: _profile!,
          onNext: _saveAndAdvance,
          onBack: _goBack,
        );
      case 2:
        return StepGoals(
          profile: _profile!,
          onNext: _saveAndAdvance,
          onBack: _goBack,
        );
      case 3:
        return StepAccountSettings(
          profile: _profile!,
          onFinish: _finalize,
          onBack: _goBack,
        );
      default:
      // Should not reach here; finalize navigates away
        return const SizedBox.shrink();
    }
  }
}