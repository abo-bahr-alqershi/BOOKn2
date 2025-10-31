import 'package:flutter/material.dart';

class EmojiProvider extends ChangeNotifier {
  bool _isEmojiVisible = false;

  bool get isEmojiVisible => _isEmojiVisible;

  void toggleEmojiKeyboard() {
    _isEmojiVisible = !_isEmojiVisible;
    notifyListeners();
  }

  void hideEmojiKeyboard() {
    if (_isEmojiVisible) {
      _isEmojiVisible = false;
      notifyListeners();
    }
  }

  void showEmojiKeyboard() {
    if (!_isEmojiVisible) {
      _isEmojiVisible = true;
      notifyListeners();
    }
  }
}
