import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const AssignmentTrackerApp());
}

class AssignmentTrackerApp extends StatelessWidget {
  const AssignmentTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Assignment Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
