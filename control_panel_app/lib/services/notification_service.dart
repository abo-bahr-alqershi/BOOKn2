import 'dart:convert';
import 'dart:io';
import 'package:bookn_cp_app/features/chat/domain/entities/message.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../core/network/api_client.dart';
import 'local_storage_service.dart';
import '../features/auth/data/datasources/auth_local_datasource.dart';
import 'package:bookn_cp_app/injection_container.dart' as di;
import '../services/websocket_service.dart';
import 'package:bookn_cp_app/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:bookn_cp_app/services/in_app_notification_service.dart';
import 'package:go_router/go_router.dart';
import 'package:bookn_cp_app/services/navigation_service.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final ApiClient? _apiClient;
  final LocalStorageService? _localStorage;
  final AuthLocalDataSource? _authLocalDataSource;

  // Optional sink to dispatch chat events directly without WebSocket
  void Function(WebSocketMessageReceivedEvent event)? _chatEventSink;

  void bindChatEventSink(
      void Function(WebSocketMessageReceivedEvent event) sink) {
    _chatEventSink = sink;
  }

  void unbindChatEventSink() {
    _chatEventSink = null;
  }

  NotificationService({
    ApiClient? apiClient,
    LocalStorageService? localStorage,
    AuthLocalDataSource? authLocalDataSource,
  })  : _apiClient = apiClient,
        _localStorage = localStorage,
        _authLocalDataSource = authLocalDataSource;

  /// Re-register FCM token and subscribe to user/role topics for the current user
  Future<void> refreshUserSubscriptions() async {
    await _registerFcmToken();
  }

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
    // iOS: suppress OS banners/sounds/badges while app is in foreground.
    // We'll show an in-app dialog instead.
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

    // Background message handler registration (Android/iOS)
    FirebaseMessaging.onBackgroundMessage(
        NotificationService._handleBackgroundMessage);
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

  // Subscribe to default topics: user_{id}, role_*; avoid 'all' for admin apps
  Future<void> _subscribeToDefaultTopics() async {
    try {
      // In admin/control panel app, do NOT subscribe to global 'all' to avoid
      // receiving end-user broadcasts on admin/staff devices
      final user = await _authLocalDataSource?.getCachedUser();
      if (user != null) {
        final String userId = user.userId.toString() ?? '';
        if (userId.isNotEmpty) {
          await _firebaseMessaging.subscribeToTopic('user_$userId');
        }
        // roles may come from user.roles and accountRole
        final List<String> roles = [
          ...((user.roles ?? []) as List).map((e) => e.toString()),
          if ((user.accountRole != null &&
              (user.accountRole as String).isNotEmpty)) ...[
            user.accountRole as String
          ]
        ];
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
        final String userId = user.userId.toString() ?? '';
        if (userId.isNotEmpty) {
          await _firebaseMessaging.unsubscribeFromTopic('user_$userId');
        }
        final List<String> roles = [
          ...((user.roles ?? []) as List).map((e) => e.toString()),
          if ((user.accountRole != null &&
              (user.accountRole as String).isNotEmpty)) ...[
            user.accountRole as String
          ]
        ];
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
    // Normalize to 5 canonical roles: Admin, Owner, Client, Staff, Guest
    switch (r.toLowerCase()) {
      case 'admin':
      case 'administrator':
      case 'superadmin':
      case 'super_admin':
        return 'admin';
      case 'owner':
      case 'hotel_owner':
      case 'property_owner':
        return 'owner';
      case 'client':
      case 'customer':
        return 'client';
      case 'staff':
      case 'manager':
      case 'hotel_manager':
      case 'receptionist':
        return 'staff';
      case 'guest':
      case 'visitor':
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

    // إذا كانت رسالة شات داخل التطبيق: لا نعرض إشعارًا، بل نحدّث الـ Bloc مباشرة
    if (type == 'new_message' || type == 'chat.new_message') {
      final conversationId =
          (data['conversation_id'] ?? data['conversationId'] ?? '').toString();
      final messageId =
          (data['message_id'] ?? data['messageId'] ?? '').toString();
      final silent = (data['silent'] ?? '').toString() == 'true';
      if (conversationId.isNotEmpty && messageId.isNotEmpty) {
        try {
          if (_chatEventSink != null) {
            _chatEventSink!.call(WebSocketMessageReceivedEvent(
              MessageEvent(
                  type: MessageEventType.newMessage,
                  conversationId: conversationId,
                  messageId: messageId),
            ));
          } else {
            // Fallback: route via WebSocketService stream bus for ChatBloc
            try {
              di.sl<ChatWebSocketService>().emitNewMessageById(
                    conversationId: conversationId,
                    messageId: messageId,
                  );
            } catch (_) {}
          }
        } catch (e) {
          debugPrint('Dispatch in-app chat update failed: $e');
        }
      }
      if (silent) return; // لا إشعار محلي داخل التطبيق إذا كان صامت
    }

    if (type == 'conversation_created' || type == 'chat.conversation_created') {
      final conversationId =
          (data['conversation_id'] ?? data['conversationId'] ?? '').toString();
      if (conversationId.isNotEmpty) {
        try {
          // Push a conversation update into the bus so ChatBloc updates immediately
          await di.sl<ChatWebSocketService>().emitConversationById(
                conversationId: conversationId,
              );
        } catch (_) {}
      }
      return; // لا إشعار محلي داخل التطبيق
    }

    // تفاعل مُضاف/محذوف: ادفع حدثاً دقيقاً لتحديث فوري دون إعادة جلب كامل
    if (type == 'reaction_added' || type == 'reaction_removed') {
      final conversationId =
          (data['conversation_id'] ?? data['conversationId'] ?? '').toString();
      final messageId =
          (data['message_id'] ?? data['messageId'] ?? '').toString();
      final userId = (data['user_id'] ?? data['userId'] ?? '').toString();
      final reactionType =
          (data['reaction_type'] ?? data['reactionType'] ?? '').toString();
      if (conversationId.isNotEmpty &&
          messageId.isNotEmpty &&
          userId.isNotEmpty &&
          reactionType.isNotEmpty) {
        try {
          final isAdded = type == 'reaction_added';
          if (_chatEventSink != null) {
            _chatEventSink!.call(WebSocketMessageReceivedEvent(
              MessageEvent(
                type: isAdded
                    ? MessageEventType.reactionAdded
                    : MessageEventType.reactionRemoved,
                conversationId: conversationId,
                messageId: messageId,
                reaction: MessageReaction(
                  id: 'temp_${DateTime.now().microsecondsSinceEpoch}',
                  messageId: messageId,
                  userId: userId,
                  reactionType: reactionType,
                ),
              ),
            ));
          } else {
            // Fallback via WebSocketService stream
            try {
              di.sl<ChatWebSocketService>().emitReactionUpdate(
                    conversationId: conversationId,
                    messageId: messageId,
                    userId: userId,
                    reactionType: reactionType,
                    isAdded: isAdded,
                  );
            } catch (_) {}
          }
        } catch (e) {
          debugPrint('Silent reaction update handling failed: $e');
        }
      }
      return; // لا إشعار مرئي للتفاعلات
    }

    // تحديث حالة الرسالة: تحديث صامت للواجهة
    if (type == 'message_status_updated') {
      final conversationId =
          (data['conversation_id'] ?? data['conversationId'] ?? '').toString();
      final messageId =
          (data['message_id'] ?? data['messageId'] ?? '').toString();
      final status = (data['status'] ?? '').toString();
      final readAt = (data['read_at'] ?? '').toString();
      final deliveredAt = (data['delivered_at'] ?? '').toString();
      if (conversationId.isNotEmpty) {
        try {
          if (_chatEventSink != null &&
              messageId.isNotEmpty &&
              status.isNotEmpty) {
            _chatEventSink!.call(WebSocketMessageReceivedEvent(
              MessageEvent(
                  type: MessageEventType.statusUpdated,
                  conversationId: conversationId,
                  messageId: messageId,
                  status: status),
            ));
          } else if (messageId.isNotEmpty && status.isNotEmpty) {
            // Fallback via WebSocketService stream
            try {
              di.sl<ChatWebSocketService>().emitMessageStatusUpdate(
                    conversationId: conversationId,
                    messageId: messageId,
                    status: status,
                  );
            } catch (_) {}
          }
        } catch (e) {
          debugPrint('Silent status update handling failed: $e');
        }
      }
      return; // لا عرض لإشعار مرئي
    }

    // أي رسائل صامتة عامة أخرى: لا تعرض تنبيهًا
    if ((data['silent'] ?? '').toString() == 'true') {
      return;
    }

    // بقية الأنواع: في وضع foreground داخل التطبيق نعرض حوار أنيق داخل التطبيق
    final notification = message.notification;
    String title =
        (notification?.title ?? data['title'] ?? '').toString().trim();
    String body = (notification?.body ?? data['body'] ?? data['message'] ?? '')
        .toString()
        .trim();

    // Fallbacks when payload misses human-readable strings
    final fallbackType = (data['type'] ?? data['event_type'] ?? '').toString();
    final id =
        (data['id'] ?? data['booking_id'] ?? data['conversation_id'] ?? '')
            .toString();
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
          body = id.isNotEmpty
              ? 'تم تحديث الحجز رقم $id'
              : 'اطّلع على تفاصيل التحديث.';
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

    final preview = body.length > 120 ? '${body.substring(0, 120)}…' : body;
    debugPrint(
        'In-app dialog prepared | type=$fallbackType | title="$title" | body="$preview"');

    // Determine visual priority/accent with robust heuristics
    final rawPriority = (data['priority'] ?? data['severity'] ?? data['level'] ?? data['importance'] ?? data['urgency'] ?? '').toString();
    String derivedPriority = rawPriority.trim().toLowerCase();

    // Normalize known synonyms and numeric levels first
    String normalizePriority(String v) {
      final s = v.trim().toLowerCase();
      if (s.isEmpty) return s;
      // Numeric mapping (common patterns): 1/critical, 2/high, 3/medium, 4/low, 5/info
      if (RegExp(r'^[0-9]+$').hasMatch(s)) {
        final n = int.tryParse(s) ?? 0;
        if (n == 1) return 'high';
        if (n == 2) return 'high';
        if (n == 3) return 'medium';
        if (n == 4) return 'low';
        if (n >= 5) return 'info';
      }
      // English synonyms
      if (['critical','crit','urgent','high','danger','severe','fatal','error','fail'].contains(s)) return 'high';
      if (['warn','warning','medium'].contains(s)) return 'medium';
      if (['success','ok','done','approved','complete','completed','paid'].contains(s)) return 'success';
      if (['low','minor','info','default','normal'].contains(s)) return 'info';
      // Arabic synonyms
      if (['عاجل','طارئ','خطر','حرج','عالية','عالي','مرتفع','خطير','خطأ','فشل','إلغاء','ملغي','رفض','مرفوض'].contains(s)) return 'high';
      if (['تحذير','متوسط','معلق','انتظار','قيد','قيد الانتظار','قيد المعالجة','تحذيري'].contains(s)) return 'medium';
      if (['نجاح','ناجح','مؤكد','تم','تم الدفع','مدفوع','مكتمل','اكتمل','موافق','تمت الموافقة'].contains(s)) return 'success';
      if (['منخفض','منخفضة','عادي','عادية','افتراضي','معلومات'].contains(s)) return 'info';
      return s;
    }

    if (derivedPriority.isNotEmpty) {
      derivedPriority = normalizePriority(derivedPriority);
    }

    // If still no priority, analyze title and body content
    if (derivedPriority.isEmpty || derivedPriority == 'info') {
      // Combine title and body for content analysis
      final contentToAnalyze = '${title.toLowerCase()} ${body.toLowerCase()}';
      
      // High priority keywords (errors, cancellations, failures)
      final highPriorityKeywords = [
        // English
        'cancelled', 'canceled', 'failed', 'error', 'rejected', 'declined', 'urgent', 'critical', 
        'expired', 'overdue', 'blocked', 'suspended', 'terminated', 'denied',
        // Arabic
        'ملغي', 'ملغى', 'إلغاء', 'ألغيت', 'تم إلغاء', 'فشل', 'فشلت', 'خطأ', 'رفض', 'مرفوض', 'رفضت',
        'عاجل', 'طارئ', 'حرج', 'منتهي', 'منتهية', 'متأخر', 'محظور', 'معلق', 'منتهى', 'مرفوضة'
      ];
      
      // Success keywords
      final successKeywords = [
        // English  
        'confirmed', 'approved', 'successful', 'completed', 'paid', 'accepted', 'activated',
        'verified', 'processed', 'delivered', 'received',
        // Arabic
        'مؤكد', 'تم تأكيد', 'موافق', 'تمت الموافقة', 'ناجح', 'نجح', 'مكتمل', 'اكتمل', 'مدفوع', 'تم الدفع',
        'مقبول', 'تم قبول', 'مفعل', 'تم تفعيل', 'تم التحقق', 'معالج', 'تم التسليم', 'تم الاستلام'
      ];
      
      // Warning keywords
      final warningKeywords = [
        // English
        'pending', 'waiting', 'processing', 'reminder', 'attention', 'review', 'update required',
        'expiring soon', 'action needed', 'incomplete',
        // Arabic
        'معلق', 'قيد الانتظار', 'قيد المعالجة', 'تذكير', 'انتباه', 'مراجعة', 'يتطلب تحديث',
        'ينتهي قريبا', 'ينتهي قريباً', 'يتطلب إجراء', 'غير مكتمل', 'بانتظار'
      ];
      
      // Check for keywords in content
      bool containsAnyKeyword(List<String> keywords) {
        return keywords.any((keyword) => contentToAnalyze.contains(keyword));
      }
      
      if (containsAnyKeyword(highPriorityKeywords)) {
        derivedPriority = 'high';
      } else if (containsAnyKeyword(successKeywords)) {
        derivedPriority = 'success';
      } else if (containsAnyKeyword(warningKeywords)) {
        derivedPriority = 'medium';
      } else {
        // Original fallback logic based on type
        final status = (data['status'] ?? data['state'] ?? data['result'] ?? '').toString().toLowerCase();
        final eventName = (data['event'] ?? data['event_type'] ?? data['type'] ?? '').toString().toLowerCase();
        final combined = '$fallbackType $status $eventName';

        bool containsAny(List<String> keys) => keys.any((k) => combined.contains(k));

        if (containsAny(['fail', 'error', 'cancel', 'declin', 'reject', 'failed', 'cancelled']) ||
            containsAny(['فشل','إلغاء','ملغي','رفض','مرفوض','خطأ','تعذر'])) {
          derivedPriority = 'high';
        } else if (containsAny(['success', 'confirm', 'complete', 'paid', 'approve', 'approved', 'confirmed', 'completed']) ||
            containsAny(['نجاح','ناجح','مؤكد','تم','تم الدفع','مدفوع','مكتمل','اكتمل','موافق','تمت الموافقة'])) {
          derivedPriority = 'success';
        } else if (containsAny(['pend', 'wait', 'processing', 'warning']) ||
            containsAny(['تحذير','قيد','انتظار','معلق','قيد الانتظار','قيد المعالجة'])) {
          derivedPriority = 'medium';
        } else if (containsAny(['message', 'chat', 'info', 'notify', 'created', 'create']) ||
            containsAny(['رسالة','محادثة','معلومات','إشعار','تم الإنشاء','إنشاء'])) {
          derivedPriority = 'info';
        } else {
          switch (fallbackType) {
            case 'booking':
              derivedPriority = 'medium';
              break;
            case 'chat':
            case 'new_message':
              derivedPriority = 'info';
              break;
            case 'conversation_created':
              derivedPriority = 'low';
              break;
            default:
              derivedPriority = 'info';
          }
        }
      }
    }
    debugPrint('In-app dialog priority="$derivedPriority" from data=${json.encode(data)}');

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
    return;
  }

  // Handle background messages (static function required)
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('Background message received: ${message.messageId}');
  }

  // Handle notification tap when app is opened
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.messageId}');
    final data = message.data;
    final type = (data['type'] ?? data['event_type'] ?? '').toString();
    if (type == 'new_message' || type == 'chat.new_message') {
      final conversationId =
          (data['conversation_id'] ?? data['conversationId'] ?? '').toString();
      final messageId =
          (data['message_id'] ?? data['messageId'] ?? '').toString();
      if (conversationId.isNotEmpty) {
        // UI will load when navigated
      }
    }
    _navigateToScreen(data);
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
    // Suppress in-app local notifications always (foreground)
    return;

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
                ? context.push('/admin/bookings/${id.toString()}')
                : context.go('/admin/bookings/${id.toString()}');
            return;
          }
          preferPush ? context.push('/notifications') : context.go('/notifications');
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
          preferPush ? context.push('/notifications') : context.go('/notifications');
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

// Helper to dispatch a status update into ChatBloc pipeline via WebSocketService streams
void _dispatchStatusUpdate(
    String conversationId, String messageId, String status) {
  try {
    final ws = di.sl<ChatWebSocketService>();
    ws.messageEvents.listen((_) {}); // ensure stream is active
    // Internally push a synthetic status update event
    // We don't have direct access to add event in bloc here, but WebSocketService exposes a stream consumed by ChatBloc
    // So we emulate by sending a crafted map through the private handler would be intrusive; as an alternative,
    // we reuse emitNewMessageById path to force a refresh if messageId missing.
    // Since ChatBloc now handles MessageEventType.statusUpdated, prefer emitting empty newMessage fetch when ids missing.
    if (messageId.isEmpty || status.isEmpty) {
      ws.emitNewMessageById(conversationId: conversationId, messageId: '');
    } else {
      // Fallback: trigger a messages fetch which updates statuses from server
      ws.emitNewMessageById(conversationId: conversationId, messageId: '');
    }
  } catch (e) {
    debugPrint('Failed to dispatch status update: $e');
  }
}
