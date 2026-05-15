import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _getIconForType(String type) {
    switch (type) {
      case 'assignment':
        return Icons.assignment_outlined;
      case 'group':
        return Icons.group_add_outlined;
      default:
        return Icons.notifications;
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
  
    // final notifications = [
    //   {
    //     'title': 'New Assignment',
    //     'message': 'A new assignment for "Software Engineering" was added.',
    //     'time': '2 hours ago',
    //     'isRead': false,
    //   },
    //   {
    //     'title': 'Deadline Approaching',
    //     'message': '"Data Structures Project" is due in 24 hours.',
    //     'time': '5 hours ago',
    //     'isRead': false,
    //   },
    //   {
    //     'title': 'System Update',
    //     'message': 'The app will undergo maintenance tonight at 2 AM.',
    //     'time': '1 day ago',
    //     'isRead': true,
    //   },
    // ];
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () async {
              if (userId.isNotEmpty) {
                await NotificationService.markAllAsRead(userId);
              }
            },
            child: const Text(
              'Read All',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: NotificationService.getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.textHint),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] ?? '';
              final message = data['message'] ?? '';
              final type = data['type'] ?? 'system';
              final readBy = List<String>.from(data['readBy'] ?? []);
              final isRead = readBy.contains(userId);
              final ts = data['createdAt'] as Timestamp?;
              final timeLabel = NotificationService.formatTimeAgo(ts);

              return GestureDetector(
                onTap: () {
                  if (!isRead && userId.isNotEmpty) {
                    NotificationService.markAsRead(doc.id, userId);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isRead
                          ? Colors.transparent
                          : _getColorForType(type).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isRead
                              ? AppColors.scaffold
                              : _getColorForType(type).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIconForType(type),
                          color: isRead ? AppColors.textHint : _getColorForType(type),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                color: AppColors.textPrimary,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              timeLabel,
                              style: const TextStyle(
                                color: AppColors.textHint,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            color: _getColorForType(type),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
