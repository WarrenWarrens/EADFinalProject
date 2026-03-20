import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/local_storage_service.dart';
import '../../services/music_service.dart';
import '../../theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _storage = LocalStorageService();
  UserProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await _storage.loadProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _loading = false;
      });
    }
  }

  Future<void> _save(UserProfile updated) async {
    await _storage.saveProfile(updated);
    if (mounted) setState(() => _profile = updated);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // ── Permissions section ─────────────────────────────────────
          _SectionHeader(label: 'Permissions'),
          const SizedBox(height: 8),
          _ToggleTile(
            icon: Icons.share_rounded,
            label: 'Share Data',
            subtitle: 'Help us improve with anonymous usage data',
            value: _profile?.shareData ?? false,
            onChanged: (v) => _save(_profile!.copyWith(shareData: v)),
          ),
          _ToggleTile(
            icon: Icons.notifications_rounded,
            label: 'Notifications',
            subtitle: 'Daily reminders and lesson updates',
            value: _profile?.notifications ?? true,
            onChanged: (v) => _save(_profile!.copyWith(notifications: v)),
          ),
          _ToggleTile(
            icon: Icons.mic_rounded,
            label: 'Microphone',
            subtitle: 'Required for audio mimicry lessons',
            value: _profile?.allowMicrophone ?? false,
            onChanged: (v) => _save(_profile!.copyWith(allowMicrophone: v)),
          ),
          _ToggleTile(
            icon: Icons.camera_alt_rounded,
            label: 'Camera',
            subtitle: 'Used for avatar photos',
            value: _profile?.allowCamera ?? false,
            onChanged: (v) => _save(_profile!.copyWith(allowCamera: v)),
          ),

          const SizedBox(height: 24),

          // ── Audio section ──────────────────────────────────────────
          _SectionHeader(label: 'Audio'),
          const SizedBox(height: 8),
          _ActionTile(
            icon: Icons.music_off_rounded,
            label: 'Stop Music',
            subtitle: 'Pause the background music',
            onTap: () {
              final music = MusicService();
              if (music.isPlaying) {
                music.pause();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Music paused')),
                );
              } else {
                music.resume();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Music resumed')),
                );
              }
            },
          ),

          const SizedBox(height: 24),

          // ── Account section ────────────────────────────────────────
          _SectionHeader(label: 'Account'),
          const SizedBox(height: 8),
          _ActionTile(
            icon: Icons.email_rounded,
            label: 'Email',
            subtitle: _profile?.email ?? 'Coming soon - Not set',
            onTap: () {},
          ),
          _ActionTile(
            icon: Icons.badge_rounded,
            label: 'Account Type',
            subtitle: (_profile?.isGuest ?? true) ? 'Coming soon - Guest' : 'Coming soon - Registered',
            onTap: () {},
          ),

          const SizedBox(height: 24),

          // ── Danger zone ────────────────────────────────────────────
          _SectionHeader(label: 'Data'),
          const SizedBox(height: 8),
          _ActionTile(
            icon: Icons.delete_outline_rounded,
            label: 'Reset All Data',
            subtitle: 'Coming soon - Clear progress and start fresh',
            danger: true,
            onTap: () => _showResetConfirm(context),
          ),
        ],
      ),
    );
  }

  void _showResetConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset all data?',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: const Text(
          'This will clear your profile, progress, and all lesson data. This cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _storage.clearAll();
              if (!mounted) return;
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: const Text('Reset',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Sub-widgets
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary)),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: danger
                                  ? AppColors.error
                                  : AppColors.textPrimary)),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
