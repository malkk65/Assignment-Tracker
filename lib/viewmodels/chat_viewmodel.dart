import 'package:flutter/material.dart';
import '../models/message_model.dart';

class ChatViewModel extends ChangeNotifier {
  List<MessageModel> _messages = [];
  bool _isLoading = false;

  // Getters
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;

  // Fetch messages
  Future<void> fetchMessages(String chatRoomId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Call API service
      await Future.delayed(const Duration(seconds: 1));
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send message
  Future<void> sendMessage(MessageModel message) async {
    // TODO: Call API service
    _messages.add(message);
    notifyListeners();
  }
}
