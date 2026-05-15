import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'navigation/main_shell.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Disable Firestore local persistence to prevent Android ANR (freezes)
  // caused by corrupted cache or gRPC connection issues.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );

  await Supabase.initialize(
    url: 'https://ixivfixzemimtnuczdoa.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml4aXZmaXh6ZW1pbXRudWN6ZG9hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2MjAyNDIsImV4cCI6MjA5NDE5NjI0Mn0.1ovuiJf3ee0-EkKtOgivekntXgEHB_LV21EYgSVf31k',
  );

  runApp(const AssignmentTrackerApp());
}

class AssignmentTrackerApp extends StatelessWidget {
  const AssignmentTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const MainShell(),
      },
    );
  }
}
