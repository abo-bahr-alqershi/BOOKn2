import 'dart:async';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class DeepLinkService {
  late FirebaseDynamicLinks _dynamicLinks;
  late AppLinks _appLinks;
  StreamSubscription? _linkSubscription;
  
  // Stream controller for deep links
  final _deepLinkController = StreamController<DeepLinkData>.broadcast();
  Stream<DeepLinkData> get deepLinkStream => _deepLinkController.stream;

  DeepLinkService() {
    _dynamicLinks = FirebaseDynamicLinks.instance;
    _appLinks = AppLinks();
  }

  // Initialize deep link service
  Future<void> initialize() async {
    // Handle Firebase Dynamic Links
    await _initDynamicLinks();
    
    // Handle custom scheme links
    await _initAppLinks();
  }

  // Initialize Firebase Dynamic Links
  Future<void> _initDynamicLinks() async {
    // Handle initial dynamic link if app was closed
    final initialLink = await _dynamicLinks.getInitialLink();
    if (initialLink != null) {
      _handleDynamicLink(initialLink);
    }

    // Listen for dynamic links when app is in foreground/background
    _dynamicLinks.onLink.listen(
      _handleDynamicLink,
      onError: (error) {
        debugPrint('Dynamic Link Error: $error');
      },
    );
  }

  // Initialize app_links for custom schemes
  Future<void> _initAppLinks() async {
    // Handle initial link if app was closed
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink.toString());
      }
    } on PlatformException {
      debugPrint('Failed to get initial link');
    }

    // Listen for links when app is in foreground/background
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleDeepLink(uri.toString());
      },
      onError: (error) {
        debugPrint('Link Stream Error: $error');
      },
    );
  }

  // Handle Firebase Dynamic Link
  void _handleDynamicLink(PendingDynamicLinkData dynamicLink) {
    final Uri deepLink = dynamicLink.link;
    debugPrint('Received dynamic link: $deepLink');

    final data = _parseDeepLink(deepLink.toString());
    if (data != null) {
      _deepLinkController.add(data);
    }
  }

  // Handle custom scheme deep link
  void _handleDeepLink(String link) {
    debugPrint('Received deep link: $link');
    
    final data = _parseDeepLink(link);
    if (data != null) {
      _deepLinkController.add(data);
    }
  }

  // Parse deep link and extract data
  DeepLinkData? _parseDeepLink(String link) {
    try {
      final uri = Uri.parse(link);
      final path = uri.path;
      final queryParams = uri.queryParameters;

      // Parse different link types
      if (path.contains('/property/')) {
        final propertyId = path.split('/property/').last;
        return DeepLinkData(
          type: DeepLinkType.property,
          id: propertyId,
          parameters: queryParams,
        );
      } else if (path.contains('/booking/')) {
        final bookingId = path.split('/booking/').last;
        return DeepLinkData(
          type: DeepLinkType.booking,
          id: bookingId,
          parameters: queryParams,
        );
      } else if (path.contains('/search')) {
        return DeepLinkData(
          type: DeepLinkType.search,
          parameters: queryParams,
        );
      } else if (path.contains('/profile/')) {
        final userId = path.split('/profile/').last;
        return DeepLinkData(
          type: DeepLinkType.profile,
          id: userId,
          parameters: queryParams,
        );
      } else if (path.contains('/promotion/')) {
        final promotionId = path.split('/promotion/').last;
        return DeepLinkData(
          type: DeepLinkType.promotion,
          id: promotionId,
          parameters: queryParams,
        );
      } else if (path.contains('/reset-password')) {
        return DeepLinkData(
          type: DeepLinkType.resetPassword,
          parameters: queryParams,
        );
      } else if (path.contains('/verify-email')) {
        return DeepLinkData(
          type: DeepLinkType.verifyEmail,
          parameters: queryParams,
        );
      }

      return null;
    } catch (e) {
      debugPrint('Error parsing deep link: $e');
      return null;
    }
  }

  // Create dynamic link
  Future<Uri> createDynamicLink({
    required String path,
    Map<String, String>? queryParameters,
    String? title,
    String? description,
    String? imageUrl,
  }) async {
    final dynamicLinkParams = DynamicLinkParameters(
      link: Uri.parse('https://yemenbooking.com$path').replace(
        queryParameters: queryParameters,
      ),
      uriPrefix: 'https://yemenbooking.page.link',
      androidParameters: const AndroidParameters(
        packageName: 'com.yemenbooking.app',
        minimumVersion: 1,
      ),
      iosParameters: const IOSParameters(
        bundleId: 'com.yemenbooking.app',
        minimumVersion: '1.0.0',
        appStoreId: '123456789',
      ),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: title,
        description: description,
        imageUrl: imageUrl != null ? Uri.parse(imageUrl) : null,
      ),
    );

    final shortLink = await _dynamicLinks.buildShortLink(dynamicLinkParams);
    return shortLink.shortUrl;
  }

  // Create property share link
  Future<Uri> createPropertyShareLink({
    required String propertyId,
    String? propertyName,
    String? propertyImage,
  }) async {
    return await createDynamicLink(
      path: '/property/$propertyId',
      title: propertyName ?? 'عقار مميز على Yemen Booking',
      description: 'شاهد هذا العقار المميز على تطبيق Yemen Booking',
      imageUrl: propertyImage,
    );
  }

  // Create booking share link
  Future<Uri> createBookingShareLink({
    required String bookingId,
  }) async {
    return await createDynamicLink(
      path: '/booking/$bookingId',
      title: 'حجزي على Yemen Booking',
      description: 'تفاصيل الحجز على تطبيق Yemen Booking',
    );
  }

  // Create search link
  Future<Uri> createSearchLink({
    String? location,
    String? propertyType,
    DateTime? checkIn,
    DateTime? checkOut,
    int? guests,
  }) async {
    final queryParams = <String, String>{};
    
    if (location != null) queryParams['location'] = location;
    if (propertyType != null) queryParams['type'] = propertyType;
    if (checkIn != null) queryParams['checkin'] = checkIn.toIso8601String();
    if (checkOut != null) queryParams['checkout'] = checkOut.toIso8601String();
    if (guests != null) queryParams['guests'] = guests.toString();

    return await createDynamicLink(
      path: '/search',
      queryParameters: queryParams,
      title: 'ابحث عن عقارات في Yemen Booking',
      description: 'اكتشف أفضل العقارات والفنادق في اليمن',
    );
  }

  // Dispose
  void dispose() {
    _linkSubscription?.cancel();
    _deepLinkController.close();
  }
}

// Deep link data model
class DeepLinkData {
  final DeepLinkType type;
  final String? id;
  final Map<String, String>? parameters;

  DeepLinkData({
    required this.type,
    this.id,
    this.parameters,
  });
}

// Deep link types
enum DeepLinkType {
  property,
  booking,
  search,
  profile,
  promotion,
  resetPassword,
  verifyEmail,
}
