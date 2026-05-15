import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/cache/user_cache.dart';
import '../../../core/widgets/action_tile.dart';
import '../../../core/widgets/info_row.dart';
import '../../../core/widgets/custom_dialog.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _resetPassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent!')),
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
    final bool confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => CustomDialog(
            title: 'Sign Out?',
            message: 'Are you sure you want to log out? You will need to sign in again to access your assignments.',
            icon: Icons.logout_rounded,
            iconColor: AppColors.error,
            primaryButtonText: 'Logout',
            onPrimaryPressed: () {},
          ),
        ) ??
        false;

    if (!confirm) return;

    UserCache.clear();
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String userName = user?.displayName ?? 'Student';
    final String userEmail = user?.email ?? 'student@university.edu';
    final String initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'S';
    final Color roleColor = UserCache.isAdmin ? AppColors.primary : AppColors.primaryLight;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              // ── Profile Card ──
              _ProfileCard(
                initial: initial,
                userName: userName,
                userEmail: userEmail,
                roleColor: roleColor,
              ),
              const SizedBox(height: 30),

              // ── Academic Info ──
              _AcademicInfoCard(),
              const SizedBox(height: 30),

              // ── Quick Actions ──
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Account Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 15),
              ActionTile(
                icon: Icons.lock_reset,
                title: 'Reset Password',
                subtitle: 'Get a recovery link in your email',
                onTap: _resetPassword,
              ),
              ActionTile(
                icon: Icons.logout,
                title: 'Logout',
                subtitle: 'Sign out of your account',
                color: AppColors.error,
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String initial;
  final String userName;
  final String userEmail;
  final Color roleColor;

  const _ProfileCard({
    required this.initial,
    required this.userName,
    required this.userEmail,
    required this.roleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            userEmail,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
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
