import '../../domain/entities/booking.dart';
import '../../domain/entities/booking_details.dart';
import 'booking_model.dart';
import '../../../../../core/enums/payment_method_enum.dart';
import 'dart:convert';

class BookingDetailsModel extends BookingDetails {
  const BookingDetailsModel({
    required super.booking,
    required super.payments,
    required super.services,
    super.activities,
    super.guestInfo,
    super.unitDetails,
    super.propertyDetails,
  });

  factory BookingDetailsModel.fromJson(Map<String, dynamic> json) {
    // Support multiple backend shapes (Admin CP, Mobile, Legacy):
    // 1) { data: {...} } is handled by caller; here we get {...}

Map<String, dynamic>? _safeDecodeJsonMap(dynamic v) {
  try {
    if (v == null) return null;
    if (v is Map) return Map<String, dynamic>.from(v);
    if (v is String) {
      final decoded = jsonDecode(v);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
  } catch (_) {}
  return null;
}
    // 2) { booking: {...}, payments: [...], services: [...] }
    // 3) Flat BookingDetailsDto with fields like payments/paymentDetails, contactInfo, propertyAddress, unitImages, totalAmount/currency

    // Extract booking node if present, otherwise treat the whole json as a details DTO
    final Object? bookingNode = json['booking'] ?? json;
    final Map<String, dynamic> bookingRaw = bookingNode is Map
        ? Map<String, dynamic>.from(bookingNode)
        : <String, dynamic>{};

    // Normalize booking map expected by BookingModel.fromJson
    final bool isFlatDetailsDto = bookingRaw.isNotEmpty &&
        (bookingRaw.containsKey('totalAmount') ||
            bookingRaw.containsKey('bookingNumber') ||
            bookingRaw.containsKey('contactInfo') ||
            bookingRaw.containsKey('checkIn') ||
            bookingRaw.containsKey('checkInDate'));

    Map<String, dynamic> normalizedBookingMap;
    if (bookingNode == json && isFlatDetailsDto) {
      // Build a BookingModel-compatible map from flat details
      final String? currency = bookingRaw['currency']?.toString();
      final double totalAmount = (bookingRaw['totalAmount'] ?? 0).toDouble();
      final String formattedAmount =
          '${currency ?? 'YER'} ${totalAmount.toStringAsFixed(2)}';

      final DateTime? actualCheckIn =
          _tryParseDate(bookingRaw['actualCheckInDate']);
      final DateTime? actualCheckOut =
          _tryParseDate(bookingRaw['actualCheckOutDate']);
      final DateTime? confirmedAt = _tryParseDate(bookingRaw['confirmedAt']);
      final DateTime? cancelledAt = _tryParseDate(bookingRaw['cancelledAt']);

      final List unitImages = (bookingRaw['unitImages'] is List)
          ? (bookingRaw['unitImages'] as List)
          : const [];

      // Contact info fallback for guest data
      final Map<String, dynamic> contactInfo = Map<String, dynamic>.from(
          (bookingRaw['contactInfo'] is Map) ? bookingRaw['contactInfo'] : {});

      normalizedBookingMap = {
        'id': bookingRaw['id']?.toString() ?? '',
        'userId': bookingRaw['userId']?.toString() ?? '',
        'unitId': bookingRaw['unitId']?.toString() ?? '',
        'checkIn':
            (bookingRaw['checkIn'] ?? bookingRaw['checkInDate'])?.toString() ??
                DateTime.now().toIso8601String(),
        'checkOut': (bookingRaw['checkOut'] ?? bookingRaw['checkOutDate'])
                ?.toString() ??
            DateTime.now().toIso8601String(),
        'guestsCount': bookingRaw['guestsCount'] ??
            ((bookingRaw['adultGuests'] ?? 0) +
                (bookingRaw['childGuests'] ?? 0)),
        'totalPrice': {
          'amount': totalAmount,
          'currency': currency ?? 'YER',
          'formattedAmount': formattedAmount,
        },
        'status': bookingRaw['status']?.toString(),
        'bookedAt':
            (bookingRaw['bookedAt'] ?? bookingRaw['bookingDate'])?.toString() ??
                DateTime.now().toIso8601String(),
        'userName': bookingRaw['userName'] ?? '',
        'unitName': bookingRaw['unitName'] ?? '',
        'userEmail': bookingRaw['userEmail'] ?? contactInfo['email'],
        'userPhone': bookingRaw['userPhone'] ?? contactInfo['phoneNumber'],
        'unitImage':
            unitImages.isNotEmpty ? unitImages.first?.toString() : null,
        'propertyId': bookingRaw['propertyId']?.toString(),
        'propertyName': bookingRaw['propertyName'],
        'notes': bookingRaw['specialNotes'],
        'specialRequests': bookingRaw['specialRequests'],
        'cancellationReason': bookingRaw['cancellationReason'],
        'cancelledAt': cancelledAt?.toIso8601String(),
        'confirmedAt': confirmedAt?.toIso8601String(),
        'checkedInAt':
            (actualCheckIn ?? _tryParseDate(bookingRaw['checkedInAt']))
                ?.toIso8601String(),
        'checkedOutAt':
            (actualCheckOut ?? _tryParseDate(bookingRaw['checkedOutAt']))
                ?.toIso8601String(),
        'bookingSource': bookingRaw['bookingSource'],
        'isWalkIn': bookingRaw['isWalkIn'],
        'paymentStatus': bookingRaw['paymentStatus'],
      };
    } else {
      // Already in expected booking shape
      normalizedBookingMap = bookingRaw;
    }

    // Payments: support both payments[] and paymentDetails[] (Admin mapping)
    List paymentsRaw = const [];
    if (json['payments'] is List) {
      // مرر البيانات الأصلية مباشرة إلى PaymentModel
      paymentsRaw = json['payments'] as List;
    }
    
    // If only paymentDetails is provided
    if (paymentsRaw.isEmpty && json['paymentDetails'] is List) {
      paymentsRaw = json['paymentDetails'] as List;
    }

    // Services: support services[] and BookingServiceDto (TotalPrice + Quantity)
    List servicesRaw = const [];
    if (json['services'] is List) servicesRaw = json['services'] as List;
    servicesRaw = servicesRaw.whereType<Map>().map((s) {
      final ms = Map<String, dynamic>.from(s);
      // If service has TotalPrice/Currency (BookingServiceDto), convert to price + quantity
      if (ms.containsKey('totalPrice') || ms.containsKey('currency')) {
        final int qty = (ms['quantity'] ?? 1) is int
            ? (ms['quantity'] ?? 1)
            : int.tryParse(ms['quantity'].toString()) ?? 1;
        final double total = (ms['totalPrice'] ?? 0).toDouble();
        final String cur = ms['currency']?.toString() ??
            (normalizedBookingMap['totalPrice']?['currency']?.toString() ??
                'YER');
        final double unitPrice = qty > 0 ? (total / qty) : total;
        return {
          'id': ms['id']?.toString() ?? '',
          'name': ms['name'] ?? '',
          'description': ms['description'] ?? '',
          'quantity': qty,
          'price': {
            'amount': unitPrice,
            'currency': cur,
            'formattedAmount': '$cur ${unitPrice.toStringAsFixed(2)}',
          },
          'icon': ms['icon'],
          'category': ms['category'],
        };
      }
      return ms;
    }).toList();

    // Activities (optional)
    List activitiesRaw = const [];
    if (json['activities'] is List) activitiesRaw = json['activities'] as List;

    // Guest info fallback to contactInfo if provided but guestInfo is missing
    final guestInfoRaw = json['guestInfo'] ?? json['contactInfo'];

    // Unit details fallback using unitImages
    Map<String, dynamic>? unitDetailsRaw;
    if (json['unitDetails'] is Map) {
      unitDetailsRaw = Map<String, dynamic>.from(json['unitDetails']);
    } else if (json['unitImages'] is List) {
      unitDetailsRaw = {
        'id': normalizedBookingMap['unitId'] ?? '',
        'name': normalizedBookingMap['unitName'] ?? '',
        'type': '',
        'capacity': normalizedBookingMap['guestsCount'] ?? 1,
        'amenities': const <String>[],
        'images': List<String>.from(
            (json['unitImages'] as List).map((e) => e.toString())),
      };
    }

    // Property details fallback using propertyAddress in flat DTO
    Map<String, dynamic>? propertyDetailsRaw;
    if (json['propertyDetails'] is Map) {
      propertyDetailsRaw = Map<String, dynamic>.from(json['propertyDetails']);
    } else if (bookingRaw['propertyAddress'] != null ||
        json['propertyAddress'] != null) {
      propertyDetailsRaw = {
        'id': normalizedBookingMap['propertyId'] ?? '',
        'name': normalizedBookingMap['propertyName'] ?? '',
        'address':
            (bookingRaw['propertyAddress'] ?? json['propertyAddress'] ?? '')
                .toString(),
      };
    }

    // Inject saved policy snapshot into propertyDetails.policies
    try {
      final dynamic snapRaw = json['policySnapshot'] ?? bookingRaw['policySnapshot'];
      if (snapRaw is String && snapRaw.trim().isNotEmpty) {
        final Map<String, dynamic> snap = jsonDecode(snapRaw);
        final List policies = snap['Policies'] ?? const [];
        final Map<String, dynamic> policiesByType = {};
        for (final p in policies.whereType<Map>()) {
          final mp = Map<String, dynamic>.from(p);
          final String type = (mp['Type']?.toString() ?? '').toLowerCase();
          if (type.isEmpty) continue;
          policiesByType[type] = {
            'description': mp['Description'],
            'rules': _safeDecodeJsonMap(mp['Rules']),
            'cancellationWindowDays': mp['CancellationWindowDays'],
            'requireFullPaymentBeforeConfirmation': mp['RequireFullPaymentBeforeConfirmation'],
            'minimumDepositPercentage': mp['MinimumDepositPercentage'],
            'minHoursBeforeCheckIn': mp['MinHoursBeforeCheckIn'],
          };
        }
        final saved = {
          'capturedAt': snap['CapturedAt'],
          'unitOverrides': snap['UnitOverrides'],
          'policiesByType': policiesByType,
        };
        propertyDetailsRaw ??= {
          'id': normalizedBookingMap['propertyId'] ?? '',
          'name': normalizedBookingMap['propertyName'] ?? '',
          'address': bookingRaw['propertyAddress'] ?? json['propertyAddress'] ?? '',
        };
        final Map<String, dynamic> existingPolicies = Map<String, dynamic>.from(
            propertyDetailsRaw['policies'] ?? <String, dynamic>{});
        existingPolicies['saved'] = saved;
        propertyDetailsRaw['policies'] = existingPolicies;
      }
    } catch (_) {}

    final processedPayments = paymentsRaw
        .whereType<Map>()
        .map((p) {
          try {
            return PaymentModel.fromJson(Map<String, dynamic>.from(p));
          } catch (e) {
            return null;
          }
        })
        .where((p) => p != null)
        .cast<PaymentModel>()
        .toList();
    
    return BookingDetailsModel(
      booking: BookingModel.fromJson(normalizedBookingMap),
      payments: processedPayments,
      services: servicesRaw
          .whereType<Map>()
          .map((s) => ServiceModel.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
      activities: activitiesRaw
          .whereType<Map>()
          .map((a) =>
              BookingActivityModel.fromJson(Map<String, dynamic>.from(a)))
          .toList(),
      guestInfo: guestInfoRaw is Map
          ? GuestInfoModel.fromJson(Map<String, dynamic>.from(guestInfoRaw))
          : null,
      unitDetails: unitDetailsRaw != null
          ? UnitDetailsModel.fromJson(unitDetailsRaw)
          : null,
      propertyDetails: propertyDetailsRaw != null
          ? PropertyDetailsModel.fromJson(propertyDetailsRaw)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking': (booking as BookingModel).toJson(),
      'payments': payments.map((p) => (p as PaymentModel).toJson()).toList(),
      'services': services.map((s) => (s as ServiceModel).toJson()).toList(),
      'activities':
          activities.map((a) => (a as BookingActivityModel).toJson()).toList(),
      if (guestInfo != null)
        'guestInfo': (guestInfo as GuestInfoModel).toJson(),
      if (unitDetails != null)
        'unitDetails': (unitDetails as UnitDetailsModel).toJson(),
      if (propertyDetails != null)
        'propertyDetails': (propertyDetails as PropertyDetailsModel).toJson(),
    };
  }
}

/// 💳 Model للدفعة
class PaymentModel extends Payment {
  const PaymentModel({
    required super.id,
    required super.bookingId,
    required super.amount,
    required super.transactionId,
    required super.method,
    required super.status,
    required super.paymentDate,
    super.refundReason,
    super.refundedAt,
    super.receiptUrl,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    // معالجة المبلغ - قد يأتي بعدة أشكال
    Money amountObj;
    if (json['amount'] is Map) {
      // إذا كان amount عبارة عن Map مباشرة
      amountObj = MoneyModel.fromJson(Map<String, dynamic>.from(json['amount']));
    } else if (json['amountMoney'] is Map) {
      // إذا كان البيانات في amountMoney
      amountObj = MoneyModel.fromJson(Map<String, dynamic>.from(json['amountMoney']));
    } else if (json['amount'] is num) {
      // إذا كان amount رقم مباشر
      final currency = json['currency']?.toString() ?? 'YER';
      final amount = (json['amount'] as num).toDouble();
      amountObj = MoneyModel(
        amount: amount,
        currency: currency,
        formattedAmount: '$currency ${amount.toStringAsFixed(2)}',
      );
    } else {
      // قيمة افتراضية
      amountObj = MoneyModel(
        amount: 0,
        currency: 'YER',
        formattedAmount: 'YER 0.00',
      );
    }
    
    return PaymentModel(
      id: json['id']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? '',
      amount: amountObj,
      transactionId: json['transactionId']?.toString() ?? '',
      method: _parsePaymentMethod(json['method']),
      status: _parsePaymentStatus(json['status']),
      paymentDate: DateTime.parse(json['paymentDate']?.toString() ?? DateTime.now().toIso8601String()),
      refundReason: json['refundReason'],
      refundedAt: json['refundedAt'] != null
          ? DateTime.parse(json['refundedAt'])
          : null,
      receiptUrl: json['receiptUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'amount': (amount as MoneyModel).toJson(),
      'transactionId': transactionId,
      'method': method.backendValue,
      'status': status.displayNameEn,
      'paymentDate': paymentDate.toIso8601String(),
      if (refundReason != null) 'refundReason': refundReason,
      if (refundedAt != null) 'refundedAt': refundedAt!.toIso8601String(),
      if (receiptUrl != null) 'receiptUrl': receiptUrl,
    };
  }

  static PaymentMethod _parsePaymentMethod(dynamic method) {
    if (method == null) return PaymentMethod.cash;
    if (method is int) {
      return PaymentMethodExtension.fromBackendValue(method);
    }
    if (method is String) {
      return PaymentMethodExtension.fromString(method);
    }
    return PaymentMethod.cash;
  }

  static PaymentStatus _parsePaymentStatus(dynamic status) {
    if (status == null) return PaymentStatus.pending;
    return PaymentStatusExtension.fromString(status.toString());
  }
}

/// 🛎️ Model للخدمة
class ServiceModel extends Service {
  const ServiceModel({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    required super.quantity,
    super.icon,
    super.category,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price:
          MoneyModel.fromJson(Map<String, dynamic>.from(json['price'] ?? {})),
      quantity: json['quantity'] ?? 1,
      icon: json['icon'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': (price as MoneyModel).toJson(),
      'quantity': quantity,
      if (icon != null) 'icon': icon,
      if (category != null) 'category': category,
    };
  }
}

/// 📝 Model لنشاط الحجز
class BookingActivityModel extends BookingActivity {
  const BookingActivityModel({
    required super.id,
    required super.action,
    required super.description,
    required super.timestamp,
    super.userId,
    super.userName,
  });

  factory BookingActivityModel.fromJson(Map<String, dynamic> json) {
    return BookingActivityModel(
      id: json['id']?.toString() ?? '',
      action: json['action'] ?? '',
      description: json['description'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      userId: json['userId']?.toString(),
      userName: json['userName'],
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
    };
  }
}

/// 👤 Model لمعلومات الضيف
class GuestInfoModel extends GuestInfo {
  const GuestInfoModel({
    required super.name,
    required super.email,
    required super.phone,
    super.nationality,
    super.idNumber,
    super.idType,
    super.address,
  });

  factory GuestInfoModel.fromJson(Map<String, dynamic> json) {
    return GuestInfoModel(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      nationality: json['nationality'],
      idNumber: json['idNumber'],
      idType: json['idType'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      if (nationality != null) 'nationality': nationality,
      if (idNumber != null) 'idNumber': idNumber,
      if (idType != null) 'idType': idType,
      if (address != null) 'address': address,
    };
  }
}

/// 🏠 Model لتفاصيل الوحدة
class UnitDetailsModel extends UnitDetails {
  const UnitDetailsModel({
    required super.id,
    required super.name,
    required super.type,
    required super.capacity,
    required super.amenities,
    required super.images,
    super.description,
    super.location,
  });

  factory UnitDetailsModel.fromJson(Map<String, dynamic> json) {
    return UnitDetailsModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      capacity: json['capacity'] ?? 1,
      amenities: List<String>.from(json['amenities'] ?? []),
      images: List<String>.from(json['images'] ?? []),
      description: json['description'],
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'capacity': capacity,
      'amenities': amenities,
      'images': images,
      if (description != null) 'description': description,
      if (location != null) 'location': location,
    };
  }
}

/// 🏢 Model لتفاصيل العقار
class PropertyDetailsModel extends PropertyDetails {
  const PropertyDetailsModel({
    required super.id,
    required super.name,
    required super.address,
    super.phone,
    super.email,
    super.checkInTime,
    super.checkOutTime,
    super.policies,
  });

  factory PropertyDetailsModel.fromJson(Map<String, dynamic> json) {
    return PropertyDetailsModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'],
      email: json['email'],
      checkInTime: json['checkInTime'],
      checkOutTime: json['checkOutTime'],
      policies: json['policies'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (checkInTime != null) 'checkInTime': checkInTime,
      if (checkOutTime != null) 'checkOutTime': checkOutTime,
      if (policies != null) 'policies': policies,
    };
  }
}

DateTime? _tryParseDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;

  if (raw is num) {
    return _dateTimeFromEpoch(raw.toInt());
  }

  final String value = raw.toString().trim();
  if (value.isEmpty) return null;

  final DateTime? parsed = DateTime.tryParse(value);
  if (parsed != null) return parsed;

  final int? epoch = int.tryParse(value);
  if (epoch != null) {
    return _dateTimeFromEpoch(epoch);
  }

  return null;
}

DateTime? _dateTimeFromEpoch(int epoch) {
  if (epoch <= 0) return null;

  if (epoch < 1000000000000) {
    return DateTime.fromMillisecondsSinceEpoch(epoch * 1000, isUtc: true)
        .toLocal();
  }

  if (epoch < 1000000000000000) {
    return DateTime.fromMillisecondsSinceEpoch(epoch, isUtc: true).toLocal();
  }

  return DateTime.fromMicrosecondsSinceEpoch(epoch, isUtc: true).toLocal();
}
