import 'package:flutter/material.dart';
import '../../../models/user_profile.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common_widgets.dart';

class StepUsername extends StatefulWidget {
  final UserProfile profile;
  final Future<void> Function(UserProfile) onNext;

  const StepUsername({super.key, required this.profile, required this.onNext});

  @override
  State<StepUsername> createState() => _StepUsernameState();
}

class _StepUsernameState extends State<StepUsername> {
  final _controller = TextEditingController();
  String? _error;

  // Avatar options — replace with your actual asset paths
  final List<String> _avatarOptions = [
    'assets/avatars/avatar_1.png',
    'assets/avatars/avatar_2.png',
    'assets/avatars/avatar_3.png',
    'assets/avatars/avatar_4.png',
    'assets/avatars/avatar_5.png',
    'assets/avatars/avatar_6.png',
  ];
  int _selectedAvatar = 0;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.profile.username ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_controller.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a username');
      return;
    }
    widget.onNext(widget.profile.copyWith(
      username: _controller.text.trim(),
      avatarPath: _avatarOptions[_selectedAvatar],
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
              const AppHeader(),

              // Avatar selector
              GestureDetector(
                onTap: () => _showAvatarPicker(context),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.primaryLight,
                  child: const Icon(Icons.person,
                      size: 48, color: AppColors.primary),
                  // backgroundImage: AssetImage(_avatarOptions[_selectedAvatar]),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _showAvatarPicker(context),
                child: const Text('Change avatar',
                    style: TextStyle(color: AppColors.primary, fontSize: 13)),
              ),
              const SizedBox(height: 24),

              const Text(
                'Please enter your username:',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),

              AppTextField(
                hint: 'username',
                controller: _controller,
                showClearButton: false,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(_error!,
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 12)),
                ),

              const Spacer(),

              Row(
                children: [
                  // Back disabled on first step but shown for consistency
                  Opacity(
                    opacity: 0.0,
                    child: _NavButton(
                        icon: Icons.arrow_back, onTap: () {}),
                  ),
                  const Spacer(),
                  _NavButton(icon: Icons.arrow_forward, onTap: _next),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showAvatarPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: GridView.builder(
          shrinkWrap: true,
          itemCount: _avatarOptions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12),
          itemBuilder: (_, i) => GestureDetector(
            onTap: () {
              setState(() => _selectedAvatar = i);
              Navigator.pop(context);
            },
            child: CircleAvatar(
              backgroundColor: i == _selectedAvatar
                  ? AppColors.primary
                  : AppColors.primaryLight,
              child: Icon(Icons.person,
                  color: i == _selectedAvatar
                      ? Colors.white
                      : AppColors.primary),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(16),
        minimumSize: Size.zero,
        backgroundColor: AppColors.primary,
      ),
      onPressed: onTap,
      child: Icon(icon, color: Colors.white),
    );
  }
}
