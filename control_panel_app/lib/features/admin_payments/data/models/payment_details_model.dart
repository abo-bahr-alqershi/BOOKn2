import 'package:bookn_cp_app/features/admin_payments/domain/entities/payment.dart';
import 'package:bookn_cp_app/features/admin_payments/domain/entities/refund.dart';

import '../../domain/entities/payment_details.dart';
import 'payment_model.dart';
import 'refund_model.dart';

class PaymentDetailsModel extends PaymentDetails {
  const PaymentDetailsModel({
    required super.payment,
    required super.refunds,
    required super.activities,
    super.bookingInfo,
    super.customerInfo,
    super.gatewayInfo,
    super.additionalData,
  });

  factory PaymentDetailsModel.fromJson(Map<String, dynamic> json) {
    // Check if 'payment' field exists - this means it's the full details response
    if (json.containsKey('payment') && json['payment'] != null) {
      // This is the PaymentDetails structure
      return PaymentDetailsModel(
        payment: PaymentModel.fromJson(json['payment']),
        refunds: (json['refunds'] as List? ?? [])
            .map((r) => RefundModel.fromJson(r))
            .toList(),
        activities: (json['activities'] as List? ?? [])
            .map((a) => PaymentActivityModel.fromJson(a))
            .toList(),
        bookingInfo: json['bookingInfo'] != null
            ? BookingInfoModel.fromJson(json['bookingInfo'])
            : null,
        customerInfo: json['customerInfo'] != null
            ? CustomerInfoModel.fromJson(json['customerInfo'])
            : null,
        gatewayInfo: json['gatewayInfo'] != null
            ? PaymentGatewayInfoModel.fromJson(json['gatewayInfo'])
            : null,
        additionalData: json['additionalData'] as Map<String, dynamic>?,
      );
    } else {
      // This is just a Payment object, create minimal PaymentDetails
      return PaymentDetailsModel(
        payment: PaymentModel.fromJson(json),
        refunds: [],
        activities: [],
        bookingInfo: null,
        customerInfo: null,
        gatewayInfo: null,
        additionalData: null,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'payment': (payment as PaymentModel).toJson(),
      'refunds': refunds.map((r) => (r as RefundModel).toJson()).toList(),
      'activities':
          activities.map((a) => (a as PaymentActivityModel).toJson()).toList(),
      if (bookingInfo != null)
        'bookingInfo': (bookingInfo as BookingInfoModel).toJson(),
      if (customerInfo != null)
        'customerInfo': (customerInfo as CustomerInfoModel).toJson(),
      if (gatewayInfo != null)
        'gatewayInfo': (gatewayInfo as PaymentGatewayInfoModel).toJson(),
      if (additionalData != null) 'additionalData': additionalData,
    };
  }
}

class PaymentActivityModel extends PaymentActivity {
  const PaymentActivityModel({
    required super.id,
    required super.action,
    required super.description,
    required super.timestamp,
    super.userId,
    super.userName,
    super.data,
  });

  factory PaymentActivityModel.fromJson(Map<String, dynamic> json) {
    return PaymentActivityModel(
      id: json['id']?.toString() ?? '',
      action: json['action'] ?? '',
      description: json['description'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      userId: json['userId']?.toString(),
      userName: json['userName'],
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      if (userId != null) 'userId': userId,
      if (userName != null) 'userName': userName,
      if (data != null) 'data': data,
    };
  }
}

class BookingInfoModel extends BookingInfo {
  const BookingInfoModel({
    required super.bookingId,
    required super.bookingReference,
    required super.checkIn,
    required super.checkOut,
    required super.unitName,
    required super.propertyName,
    required super.guestsCount,
  });

  factory BookingInfoModel.fromJson(Map<String, dynamic> json) {
    return BookingInfoModel(
      bookingId: json['bookingId']?.toString() ?? '',
      bookingReference: json['bookingReference'] ?? '',
      checkIn: DateTime.parse(json['checkIn']),
      checkOut: DateTime.parse(json['checkOut']),
      unitName: json['unitName'] ?? '',
      propertyName: json['propertyName'] ?? '',
      guestsCount: json['guestsCount'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'bookingReference': bookingReference,
      'checkIn': checkIn.toIso8601String(),
      'checkOut': checkOut.toIso8601String(),
      'unitName': unitName,
      'propertyName': propertyName,
      'guestsCount': guestsCount,
    };
  }
}

class CustomerInfoModel extends CustomerInfo {
  const CustomerInfoModel({
    required super.customerId,
    required super.name,
    required super.email,
    super.phone,
    super.address,
    super.nationality,
    super.additionalInfo,
  });

  factory CustomerInfoModel.fromJson(Map<String, dynamic> json) {
    return CustomerInfoModel(
      customerId: json['customerId']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      address: json['address'],
      nationality: json['nationality'],
      additionalInfo: json['additionalInfo'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'name': name,
      'email': email,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (nationality != null) 'nationality': nationality,
      if (additionalInfo != null) 'additionalInfo': additionalInfo,
    };
  }
}

class PaymentGatewayInfoModel extends PaymentGatewayInfo {
  const PaymentGatewayInfoModel({
    required super.gatewayName,
    required super.gatewayTransactionId,
    super.authorizationCode,
    super.responseCode,
    super.responseMessage,
    super.rawResponse,
  });

  factory PaymentGatewayInfoModel.fromJson(Map<String, dynamic> json) {
    return PaymentGatewayInfoModel(
      gatewayName: json['gatewayName'] ?? '',
      gatewayTransactionId: json['gatewayTransactionId'] ?? '',
      authorizationCode: json['authorizationCode'],
      responseCode: json['responseCode'],
      responseMessage: json['responseMessage'],
      rawResponse: json['rawResponse'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gatewayName': gatewayName,
      'gatewayTransactionId': gatewayTransactionId,
      if (authorizationCode != null) 'authorizationCode': authorizationCode,
      if (responseCode != null) 'responseCode': responseCode,
      if (responseMessage != null) 'responseMessage': responseMessage,
      if (rawResponse != null) 'rawResponse': rawResponse,
    };
  }
}
