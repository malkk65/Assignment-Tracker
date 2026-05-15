import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/chat_service.dart';
import '../widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String groupId;
  final String chatTitle;

  const ChatScreen({
    super.key,
    required this.groupId,
    required this.chatTitle,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void sendMessage() async {
    if (controller.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final text = controller.text.trim();
    controller.clear();

    await ChatService.sendMessage(
      groupId: widget.groupId,
      text: text,
      senderId: user.uid,
      senderName: user.displayName ?? 'Anonymous',
    );

    _scrollToBottom();
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '';
    final date = ts.toDate();
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'TODAY';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'YESTERDAY';
    } else {
      const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF006D77)),
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chatTitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF006D77),
              ),
            ),
            const Text(
              "ACTIVE NOW",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFFA0AEC0),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFF006D77)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: ChatService.getMessagesStream(widget.groupId),
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
                        Icon(Icons.chat_bubble_outline, size: 56, color: Color(0xFFA0AEC0)),
                        SizedBox(height: 12),
                        Text(
                          'No messages yet',
                          style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(color: Color(0xFFA0AEC0), fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                // Group messages by date for date headers
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 20, bottom: 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == currentUserId;
                    final senderName = data['senderName'] ?? 'Unknown';
                    final text = data['text'] ?? '';
                    final ts = data['timestamp'] as Timestamp?;
                    final time = _formatTimestamp(ts);

                    // Check if we need to show a date header
                    Widget? dateHeader;
                    if (ts != null) {
                      final currentDate = ts.toDate();
                      bool showHeader = false;

                      if (index == 0) {
                        showHeader = true;
                      } else {
                        final prevData = docs[index - 1].data() as Map<String, dynamic>;
                        final prevTs = prevData['timestamp'] as Timestamp?;
                        if (prevTs != null) {
                          final prevDate = prevTs.toDate();
                          if (currentDate.day != prevDate.day ||
                              currentDate.month != prevDate.month ||
                              currentDate.year != prevDate.year) {
                            showHeader = true;
                          }
                        }
                      }

                      if (showHeader) {
                        dateHeader = Center(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _formatDateHeader(currentDate),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF718096),
                              ),
                            ),
                          ),
                        );
                      }
                    }

                    return Column(
                      children: [
                        if (dateHeader != null) dateHeader,
                        ChatBubble(
                          text: text,
                          isMe: isMe,
                          senderName: isMe ? null : senderName,
                          time: time,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  const Icon(Icons.emoji_emotions_outlined, color: Color(0xFF718096)),
                  const SizedBox(width: 12),
                  const Icon(Icons.attach_file, color: Color(0xFF718096)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => sendMessage(),
                      decoration: const InputDecoration(
                        hintText: "Type your message...",
                        hintStyle: TextStyle(color: Color(0xFFA0AEC0)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF006D77),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}