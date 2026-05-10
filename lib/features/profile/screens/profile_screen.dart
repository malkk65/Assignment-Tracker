import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/cache/user_cache.dart';
import '../../../core/services/user_service.dart';
import '../../../core/widgets/action_tile.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/stat_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ── Helpers ──

  String _getFallbackName(String? email) {
    if (email == null || email.isEmpty) return 'Student';
    return email.split('@')[0];
  }

  String get _userName {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName;
    return (name != null && name.isNotEmpty) ? name : _getFallbackName(user?.email);
  }

  // ── Actions ──

  void _showEditProfileDialog() {
    final user = FirebaseAuth.instance.currentUser;
    final nameController = TextEditingController(text: _userName);
    final uniController = TextEditingController(text: UserCache.university);
    final facController = TextEditingController(text: UserCache.faculty);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: uniController,
                decoration: const InputDecoration(labelText: 'University'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: facController,
                decoration: const InputDecoration(labelText: 'Faculty'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (user == null) return;

              await user.updateDisplayName(nameController.text.trim());
              await user.reload();

              await UserService.updateUserProfile(
                uid: user.uid,
                name: nameController.text.trim(),
                university: uniController.text.trim(),
                faculty: facController.text.trim(),
              );

              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully!')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No email found to reset password.')),
        );
      }
      return;
    }
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

  Future<void> _logout() async {
    UserCache.clear();
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = _userName;
    final userEmail = user?.email ?? 'student@university.edu';
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'S';
    final roleColor = UserCache.isAdmin ? AppColors.primary : AppColors.primaryLight;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            // ── Profile Card ──
            _ProfileCard(
              initial: initial,
              userName: userName,
              userEmail: userEmail,
              roleColor: roleColor,
              onEditTap: _showEditProfileDialog,
            ),
            const SizedBox(height: 20),

            // ── Stats Grid ──
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 1.5,
              children: const [
                StatCard(label: 'TOTAL TASKS', value: '12'),
                StatCard(label: 'COMPLETED', value: '8'),
                StatCard(label: 'IN PROGRESS', value: '3', valueColor: AppColors.textSecondary),
                StatCard(label: 'OVERDUE', value: '1', valueColor: AppColors.error),
              ],
            ),
            const SizedBox(height: 20),

            // ── Academic Info ──
            _AcademicInfoCard(),
            const SizedBox(height: 20),

            // ── Actions ──
            ActionTile(
              title: 'Change Password',
              subtitle: 'Send a reset link to your email',
              icon: Icons.lock_reset,
              onTap: _resetPassword,
            ),
            const SizedBox(height: 15),
            ActionTile(
              title: 'Account Settings',
              subtitle: 'Update your workspace preferences',
              icon: Icons.settings_applications,
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
            const SizedBox(height: 15),
            ActionTile(
              title: 'Logout',
              subtitle: 'Safely exit your current session',
              icon: Icons.logout,
              color: AppColors.error,
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private Sub-Widgets ───────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final String initial;
  final String userName;
  final String userEmail;
  final Color roleColor;
  final VoidCallback onEditTap;

  const _ProfileCard({
    required this.initial,
    required this.userName,
    required this.userEmail,
    required this.roleColor,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: roleColor,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.card, width: 2),
                  ),
                  child: Text(
                    UserCache.role.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            userName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            userEmail,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onEditTap,
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit Profile'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AcademicInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance, color: AppColors.primary),
              SizedBox(width: 10),
              Text(
                'Academic Identity',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const Divider(height: 30),
          InfoRow(label: 'UNIVERSITY', value: UserCache.university),
          InfoRow(label: 'FACULTY', value: UserCache.faculty),
          InfoRow(
            label: 'ACADEMIC ROLE',
            value: '${UserCache.role.icon} ${UserCache.role.displayName}',
          ),
        ],
      ),
    );
  }
}
