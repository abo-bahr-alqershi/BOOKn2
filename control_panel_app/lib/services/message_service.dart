import 'package:flutter/material.dart';
import 'dart:math' as math;

/// MessageService provides a global way to display user-facing messages
/// (errors, warnings, info, success) via a single ScaffoldMessenger.
class MessageService {
  MessageService._();

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static const Duration _defaultDuration = Duration(seconds: 4);

  static String? _lastMessage;
  static DateTime? _lastShownAt;

  static bool _shouldSuppress(String message) {
    final now = DateTime.now();
    if (_lastMessage == message && _lastShownAt != null) {
      final since = now.difference(_lastShownAt!);
      if (since.inMilliseconds < 1200) return true; // throttle duplicates
    }
    _lastMessage = message;
    _lastShownAt = now;
    return false;
  }

  static void _showSnackBar(
    String message, {
    Color? backgroundColor,
    SnackBarAction? action,
    Duration? duration,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    EdgeInsetsGeometry margin = const EdgeInsets.all(12),
  }) {
    debugPrint('📱 [MessageService._showSnackBar] Called with: "$message"');
    
    if (message.trim().isEmpty) {
      debugPrint('⚠️ [MessageService._showSnackBar] Message is empty, returning');
      return;
    }
    
    if (_shouldSuppress(message)) {
      debugPrint('⚠️ [MessageService._showSnackBar] Message suppressed (duplicate)');
      return;
    }

    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) {
      debugPrint(
          'MessageService: ScaffoldMessenger not ready. Message: $message');
      return;
    }

    // Calculate duration based on message length
    Duration calculatedDuration = duration ?? _defaultDuration;
    if (duration == null) {
      // For longer messages, show for longer
      final lines = message.split('\n').length;
      final charCount = message.length;

      if (lines > 1 || charCount > 80) {
        final seconds = 4 + (lines * 2) + (charCount ~/ 100);
        final clampedSeconds = math.max(4, math.min(12, seconds));
        calculatedDuration = Duration(seconds: clampedSeconds);
      }
    }

    messenger.clearSnackBars();
    
    debugPrint('✅ [MessageService._showSnackBar] Showing SnackBar with duration: ${calculatedDuration.inSeconds}s');
    
    messenger.showSnackBar(
      SnackBar(
        content: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Text(
            message,
            textAlign: TextAlign.start,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: behavior,
        margin: margin,
        duration: calculatedDuration,
        action: action,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
    
    debugPrint('✅ [MessageService._showSnackBar] SnackBar shown successfully');
  }

  static void showError(String message) {
    debugPrint('🔴 [MessageService.showError] Called with message: "$message"');
    _showSnackBar(
      message,
      backgroundColor: const Color(0xFFDC2626),
    );
  }

  static void showSuccess(String message) {
    _showSnackBar(
      message,
      backgroundColor: const Color(0xFF059669),
    );
  }

  static void showInfo(String message) {
    _showSnackBar(
      message,
      backgroundColor: const Color(0xFF0284C7),
    );
  }

  static void showWarning(String message) {
    _showSnackBar(
      message,
      backgroundColor: const Color(0xFFF59E0B),
    );
  }
}
