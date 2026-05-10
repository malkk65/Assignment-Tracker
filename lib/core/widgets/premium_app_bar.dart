import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../cache/user_cache.dart';
import '../../features/notifications/screens/notifications_screen.dart';

/// A premium, responsive app bar widget inspired by modern SaaS dashboards.
///
/// Features:
/// - Animated brand logo with gradient accent
/// - Notification bell with animated badge
/// - User avatar with role indicator and hover/tap effects
/// - Soft shadow, glassmorphism-lite styling
/// - Responsive layout that adapts to screen width
class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Callback when the user avatar is tapped.
  final VoidCallback onAvatarTap;

  /// The height of the app bar content area.
  static const double _barHeight = 64.0;

  const PremiumAppBar({
    super.key,
    required this.onAvatarTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(_barHeight);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;
    final horizontalPadding = isCompact ? 12.0 : 20.0;

    return Container(
      height: _barHeight + MediaQuery.of(context).padding.top,
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.92),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            children: [
              // ── Brand / Logo ──
              const _BrandSection(),

              const Spacer(),

              // ── Right Actions: Notification + Avatar ──
              _NotificationButton(isCompact: isCompact),
              SizedBox(width: isCompact ? 6 : 14),
              _UserAvatarButton(
                onTap: onAvatarTap,
                isCompact: isCompact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Brand Section — logo icon + app name with subtle animation
// ─────────────────────────────────────────────────────────────
class _BrandSection extends StatefulWidget {
  const _BrandSection();

  @override
  State<_BrandSection> createState() => _BrandSectionState();
}

class _BrandSectionState extends State<_BrandSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    // Entrance animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gradient-backed logo icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          // App title
          const Text(
            'Academic Editorial',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Notification Bell — with animated badge pulse
// ─────────────────────────────────────────────────────────────
class _NotificationButton extends StatefulWidget {
  final bool isCompact;

  const _NotificationButton({required this.isCompact});

  @override
  State<_NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<_NotificationButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const NotificationsScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.05),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.scaffold.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.border.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedScale(
                scale: _isHovered ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: _isHovered
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 22,
                ),
              ),
              // Animated notification dot
              Positioned(
                right: 9,
                top: 9,
                child: ScaleTransition(
                  scale: _pulseAnim,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.card,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B6B).withValues(alpha: 0.4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// User Avatar Button — shows initial, role badge, hover effects
// ─────────────────────────────────────────────────────────────
class _UserAvatarButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isCompact;

  const _UserAvatarButton({
    required this.onTap,
    required this.isCompact,
  });

  @override
  State<_UserAvatarButton> createState() => _UserAvatarButtonState();
}

class _UserAvatarButtonState extends State<_UserAvatarButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late final AnimationController _entranceController;
  late final Animation<double> _entranceAnim;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entranceAnim = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutBack,
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  String _getUserInitial() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName![0].toUpperCase();
    }
    if (user?.email != null && user!.email!.isNotEmpty) {
      return user.email![0].toUpperCase();
    }
    return 'S';
  }

  String _getUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    if (user?.email != null && user!.email!.isNotEmpty) {
      return user.email!.split('@')[0];
    }
    return 'Student';
  }

  @override
  Widget build(BuildContext context) {
    final initial = _getUserInitial();
    final userName = _getUserName();
    final isAdmin = UserCache.isAdmin;
    final screenWidth = MediaQuery.of(context).size.width;
    final showName = screenWidth > 420 && !widget.isCompact;

    return ScaleTransition(
      scale: _entranceAnim,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(
              horizontal: showName ? 10 : 0,
              vertical: 0,
            ),
            decoration: BoxDecoration(
              color: _isHovered
                  ? AppColors.primary.withValues(alpha: 0.06)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar circle with gradient ring
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isHovered
                          ? [AppColors.primary, AppColors.primaryLight]
                          : [
                              AppColors.primary.withValues(alpha: 0.3),
                              AppColors.primaryLight.withValues(alpha: 0.3),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isAdmin
                          ? AppColors.primary
                          : AppColors.primaryLight,
                      border: Border.all(
                        color: AppColors.card,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),

                // Name + Role (shown on wider screens)
                if (showName) ...[
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 100),
                        child: Text(
                          userName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isAdmin
                                  ? AppColors.primary
                                  : AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isAdmin ? 'Admin' : 'Student',
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 2),
                  AnimatedRotation(
                    turns: _isHovered ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textHint,
                      size: 18,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
