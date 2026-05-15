import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _groupsCollection = 'chat_groups';

  /// Returns a stream of all chat groups, ordered by last activity.
  static Stream<QuerySnapshot> getGroupsStream() {
    return _firestore
        .collection(_groupsCollection)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  /// Creates a new chat group (admin only).
  static Future<void> createGroup({
    required String name,
    String description = '',
  }) async {
    await _firestore.collection(_groupsCollection).add({
      'name': name,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastMessageSender': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'memberCount': 0,
    });
  }

  /// Deletes a chat group and all its messages (admin only).
  static Future<void> deleteGroup(String groupId) async {
    // Delete all messages in the group first
    final messages = await _firestore
        .collection(_groupsCollection)
        .doc(groupId)
        .collection('messages')
        .get();

    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    // Delete the group itself
    batch.delete(_firestore.collection(_groupsCollection).doc(groupId));
    await batch.commit();
  }

  /// Sends a message to a chat group.
  static Future<void> sendMessage({
    required String groupId,
    required String text,
    required String senderId,
    required String senderName,
  }) async {
    final batch = _firestore.batch();

    // Add the message
    final msgRef = _firestore
        .collection(_groupsCollection)
        .doc(groupId)
        .collection('messages')
        .doc();

    batch.set(msgRef, {
      'text': text,
      'senderId': senderId,
      'senderName': senderName,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update the group's last message info
    batch.update(_firestore.collection(_groupsCollection).doc(groupId), {
      'lastMessage': text,
      'lastMessageSender': senderName,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Returns a stream of messages for a specific group, ordered by time.
  static Stream<QuerySnapshot> getMessagesStream(String groupId) {
    return _firestore
        .collection(_groupsCollection)
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
}
