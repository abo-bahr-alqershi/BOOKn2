import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yemen_booking_app/core/utils/timezone_helper.dart';
import 'app.dart';
import 'injection_container.dart' as di;
import 'core/bloc/app_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/connectivity_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Register a top-level background message handler for Android/iOS
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await Hive.initFlutter();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize services
  await di.init();

  // Initialize connectivity service
  await ConnectivityService().initialize();
  // Initialize notifications (register FCM token and handlers)
  await di.sl<NotificationService>().initialize();

  // Initialize AppBloc after dependency injection
  AppBloc.initialize();
  AppBloc.initializeEvents();

  // Services are initialized via dependency injection
  // await LocalStorageService.init();
  // await NotificationService.init();
  // await CrashReportingService.init();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  // تهيئة timezone
  await TimezoneHelper.initialize();
  runApp(const YemenBookingApp());
}

// Top-level background message handler (required by firebase_messaging)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}
