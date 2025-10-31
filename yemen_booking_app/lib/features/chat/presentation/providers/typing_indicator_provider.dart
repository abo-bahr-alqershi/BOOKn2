import 'dart:async';
import 'package:flutter/foundation.dart';

class TypingIndicatorProvider extends ChangeNotifier {
  final Map<String, Set<String>> _typingUsers = {};
  final Map<String, Timer> _typingTimers = {};
  static const Duration _typingTimeout = Duration(seconds: 5);

  Map<String, Set<String>> get typingUsers => Map.unmodifiable(_typingUsers);

  List<String> getTypingUsersForConversation(String conversationId) {
    return _typingUsers[conversationId]?.toList() ?? [];
  }

  bool isUserTyping(String conversationId, String userId) {
    return _typingUsers[conversationId]?.contains(userId) ?? false;
  }

  void setUserTyping({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) {
    if (isTyping) {
      _addTypingUser(conversationId, userId);
      _resetTypingTimer(conversationId, userId);
    } else {
      _removeTypingUser(conversationId, userId);
      _cancelTypingTimer(conversationId, userId);
    }
  }

  void _addTypingUser(String conversationId, String userId) {
    _typingUsers.putIfAbsent(conversationId, () => {});
    if (_typingUsers[conversationId]!.add(userId)) {
      notifyListeners();
    }
  }

  void _removeTypingUser(String conversationId, String userId) {
    if (_typingUsers[conversationId]?.remove(userId) ?? false) {
      if (_typingUsers[conversationId]!.isEmpty) {
        _typingUsers.remove(conversationId);
      }
      notifyListeners();
    }
  }

  void _resetTypingTimer(String conversationId, String userId) {
    final key = '$conversationId:$userId';
    _cancelTypingTimer(conversationId, userId);
    
    _typingTimers[key] = Timer(_typingTimeout, () {
      _removeTypingUser(conversationId, userId);
      _typingTimers.remove(key);
    });
  }

  void _cancelTypingTimer(String conversationId, String userId) {
    final key = '$conversationId:$userId';
    _typingTimers[key]?.cancel();
    _typingTimers.remove(key);
  }

  void clearTypingUsersForConversation(String conversationId) {
    if (_typingUsers.remove(conversationId) != null) {
      // Cancel all timers for this conversation
      final keysToRemove = <String>[];
      _typingTimers.forEach((key, timer) {
        if (key.startsWith('$conversationId:')) {
          timer.cancel();
          keysToRemove.add(key);
        }
      });
      keysToRemove.forEach(_typingTimers.remove);
      notifyListeners();
    }
  }

  void clearAllTypingUsers() {
    _typingUsers.clear();
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    _typingTimers.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    clearAllTypingUsers();
    super.dispose();
  }
}