import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

  static Future<T?>? navigateTo<T>(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushNamed<T>(routeName, arguments: arguments);
  }

  static void goToLogin() {
    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      context.go('/login');
      return;
    }
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
  }
}
