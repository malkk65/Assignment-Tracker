import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'notifications';

  /// Creates a notification visible to all students.
  static Future<void> createNotification({
    required String title,
    required String message,
    required String type, // 'assignment', 'group', 'system'
  }) async {
    await _firestore.collection(_collection).add({
      'title': title,
      'message': message,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': <String>[], // Track which users have read this
    });
  }

  /// Returns a stream of all notifications, newest first.
  static Stream<QuerySnapshot> getNotificationsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Marks a notification as read by a specific user.
  static Future<void> markAsRead(String notificationId, String userId) async {
    await _firestore.collection(_collection).doc(notificationId).update({
      'readBy': FieldValue.arrayUnion([userId]),
    });
  }

  /// Marks all notifications as read by a specific user.
  static Future<void> markAllAsRead(String userId) async {
    final snapshot = await _firestore.collection(_collection).get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      final readBy = List<String>.from(doc.data()['readBy'] ?? []);
      if (!readBy.contains(userId)) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([userId]),
        });
      }
    }
    await batch.commit();
  }

  /// Returns a stream of the count of unread notifications for a user.
  static Stream<int> getUnreadCountStream(String userId) {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) {
      int count = 0;
      for (final doc in snapshot.docs) {
        final readBy = List<String>.from(doc.data()['readBy'] ?? []);
        if (!readBy.contains(userId)) count++;
      }
      return count;
    });
  }

  /// Formats a Firestore timestamp into a human-readable relative time.
  static String formatTimeAgo(Timestamp? ts) {
    if (ts == null) return '';
    final now = DateTime.now();
    final date = ts.toDate();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
