import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

/// خدمة إدارة الاتصال بالإنترنت
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
  
  bool _isConnected = false;
  Timer? _connectionCheckTimer;

  /// Stream لحالة الاتصال
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  /// الحالة الحالية للاتصال
  bool get isConnected => _isConnected;

  /// تهيئة الخدمة
  Future<void> initialize() async {
    // التحقق من الحالة الأولية
    await _checkConnectionStatus();
    
    // الاستماع لتغييرات الاتصال
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      _handleConnectivityChange(result);
    });

    // بدء فحص دوري للاتصال كل 30 ثانية
    _startPeriodicConnectionCheck();
  }

  /// التحقق من حالة الاتصال
  Future<bool> checkConnection() async {
    try {
      // التحقق من الاتصال بالإنترنت
      final result = await InternetAddress.lookup('google.com');
      final isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      
      if (_isConnected != isConnected) {
        _isConnected = isConnected;
        _connectionStatusController.add(isConnected);
      }
      
      return isConnected;
    } on SocketException catch (_) {
      if (_isConnected) {
        _isConnected = false;
        _connectionStatusController.add(false);
      }
      return false;
    } catch (e) {
      print('Error checking connection: $e');
      return false;
    }
  }

  /// التحقق من نوع الاتصال
  Future<ConnectivityResult> getConnectionType() async {
    try {
      return await _connectivity.checkConnectivity();
    } catch (e) {
      print('Error getting connection type: $e');
      return ConnectivityResult.none;
    }
  }

  /// التحقق من جودة الاتصال
  Future<ConnectionQuality> checkConnectionQuality() async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // محاولة الاتصال بخادم سريع
      final result = await InternetAddress.lookup('8.8.8.8');
      stopwatch.stop();
      
      final responseTime = stopwatch.elapsedMilliseconds;
      
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        if (responseTime < 100) {
          return ConnectionQuality.excellent;
        } else if (responseTime < 300) {
          return ConnectionQuality.good;
        } else if (responseTime < 1000) {
          return ConnectionQuality.fair;
        } else {
          return ConnectionQuality.poor;
        }
      } else {
        return ConnectionQuality.none;
      }
    } catch (e) {
      return ConnectionQuality.none;
    }
  }

  /// اختبار الاتصال بخادم معين
  Future<bool> testConnectionToServer(String host, {int port = 80, Duration timeout = const Duration(seconds: 5)}) async {
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// التحقق من الاتصال بخوادم التطبيق
  Future<bool> checkAppServerConnection() async {
    // يمكن إضافة خوادم التطبيق هنا
    const servers = [
      'api.yemenbooking.com',
      'yemenbooking.com',
    ];

    for (final server in servers) {
      try {
        final result = await InternetAddress.lookup(server);
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          return true;
        }
      } catch (e) {
        continue;
      }
    }
    
    return false;
  }

  /// بدء الفحص الدوري للاتصال
  void _startPeriodicConnectionCheck() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkConnectionStatus();
    });
  }

  /// إيقاف الفحص الدوري
  void stopPeriodicConnectionCheck() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = null;
  }

  /// معالجة تغيير حالة الاتصال
  void _handleConnectivityChange(ConnectivityResult result) {
    final wasConnected = _isConnected;
    _isConnected = result != ConnectivityResult.none;
    
    if (wasConnected != _isConnected) {
      _connectionStatusController.add(_isConnected);
    }
  }

  /// التحقق من حالة الاتصال
  Future<void> _checkConnectionStatus() async {
    await checkConnection();
  }

  /// إغلاق الخدمة
  void dispose() {
    stopPeriodicConnectionCheck();
    _connectionStatusController.close();
  }
}

/// جودة الاتصال
enum ConnectionQuality {
  none,
  poor,
  fair,
  good,
  excellent,
}

/// امتداد لجودة الاتصال
extension ConnectionQualityExtension on ConnectionQuality {
  String get displayName {
    switch (this) {
      case ConnectionQuality.none:
        return 'لا يوجد اتصال';
      case ConnectionQuality.poor:
        return 'اتصال ضعيف';
      case ConnectionQuality.fair:
        return 'اتصال مقبول';
      case ConnectionQuality.good:
        return 'اتصال جيد';
      case ConnectionQuality.excellent:
        return 'اتصال ممتاز';
    }
  }

  bool get isConnected {
    return this != ConnectionQuality.none;
  }
}