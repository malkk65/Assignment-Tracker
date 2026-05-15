import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/widgets/premium_app_bar.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/assignments/screens/assignment_list_screen.dart';
import '../features/chat/screens/chat_list_screen.dart';
import '../features/profile/screens/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  List<Widget> get _pages {
    return const [
      DashboardScreen(),
      AssignmentListScreen(),
      ChatListScreen(),
      ProfileScreen(),
    ];
  }

  List<NavigationDestination> get _destinations {
    return const [
      NavigationDestination(
        icon: Icon(Icons.grid_view_rounded),
        selectedIcon: Icon(Icons.grid_view_rounded, color: AppColors.primary),
        label: AppStrings.dashboard,
      ),
      NavigationDestination(
        icon: Icon(Icons.assignment_outlined),
        selectedIcon: Icon(Icons.assignment, color: AppColors.primary),
        label: AppStrings.assignments,
      ),
      NavigationDestination(
        icon: Icon(Icons.chat_bubble_outline),
        selectedIcon: Icon(Icons.chat_bubble, color: AppColors.primary),
        label: AppStrings.chat,
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person, color: AppColors.primary),
        label: AppStrings.profile,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Guard against index out of bounds when role changes
    if (_currentIndex >= _pages.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      // App Bar
      appBar: PremiumAppBar(
        onAvatarTap: () {
          // Navigate to profile tab (index 3)
          setState(() {
            _currentIndex = 3;
          });
        },
      ),
      // ── Page Body with fade transition ──
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _pages[_currentIndex],
        ),
      ),
      // Navigation
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: NavigationBar(
            height: 70,
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            backgroundColor: AppColors.card,
            indicatorColor: AppColors.primary.withValues(alpha: 0.1),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: _destinations,
          ),
        ),
      ),
    );
  }
}