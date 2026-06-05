import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../services/notification_service.dart';
import '../../features/notifications/screens/notifications_screen.dart';

/// Data class representing a single floating notification to display.
class _FloatingNotification {
  final String id;
  final String title;
  final String message;
  final String type;

  _FloatingNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
  });
}

/// Displays floating notification banners at the top of the app,
/// sliding in from the top with a smooth animation and auto-dismissing.
///
/// Listens to Firestore for new unread notifications and shows them
/// one at a time as beautiful floating banners.
class FloatingNotificationManager extends StatefulWidget {
  final Widget child;

  const FloatingNotificationManager({
    super.key,
    required this.child,
  });

  @override
  State<FloatingNotificationManager> createState() =>
      _FloatingNotificationManagerState();
}

class _FloatingNotificationManagerState
    extends State<FloatingNotificationManager> {
  StreamSubscription<QuerySnapshot>? _subscription;

  /// IDs of notifications we've already shown as floating banners this session.
  final Set<String> _shownIds = {};

  /// Queue of notifications waiting to be displayed.
  final List<_FloatingNotification> _queue = [];

  /// Whether a banner is currently being displayed.
  bool _isShowingBanner = false;

  @override
  void initState() {
    super.initState();
    _listenForNotifications();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _listenForNotifications() {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    _subscription = NotificationService.getNotificationsStream().listen(
      (snapshot) {
        for (final doc in snapshot.docs) {
          // Skip already-shown banners
          if (_shownIds.contains(doc.id)) continue;

          final data = doc.data() as Map<String, dynamic>;
          final readBy = List<String>.from(data['readBy'] ?? []);
          final createdAt = data['createdAt'] as Timestamp?;

          // Only show for unread notifications
          if (readBy.contains(userId)) {
            _shownIds.add(doc.id); // Mark read ones so we don't show later
            continue;
          }

          // Only show notifications created within the last 30 seconds
          // to avoid showing old ones on app launch
          if (createdAt != null) {
            final now = DateTime.now();
            final created = createdAt.toDate();
            if (now.difference(created).inSeconds > 30) {
              _shownIds.add(doc.id);
              continue;
            }
          } else {
            // No timestamp yet (server timestamp pending), skip for now
            continue;
          }

          _shownIds.add(doc.id);

          final notification = _FloatingNotification(
            id: doc.id,
            title: data['title'] ?? '',
            message: data['message'] ?? '',
            type: data['type'] ?? 'system',
          );

          _queue.add(notification);
          _processQueue();
        }
      },
    );
  }

  void _processQueue() {
    if (_isShowingBanner || _queue.isEmpty || !mounted) return;

    _isShowingBanner = true;
    final notification = _queue.removeAt(0);

    _showFloatingBanner(notification);
  }

  void _showFloatingBanner(_FloatingNotification notification) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    final animController = AnimationController(
      vsync: overlay,
      duration: const Duration(milliseconds: 450),
      reverseDuration: const Duration(milliseconds: 350),
    );

    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    void dismiss() async {
      if (!animController.isDismissed) {
        await animController.reverse();
      }
      entry.remove();
      animController.dispose();
      if (mounted) {
        _isShowingBanner = false;
        _processQueue();
      }
    }

    entry = OverlayEntry(
      builder: (context) {
        final topPadding = MediaQuery.of(context).padding.top;
        return Positioned(
          top: topPadding + 70, // Below the app bar
          left: 16,
          right: 16,
          child: SlideTransition(
            position: slideAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: _FloatingBannerCard(
                notification: notification,
                onDismiss: dismiss,
                onTap: () {
                  dismiss();
                  // Navigate to notifications screen
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder:
                          (context, animation, secondaryAnimation) =>
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
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);
    animController.forward();

    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (animController.isCompleted) {
        dismiss();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// ─────────────────────────────────────────────────────────────
// Floating Banner Card — the actual visual notification card
// ─────────────────────────────────────────────────────────────
class _FloatingBannerCard extends StatelessWidget {
  final _FloatingNotification notification;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _FloatingBannerCard({
    required this.notification,
    required this.onDismiss,
    required this.onTap,
  });

  IconData _getIconForType(String type) {
    switch (type) {
      case 'assignment':
        return Icons.assignment_outlined;
      case 'group':
        return Icons.group_add_outlined;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'assignment':
        return AppColors.primary;
      case 'group':
        return const Color(0xFF006D77);
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorForType(notification.type);
    final icon = _getIconForType(notification.type);

    return Material(
      color: Colors.transparent,
      child: Dismissible(
        key: ValueKey(notification.id),
        direction: DismissDirection.horizontal,
        onDismissed: (_) => onDismiss(),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // Glassmorphism-inspired card
              color: AppColors.card.withValues(alpha: 0.97),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withValues(alpha: 0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // ── Icon with gradient background ──
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.15),
                        color.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: color.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),

                // ── Text content ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        notification.message,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // ── Close button ──
                GestureDetector(
                  onTap: onDismiss,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.scaffold.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
