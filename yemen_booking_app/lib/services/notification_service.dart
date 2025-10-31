import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../core/network/api_client.dart';
import 'local_storage_service.dart';
import '../features/auth/data/datasources/auth_local_datasource.dart';
import 'package:yemen_booking_app/services/in_app_notification_service.dart';
import 'package:yemen_booking_app/services/navigation_service.dart';
import 'package:go_router/go_router.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final ApiClient? _apiClient;
  final LocalStorageService? _localStorage;
  final AuthLocalDataSource? _authLocalDataSource;

  NotificationService({
    ApiClient? apiClient,
    LocalStorageService? localStorage,
    AuthLocalDataSource? authLocalDataSource,
  })  : _apiClient = apiClient,
        _localStorage = localStorage,
        _authLocalDataSource = authLocalDataSource;

  // Initialize notification service
  Future<void> initialize() async {
    // Request permission
    await _requestPermission();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Configure Firebase messaging
    await _configureFirebaseMessaging();

    // Get and register FCM token
    await _registerFcmToken();

    // Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);
  }

  // Request notification permission
  Future<void> _requestPermission() async {
    // Android 13+ requires runtime POST_NOTIFICATIONS permission
    if (Platform.isAndroid) {
      final current = await Permission.notification.status;
      if (!current.isGranted) {
        final result = await Permission.notification.request();
        debugPrint('Android notification permission result: $result');
      }
    }

    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    debugPrint(
        'Notification permission status: ${settings.authorizationStatus}');
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    // Ensure the Android channel exists so push notifications render reliably
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // Android: create notification channels up front
    const androidChannel = AndroidNotificationChannel(
      'yemen_booking_channel',
      'Yemen Booking Notifications',
      description: 'إشعارات تطبيق حجوزات اليمن',
      importance: Importance.high,
    );
    const androidScheduledChannel = AndroidNotificationChannel(
      'yemen_booking_scheduled',
      'Yemen Booking Scheduled',
      description: 'إشعارات مجدولة لتطبيق حجوزات اليمن',
      importance: Importance.high,
    );
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(androidChannel);
    await androidPlugin?.createNotificationChannel(androidScheduledChannel);
  }

  // Configure Firebase messaging
  Future<void> _configureFirebaseMessaging() async {
    // Suppress OS banners/sounds while foreground; we'll show our own in-app dialog
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    // Foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Message opened app handler
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was opened by notification
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  // Register FCM token with backend
  Future<void> _registerFcmToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('FCM token: $token');
        await _sendTokenToServer(token);
        await _localStorage?.saveFcmToken(token);
        await _subscribeToDefaultTopics();
      }
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
    }
  }

  // Subscribe to default topics: user_{id}, role_*; avoid 'all' for admin/staff builds
  Future<void> _subscribeToDefaultTopics() async {
    try {
      final user = await _authLocalDataSource?.getCachedUser();
      if (user != null) {
        final String userId = user.userId;
        if (userId.isNotEmpty) {
          await _firebaseMessaging.subscribeToTopic('user_$userId');
        }
        final List<String> roles =
            (user.roles).map((e) => e.toString()).toList();
        final uniqueRoles = roles
            .where((r) => r.trim().isNotEmpty)
            .map((r) => _normalizeRole(r))
            .toSet()
            .toList();
        for (final role in uniqueRoles) {
          await _firebaseMessaging.subscribeToTopic('role_$role');
        }
      }
    } catch (e) {
      debugPrint('Error subscribing to default topics: $e');
    }
  }

  // Unsubscribe from default topics: user_{id}, role_*
  Future<void> _unsubscribeFromDefaultTopics() async {
    try {
      final user = await _authLocalDataSource?.getCachedUser();
      if (user != null) {
        final String userId = user.userId;
        if (userId.isNotEmpty) {
          await _firebaseMessaging.unsubscribeFromTopic('user_$userId');
        }
        final List<String> roles =
            (user.roles).map((e) => e.toString()).toList();
        final uniqueRoles = roles
            .where((r) => r.trim().isNotEmpty)
            .map((r) => _normalizeRole(r))
            .toSet()
            .toList();
        for (final role in uniqueRoles) {
          await _firebaseMessaging.unsubscribeFromTopic('role_$role');
        }
      }
    } catch (e) {
      debugPrint('Error unsubscribing from default topics: $e');
    }
  }

  String _normalizeRole(String role) {
    final r = role.trim();
    switch (r.toLowerCase()) {
      case 'client':
      case 'customer':
        return 'client';
      case 'superadmin':
      case 'super_admin':
        return 'admin';
      case 'staff':
        return 'staff';
      case 'guest':
        return 'guest';
      default:
        return r.toLowerCase();
    }
  }

  // Send token to server
  Future<void> _sendTokenToServer(String token) async {
    if (_apiClient == null || _authLocalDataSource == null) return;

    try {
      final user = await _authLocalDataSource!.getCachedUser();
      if (user == null) return;

      final deviceType = Platform.isIOS ? 'iOS' : 'Android';

      await _apiClient!.post(
        '/api/fcm/register',
        data: {
          'userId': user.userId,
          'token': token,
          'deviceType': deviceType,
        },
      );
    } catch (e) {
      debugPrint('Error sending FCM token to server: $e');
    }
  }

  // Handle token refresh
  Future<void> _onTokenRefresh(String token) async {
    debugPrint('FCM token refreshed: $token');
    await _sendTokenToServer(token);
    await _localStorage?.saveFcmToken(token);
    await _subscribeToDefaultTopics();
  }

  // Unregister FCM token
  Future<void> unregisterFcmToken() async {
    if (_apiClient == null || _authLocalDataSource == null) return;

    try {
      final user = await _authLocalDataSource!.getCachedUser();
      if (user == null) return;
      final token = await _firebaseMessaging.getToken();

      await _apiClient!.post(
        '/api/fcm/unregister',
        data: {
          'userId': user.userId,
          if (token != null) 'token': token,
        },
      );

      await _unsubscribeFromDefaultTopics();
      await _firebaseMessaging.deleteToken();
    } catch (e) {
      debugPrint('Error unregistering FCM token: $e');
    }
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Foreground message received: ${message.messageId}');
    final data = message.data;
    final type = (data['type'] ?? data['event_type'] ?? '').toString();

    // Silent types (chat updates etc.)
    if (type == 'new_message' ||
        type == 'chat.new_message' ||
        type == 'conversation_created' ||
        type == 'reaction_added' ||
        type == 'reaction_removed' ||
        type == 'message_status_updated' ||
        (data['silent']?.toString() == 'true')) {
      return;
    }

    final notification = message.notification;
    String title = (notification?.title ?? data['title'] ?? '').toString().trim();
    String body = (notification?.body ?? data['body'] ?? data['message'] ?? '').toString().trim();

    // Fallbacks
    final fallbackType = (data['type'] ?? data['event_type'] ?? '').toString();
    final id = (data['id'] ?? data['booking_id'] ?? data['conversation_id'] ?? '').toString();
    if (title.isEmpty) {
      switch (fallbackType) {
        case 'booking':
          title = 'تحديث جديد على الحجز';
          break;
        case 'chat':
        case 'new_message':
          title = 'رسالة جديدة';
          break;
        case 'conversation_created':
          title = 'تم إنشاء محادثة جديدة';
          break;
        default:
          title = 'إشعار جديد';
      }
    }
    if (body.isEmpty) {
      switch (fallbackType) {
        case 'booking':
          body = id.isNotEmpty ? 'تم تحديث الحجز رقم $id' : 'اطّلع على تفاصيل التحديث.';
          break;
        case 'chat':
        case 'new_message':
          body = 'لديك رسالة جديدة. اضغط فتح للعرض.';
          break;
        case 'conversation_created':
          body = 'تم إنشاء محادثة جديدة. اضغط فتح للانتقال.';
          break;
        default:
          body = 'لديك إشعار جديد. اضغط فتح للعرض.';
      }
    }

    // Derive priority
    final rawPriority = (data['priority'] ?? data['severity'] ?? data['level'] ?? data['importance'] ?? data['urgency'] ?? '').toString();
    String derivedPriority = rawPriority.trim().toLowerCase();
    String normalizePriority(String v) {
      final s = v.trim().toLowerCase();
      if (s.isEmpty) return s;
      if (RegExp(r'^[0-9]+$').hasMatch(s)) {
        final n = int.tryParse(s) ?? 0;
        if (n == 1 || n == 2) return 'high';
        if (n == 3) return 'medium';
        if (n == 4) return 'low';
        if (n >= 5) return 'info';
      }
      if (['critical','crit','urgent','high','danger','severe','fatal','error','fail'].contains(s)) return 'high';
      if (['warn','warning','medium'].contains(s)) return 'medium';
      if (['success','ok','done','approved','complete','completed','paid'].contains(s)) return 'success';
      if (['low','minor','info','default','normal'].contains(s)) return 'info';
      if (['عاجل','طارئ','خطر','حرج','عالية','عالي','مرتفع','خطير','خطأ','فشل','إلغاء','ملغي','رفض','مرفوض'].contains(s)) return 'high';
      if (['تحذير','متوسط','معلق','انتظار','قيد','قيد الانتظار','قيد المعالجة','تحذيري'].contains(s)) return 'medium';
      if (['نجاح','ناجح','مؤكد','تم','تم الدفع','مدفوع','مكتمل','اكتمل','موافق','تمت الموافقة'].contains(s)) return 'success';
      if (['منخفض','منخفضة','عادي','عادية','افتراضي','معلومات'].contains(s)) return 'info';
      return s;
    }
    if (derivedPriority.isNotEmpty) {
      derivedPriority = normalizePriority(derivedPriority);
    }
    if (derivedPriority.isEmpty || derivedPriority == 'info') {
      final contentToAnalyze = '${title.toLowerCase()} ${body.toLowerCase()}';
      bool containsAny(List<String> keys) => keys.any((k) => contentToAnalyze.contains(k));
      if (containsAny(['cancelled','canceled','failed','error','rejected','declined','urgent','critical','expired','overdue','blocked','suspended','terminated','denied','ملغي','إلغاء','فشل','خطأ','رفض','عاجل','طارئ','حرج'])) {
        derivedPriority = 'high';
      } else if (containsAny(['confirmed','approved','successful','completed','paid','accepted','activated','verified','processed','delivered','received','مؤكد','موافق','ناجح','مكتمل','مدفوع','تم الدفع','تم التحقق','تم التسليم','تم الاستلام'])) {
        derivedPriority = 'success';
      } else if (containsAny(['pending','waiting','processing','reminder','attention','review','update required','expiring soon','action needed','incomplete','معلق','قيد الانتظار','قيد المعالجة','تذكير','انتباه','مراجعة','يتطلب تحديث','ينتهي قريب','يتطلب إجراء','غير مكتمل'])) {
        derivedPriority = 'medium';
      } else {
        derivedPriority = 'info';
      }
    }

    await InAppNotificationService.showNotificationDialog(
      title: title,
      body: body,
      priority: derivedPriority,
      onOpen: () {
        try {
          _navigateToScreen(data, preferPush: true);
        } catch (e) {
          debugPrint('Navigation from in-app dialog failed: $e');
        }
      },
    );
  }

  // Handle background messages (static function required)
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('Background message received: ${message.messageId}');
  }

  // Handle notification tap when app is opened
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.messageId}');
    _navigateToScreen(message.data);
  }

  // Handle local notification tap
  void _handleNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      final data = json.decode(response.payload!);
      _navigateToScreen(data);
    }
  }

  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'yemen_booking_channel',
      'Yemen Booking Notifications',
      channelDescription: 'إشعارات تطبيق حجوزات اليمن',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: json.encode(message.data),
    );
  }

  // Navigate to appropriate screen based on notification data
  void _navigateToScreen(Map<String, dynamic> data, {bool preferPush = false}) {
    final type = data['type'];
    final id = data['id'] ?? data['conversation_id'];
    final context = NavigationService.rootNavigatorKey.currentContext;
    if (context == null) {
      debugPrint('Navigation context unavailable');
      return;
    }

    try {
      switch (type) {
        case 'booking':
          if (id != null && id.toString().isNotEmpty) {
            preferPush
                ? context.push('/booking/${id.toString()}')
                : context.go('/booking/${id.toString()}');
            return;
          }
          preferPush ? context.push('/main') : context.go('/main');
          return;
        case 'property':
          if (id != null && id.toString().isNotEmpty) {
            preferPush
                ? context.push('/property/${id.toString()}')
                : context.go('/property/${id.toString()}');
            return;
          }
          preferPush ? context.push('/search') : context.go('/search');
          return;
        case 'chat':
        case 'new_message':
        case 'conversation_created':
          if (id != null && id.toString().isNotEmpty) {
            preferPush
                ? context.push('/chat/${id.toString()}')
                : context.go('/chat/${id.toString()}');
            return;
          }
          preferPush ? context.push('/conversations') : context.go('/conversations');
          return;
        default:
          preferPush ? context.push('/main') : context.go('/main');
          return;
      }
    } catch (e) {
      debugPrint('Navigation failed: $e');
    }
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  // Open notification settings
  Future<void> openNotificationSettings() async {
    await _firebaseMessaging.requestPermission();
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }

  // Cancel notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Schedule notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    Map<String, dynamic>? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'yemen_booking_scheduled',
      'Yemen Booking Scheduled',
      channelDescription: 'إشعارات مجدولة لتطبيق حجوزات اليمن',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Convert DateTime to TZDateTime
    final tz.TZDateTime tzScheduledDate =
        tz.TZDateTime.from(scheduledDate, tz.local);

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload != null ? json.encode(payload) : null,
    );
  }

  // Get FCM token
  Future<String?> getFcmToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}
