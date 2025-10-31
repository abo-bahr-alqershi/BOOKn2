import 'package:flutter/foundation.dart';

class MessageService {
  static void showError(String message) {
    debugPrint('Error: $message');
  }

  static void showSuccess(String message) {
    debugPrint('Success: $message');
  }
}
