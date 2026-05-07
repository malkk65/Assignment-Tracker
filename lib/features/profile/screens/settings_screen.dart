import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotify = true;
  bool _emailDigest = false;
  bool _isDark = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('App Preferences'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Notification Channels'),
            _buildSettingsCard([
              SwitchListTile(
                title: const Text('Push Notifications'),
                subtitle: const Text('Instant alerts for deadlines'),
                value: _pushNotify,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _pushNotify = v),
              ),
              SwitchListTile(
                title: const Text('Email Digests'),
                subtitle: const Text('Weekly summary of assignments'),
                value: _emailDigest,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _emailDigest = v),
              ),
            ]),
            const SizedBox(height: 25),
            _sectionTitle('Visual & Local'),
            _buildSettingsCard([
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
            _sectionTitle('Account Actions'),
            _buildSettingsCard([
              ListTile(
                leading: const Icon(Icons.lock_reset, color: AppColors.primary),
                title: const Text('Change Password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null && user.email != null) {
                    try {
                      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password reset email sent. Check your inbox.')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to send reset email.')),
                        );
                      }
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () async {
                  final bool confirm = await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: const Text('Confirm Logout'),
                        content: const Text('Are you sure you want to log out of your account?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Logout', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      );
                    },
                  ) ?? false;

                  if (confirm && context.mounted) {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    }
                  }
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(left: 5, bottom: 10),
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: children),
    );
  }
}
