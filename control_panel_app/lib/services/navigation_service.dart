import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationService {
  NavigationService._();

  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static void goToLogin() {
    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      context.go('/login');
    }
  }

  static void goToMain() {
    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      context.go('/main');
    }
  }
}
