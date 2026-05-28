import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Add import for kDebugMode
import '../models/message_model.dart';
import '../models/conversation_model.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class MessagesProvider with ChangeNotifier {
  List<ConversationModel> _conversations = [];
  bool _isLoadingConversations = false;
  bool _isSending = false;
  String? _error;
  final Map<String, List<MessageModel>> _cachedMessages = {};

  List<ConversationModel> get conversations => _conversations;
  bool get isLoadingConversations => _isLoadingConversations;
  bool get isSending => _isSending;
  String? get error => _error;

  String _conversationKey(int adId, int otherUserId) => '$adId-$otherUserId';

  List<MessageModel> messagesFor(int adId, int otherUserId) {
    return _cachedMessages[_conversationKey(adId, otherUserId)] ?? [];
  }

  Future<void> fetchConversations({int? userId}) async {
    _isLoadingConversations = true;
    _error = null;
    notifyListeners();

    try {
      String url = '${ApiConfig.messages}/conversations';
      if (userId != null) {
        url += '?user_id=$userId';
      }
      
      final response = await ApiService.get(url);
      if (kDebugMode) {
        print('Messages response: $response');
      }
      if (response['success'] == true) {
        _conversations = (response['conversations'] as List)
            .map((json) => ConversationModel.fromJson(json))
            .toList();
        if (kDebugMode) {
          print('Parsed ${_conversations.length} conversations');
        }
      }
      _isLoadingConversations = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  Future<void> fetchMessages({
    required int adId,
    required int otherUserId,
    required int currentUserId,
  }) async {
    final key = _conversationKey(adId, otherUserId);
    try {
      final response = await ApiService.get(
        '${ApiConfig.messages}/conversation/$adId/$otherUserId',
      );
      if (response['success'] == true) {
        final list = (response['messages'] as List)
            .map((json) => MessageModel.fromJson(json, currentUserId))
            .toList();
        _cachedMessages[key] = list;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> sendMessage({
    required int adId,
    required int receiverId,
    required String message,
    required int currentUserId,
  }) async {
    if (message.trim().isEmpty) return false;

    _isSending = true;
    notifyListeners();

    try {
      final response = await ApiService.post(ApiConfig.messages, {
        'ad_id': adId,
        'receiver_id': receiverId,
        'message': message.trim(),
        'user_id': currentUserId,
      });

      _isSending = false;
      notifyListeners();

      if (response['success'] == true) {
        await fetchMessages(
          adId: adId,
          otherUserId: receiverId,
          currentUserId: currentUserId,
        );
        await fetchConversations();
        return true;
      }
    } catch (e) {
      _error = e.toString();
      _isSending = false;
      notifyListeners();
    }

    return false;
  }
}
