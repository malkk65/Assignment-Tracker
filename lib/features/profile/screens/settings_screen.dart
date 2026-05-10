import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/cache/user_cache.dart';
import '../../../core/widgets/section_label.dart';
import '../../../core/widgets/settings_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotify = true;
  bool _emailDigest = false;
  bool _isDark = false;

  Future<void> _handleLogout() async {
    final bool confirm = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirm Logout'),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Logout'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm && mounted) {
      UserCache.clear();
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      }
    }
  }

  Future<void> _handleChangePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send reset email.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('App Preferences'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel(title: 'Notification Channels'),
            SettingsCard(children: [
              SwitchListTile(
                title: const Text('Push Notifications'),
                subtitle: const Text('Instant alerts for deadlines'),
                value: _pushNotify,
                activeTrackColor: AppColors.primary,
                onChanged: (v) => setState(() => _pushNotify = v),
              ),
              SwitchListTile(
                title: const Text('Email Digests'),
                subtitle: const Text('Weekly summary of assignments'),
                value: _emailDigest,
                activeTrackColor: AppColors.primary,
                onChanged: (v) => setState(() => _emailDigest = v),
              ),
            ]),
            const SizedBox(height: 25),
            const SectionLabel(title: 'Visual & Local'),
            SettingsCard(children: [
              ListTile(
                title: const Text('Interface Theme'),
                trailing: ToggleButtons(
                  isSelected: [!_isDark, _isDark],
                  onPressed: (index) => setState(() => _isDark = index == 1),
                  borderRadius: BorderRadius.circular(20),
                  selectedColor: Colors.white,
                  fillColor: AppColors.primary,
                  constraints: const BoxConstraints(minHeight: 30, minWidth: 60),
                  children: const [Text('Light'), Text('Dark')],
                ),
              ),
              const ListTile(
                title: Text('App Language'),
                trailing: Text(
                  'English',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ]),
            const SizedBox(height: 25),
            const SectionLabel(title: 'Account Actions'),
            SettingsCard(children: [
              ListTile(
                leading: const Icon(Icons.lock_reset, color: AppColors.primary),
                title: const Text('Change Password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _handleChangePassword,
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: _handleLogout,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
