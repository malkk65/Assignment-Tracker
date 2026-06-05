import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/user_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 7));
    if (!mounted) return;

    // Check if user is already logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // User is logged in — load their role from Firestore, then go home
      await UserService.loadUserData(user.uid);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      // No user — go to onboarding
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0F2F1), Color(0xFFFFFFFF), Color(0xFFF5F5F5)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),
            // App Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: Colors.white,
                size: 60,
              ),
            ),
            const SizedBox(height: 30),
            // Title
            const Text(
              'Assignment\nTracker',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Simplify Your Studies',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(flex: 2),
            // Loading bar
            SizedBox(
              width: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'ORGANIZING ACADEMIC WORKFLOW',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(flex: 2),
            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(height: 1, width: 30, color: AppColors.border),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'ACADEMIC EDITORIAL',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Container(height: 1, width: 30, color: AppColors.border),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
