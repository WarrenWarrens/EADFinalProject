import 'package:flutter/material.dart';
import '../../../models/user_profile.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common_widgets.dart';

class StepAccountSettings extends StatefulWidget {
  final UserProfile profile;
  final Future<void> Function(UserProfile) onFinish;
  final VoidCallback onBack;

  const StepAccountSettings({
    super.key,
    required this.profile,
    required this.onFinish,
    required this.onBack,
  });

  @override
  State<StepAccountSettings> createState() => _StepAccountSettingsState();
}

class _StepAccountSettingsState extends State<StepAccountSettings> {
  late bool _shareData;
  late bool _notifications;
  late bool _microphone;
  late bool _camera;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _shareData = widget.profile.shareData;
    _notifications = widget.profile.notifications;
    _microphone = widget.profile.allowMicrophone;
    _camera = widget.profile.allowCamera;
  }

  Future<void> _finish() async {
    setState(() => _loading = true);
    await widget.onFinish(widget.profile.copyWith(
      shareData: _shareData,
      notifications: _notifications,
      allowMicrophone: _microphone,
      allowCamera: _camera,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              const Text(
                'Please finalize\nyour account!',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              _ToggleRow(
                label: 'Share Data?',
                value: _shareData,
                onChanged: (v) => setState(() => _shareData = v),
              ),
              _ToggleRow(
                label: 'Allow Notifications?',
                value: _notifications,
                onChanged: (v) => setState(() => _notifications = v),
              ),
              _ToggleRow(
                label: 'Allow Microphone?',
                value: _microphone,
                onChanged: (v) => setState(() => _microphone = v),
              ),
              _ToggleRow(
                label: 'Allow Camera?',
                value: _camera,
                onChanged: (v) => setState(() => _camera = v),
              ),
              _ToggleRow(
                label: 'Ask not to Track?',
                value: !_shareData,
                onChanged: (v) => setState(() => _shareData = !v),
              ),

              const Spacer(flex: 3),

              Row(
                children: [
                  NavButton(icon: Icons.arrow_back, onTap: widget.onBack),
                  const Spacer(),
                  _loading
                      ? const CircularProgressIndicator()
                      : NavButton(
                      icon: Icons.arrow_forward, onTap: _finish),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: value ? AppColors.primaryLight : AppColors.buttonSoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}