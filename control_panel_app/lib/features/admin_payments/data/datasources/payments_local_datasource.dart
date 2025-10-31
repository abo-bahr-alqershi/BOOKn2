import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/payment_model.dart';

abstract class PaymentsLocalDataSource {
  Future<void> cachePayments(List<PaymentModel> payments);
  Future<List<PaymentModel>> getCachedPayments();
  Future<void> cachePaymentDetails(String paymentId, PaymentModel payment);
  Future<PaymentModel?> getCachedPaymentDetails(String paymentId);
  Future<void> clearCache();
}

class PaymentsLocalDataSourceImpl implements PaymentsLocalDataSource {
  final SharedPreferences sharedPreferences;

  static const CACHED_PAYMENTS = 'CACHED_PAYMENTS';
  static const CACHED_PAYMENT_PREFIX = 'CACHED_PAYMENT_';

  PaymentsLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cachePayments(List<PaymentModel> payments) async {
    final jsonList = payments.map((payment) => payment.toJson()).toList();
    await sharedPreferences.setString(
      CACHED_PAYMENTS,
      json.encode(jsonList),
    );
  }

  @override
  Future<List<PaymentModel>> getCachedPayments() async {
    final jsonString = sharedPreferences.getString(CACHED_PAYMENTS);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => PaymentModel.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<void> cachePaymentDetails(
      String paymentId, PaymentModel payment) async {
    await sharedPreferences.setString(
      '$CACHED_PAYMENT_PREFIX$paymentId',
      json.encode(payment.toJson()),
    );
  }

  @override
  Future<PaymentModel?> getCachedPaymentDetails(String paymentId) async {
    final jsonString = sharedPreferences.getString(
      '$CACHED_PAYMENT_PREFIX$paymentId',
    );
    if (jsonString != null) {
      return PaymentModel.fromJson(json.decode(jsonString));
    }
    return null;
  }

  @override
  Future<void> clearCache() async {
    await sharedPreferences.remove(CACHED_PAYMENTS);
    // Clear individual payment details
    final keys = sharedPreferences.getKeys();
    for (final key in keys) {
      if (key.startsWith(CACHED_PAYMENT_PREFIX)) {
        await sharedPreferences.remove(key);
      }
    }
  }
}
