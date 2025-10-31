import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bookn_cp_app/injection_container.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  late FirebaseAnalytics _analytics;
  late FirebaseAnalyticsObserver _observer;

  FirebaseAnalytics get analytics => _analytics;
  FirebaseAnalyticsObserver get observer => _observer;

  // Initialize analytics
  void initialize() {
    _analytics = FirebaseAnalytics.instance;
    _observer = FirebaseAnalyticsObserver(analytics: _analytics);
  }

  // Set user properties
  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }

  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  // Clear user data
  Future<void> resetAnalyticsData() async {
    await _analytics.setUserId(id: null);
  }

  // Screen tracking
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
  }

  // Authentication events
  Future<void> logLogin({required String method}) async {
    await _analytics.logLogin(loginMethod: method);
  }

  Future<void> logSignUp({required String method}) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  Future<void> logLogout() async {
    await _analytics.logEvent(name: 'logout');
  }

  // Property events
  Future<void> logViewProperty({
    required String propertyId,
    required String propertyName,
    required String propertyType,
    required double price,
    String? location,
  }) async {
    final userCurrency = sl<SharedPreferences>().getString('selected_currency') ?? 'YER';
    await _analytics.logViewItem(
      currency: userCurrency,
      value: price,
      items: [
        AnalyticsEventItem(
          itemId: propertyId,
          itemName: propertyName,
          itemCategory: propertyType,
          locationId: location,
          price: price,
        ),
      ],
    );
  }

  Future<void> logViewPropertyList({
    required String listType,
    required List<Map<String, dynamic>> properties,
  }) async {
    await _analytics.logViewItemList(
      itemListId: listType,
      itemListName: listType,
      items: properties.map((property) => 
        AnalyticsEventItem(
          itemId: property['id'],
          itemName: property['name'],
          itemCategory: property['type'],
          price: property['price']?.toDouble() ?? 0,
        ),
      ).toList(),
    );
  }

  Future<void> logAddToFavorites({
    required String propertyId,
    required String propertyName,
    required String propertyType,
    required double price,
  }) async {
    final userCurrency = sl<SharedPreferences>().getString('selected_currency') ?? 'YER';
    await _analytics.logAddToWishlist(
      currency: userCurrency,
      value: price,
      items: [
        AnalyticsEventItem(
          itemId: propertyId,
          itemName: propertyName,
          itemCategory: propertyType,
          price: price,
        ),
      ],
    );
  }

  Future<void> logRemoveFromFavorites({
    required String propertyId,
    required String propertyName,
  }) async {
    await _analytics.logEvent(
      name: 'remove_from_favorites',
      parameters: {
        'property_id': propertyId,
        'property_name': propertyName,
      },
    );
  }

  Future<void> logShareProperty({
    required String propertyId,
    required String propertyName,
    required String method,
  }) async {
    await _analytics.logShare(
      contentType: 'property',
      itemId: propertyId,
      method: method,
    );
  }

  // Search events
  Future<void> logSearch({
    required String searchTerm,
    String? location,
    String? propertyType,
    DateTime? checkIn,
    DateTime? checkOut,
    int? numberOfGuests,
  }) async {
    await _analytics.logSearch(
      searchTerm: searchTerm,
      parameters: {
        if (location != null) 'location': location,
        if (propertyType != null) 'property_type': propertyType,
        if (checkIn != null) 'check_in': checkIn.toIso8601String(),
        if (checkOut != null) 'check_out': checkOut.toIso8601String(),
        if (numberOfGuests != null) 'guests': numberOfGuests,
      },
    );
  }

  Future<void> logApplyFilter({
    required Map<String, dynamic> filters,
  }) async {
    await _analytics.logEvent(
      name: 'apply_filter',
      parameters: filters,
    );
  }

  // Booking events
  Future<void> logBeginCheckout({
    required String propertyId,
    required String propertyName,
    required double totalPrice,
    required DateTime checkIn,
    required DateTime checkOut,
    required int numberOfNights,
  }) async {
    final userCurrency = sl<SharedPreferences>().getString('selected_currency') ?? 'YER';
    await _analytics.logBeginCheckout(
      currency: userCurrency,
      value: totalPrice,
      items: [
        AnalyticsEventItem(
          itemId: propertyId,
          itemName: propertyName,
          quantity: numberOfNights,
          price: totalPrice / numberOfNights,
        ),
      ],
    );
  }

  Future<void> logAddPaymentInfo({
    required String paymentMethod,
  }) async {
    await _analytics.logEvent(
      name: 'add_payment_info',
      parameters: {
        'payment_method': paymentMethod,
      },
    );
  }

  Future<void> logBookingComplete({
    required String bookingId,
    required String propertyId,
    required String propertyName,
    required double totalPrice,
    required String paymentMethod,
    required int numberOfNights,
  }) async {
    final userCurrency = sl<SharedPreferences>().getString('selected_currency') ?? 'YER';
    await _analytics.logPurchase(
      transactionId: bookingId,
      currency: userCurrency,
      value: totalPrice,
      items: [
        AnalyticsEventItem(
          itemId: propertyId,
          itemName: propertyName,
          quantity: numberOfNights,
          price: totalPrice / numberOfNights,
        ),
      ],
    );
  }

  Future<void> logCancelBooking({
    required String bookingId,
    required String reason,
  }) async {
    final userCurrency = sl<SharedPreferences>().getString('selected_currency') ?? 'YER';
    await _analytics.logRefund(
      transactionId: bookingId,
      currency: userCurrency,
      value: 0,
      parameters: {'reason': reason},
    );
  }

  // Review events
  Future<void> logWriteReview({
    required String propertyId,
    required double rating,
  }) async {
    await _analytics.logEvent(
      name: 'write_review',
      parameters: {
        'property_id': propertyId,
        'rating': rating,
      },
    );
  }

  // Chat events
  Future<void> logStartChat({
    required String conversationId,
    required String propertyId,
  }) async {
    await _analytics.logEvent(
      name: 'start_chat',
      parameters: {
        'conversation_id': conversationId,
        'property_id': propertyId,
      },
    );
  }

  Future<void> logSendMessage({
    required String conversationId,
    required String messageType,
  }) async {
    await _analytics.logEvent(
      name: 'send_message',
      parameters: {
        'conversation_id': conversationId,
        'message_type': messageType,
      },
    );
  }

  // Custom events
  Future<void> logCustomEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters,
    );
  }

  // App lifecycle events
  Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
  }

  Future<void> logTutorialBegin() async {
    await _analytics.logTutorialBegin();
  }

  Future<void> logTutorialComplete() async {
    await _analytics.logTutorialComplete();
  }
}