/// تعداد طرق الدفع
/// Payment Methods enumeration
enum PaymentMethod {
  jwaliWallet,
  cashWallet,
  oneCashWallet,
  floskWallet,
  jaibWallet,
  cash,
  paypal,
  creditCard,
}

/// Extension for PaymentMethod enum
extension PaymentMethodExtension on PaymentMethod {
  /// Get the backend value for the payment method
  int get backendValue {
    switch (this) {
      case PaymentMethod.jwaliWallet:
        return 1;
      case PaymentMethod.cashWallet:
        return 2;
      case PaymentMethod.oneCashWallet:
        return 3;
      case PaymentMethod.floskWallet:
        return 4;
      case PaymentMethod.jaibWallet:
        return 5;
      case PaymentMethod.cash:
        return 6;
      case PaymentMethod.paypal:
        return 7;
      case PaymentMethod.creditCard:
        return 8;
    }
  }

  /// Get display name in Arabic
  String get displayNameAr {
    switch (this) {
      case PaymentMethod.jwaliWallet:
        return 'محفظة جوالي';
      case PaymentMethod.cashWallet:
        return 'كاش محفظة';
      case PaymentMethod.oneCashWallet:
        return 'محفظة ون كاش';
      case PaymentMethod.floskWallet:
        return 'محفظة فلوس';
      case PaymentMethod.jaibWallet:
        return 'محفظة جيب';
      case PaymentMethod.cash:
        return 'نقداً';
      case PaymentMethod.paypal:
        return 'باي بال';
      case PaymentMethod.creditCard:
        return 'بطاقة ائتمان';
    }
  }

  /// Get display name in English
  String get displayNameEn {
    switch (this) {
      case PaymentMethod.jwaliWallet:
        return 'Jwali Wallet';
      case PaymentMethod.cashWallet:
        return 'Cash Wallet';
      case PaymentMethod.oneCashWallet:
        return 'OneCash Wallet';
      case PaymentMethod.floskWallet:
        return 'Flosk Wallet';
      case PaymentMethod.jaibWallet:
        return 'Jaib Wallet';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.creditCard:
        return 'Credit Card';
    }
  }

  /// Get icon name for the payment method
  String get iconName {
    switch (this) {
      case PaymentMethod.jwaliWallet:
        return 'jwali';
      case PaymentMethod.cashWallet:
        return 'cash_wallet';
      case PaymentMethod.oneCashWallet:
        return 'one_cash';
      case PaymentMethod.floskWallet:
        return 'flosk';
      case PaymentMethod.jaibWallet:
        return 'jaib';
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.paypal:
        return 'paypal';
      case PaymentMethod.creditCard:
        return 'credit_card';
    }
  }

  /// Check if the payment method is a wallet
  bool get isWallet {
    switch (this) {
      case PaymentMethod.jwaliWallet:
      case PaymentMethod.cashWallet:
      case PaymentMethod.oneCashWallet:
      case PaymentMethod.floskWallet:
      case PaymentMethod.jaibWallet:
        return true;
      default:
        return false;
    }
  }

  /// Check if the payment method is online
  bool get isOnline {
    switch (this) {
      case PaymentMethod.cash:
        return false;
      default:
        return true;
    }
  }

  /// Create PaymentMethod from backend value
  static PaymentMethod fromBackendValue(int value) {
    switch (value) {
      case 1:
        return PaymentMethod.jwaliWallet;
      case 2:
        return PaymentMethod.cashWallet;
      case 3:
        return PaymentMethod.oneCashWallet;
      case 4:
        return PaymentMethod.floskWallet;
      case 5:
        return PaymentMethod.jaibWallet;
      case 6:
        return PaymentMethod.cash;
      case 7:
        return PaymentMethod.paypal;
      case 8:
        return PaymentMethod.creditCard;
      default:
        return PaymentMethod.cash;
    }
  }

  /// Create PaymentMethod from string
  static PaymentMethod fromString(String value) {
    final normalizedValue = value.toLowerCase().replaceAll('_', '');
    switch (normalizedValue) {
      case 'jwaliwallet':
      case 'jwali':
        return PaymentMethod.jwaliWallet;
      case 'cashwallet':
        return PaymentMethod.cashWallet;
      case 'onecashwallet':
      case 'onecash':
        return PaymentMethod.oneCashWallet;
      case 'floskwallet':
      case 'flosk':
        return PaymentMethod.floskWallet;
      case 'jaibwallet':
      case 'jaib':
        return PaymentMethod.jaibWallet;
      case 'cash':
        return PaymentMethod.cash;
      case 'paypal':
        return PaymentMethod.paypal;
      case 'creditcard':
      case 'credit':
        return PaymentMethod.creditCard;
      default:
        return PaymentMethod.cash;
    }
  }
}

/// تعداد حالات الدفع
/// Payment Status enumeration
enum PaymentStatus {
  successful,
  failed,
  pending,
  refunded,
  voided,
  partiallyRefunded,
}

/// Extension for PaymentStatus enum
extension PaymentStatusExtension on PaymentStatus {
  /// Backend key used in APIs
  String get backendKey {
    switch (this) {
      case PaymentStatus.successful:
        return 'successful';
      case PaymentStatus.failed:
        return 'failed';
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.refunded:
        return 'refunded';
      case PaymentStatus.voided:
        return 'voided';
      case PaymentStatus.partiallyRefunded:
        return 'partially_refunded';
    }
  }

  /// Get display name in Arabic
  String get displayNameAr {
    switch (this) {
      case PaymentStatus.successful:
        return 'ناجح';
      case PaymentStatus.failed:
        return 'فاشل';
      case PaymentStatus.pending:
        return 'معلق';
      case PaymentStatus.refunded:
        return 'مسترد';
      case PaymentStatus.voided:
        return 'ملغي';
      case PaymentStatus.partiallyRefunded:
        return 'مسترد جزئياً';
    }
  }

  /// Get display name in English
  String get displayNameEn {
    switch (this) {
      case PaymentStatus.successful:
        return 'Successful';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.voided:
        return 'Voided';
      case PaymentStatus.partiallyRefunded:
        return 'Partially Refunded';
    }
  }

  /// Get color for status
  String get colorCode {
    switch (this) {
      case PaymentStatus.successful:
        return '#4CAF50';
      case PaymentStatus.failed:
        return '#F44336';
      case PaymentStatus.pending:
        return '#FF9800';
      case PaymentStatus.refunded:
        return '#2196F3';
      case PaymentStatus.voided:
        return '#9E9E9E';
      case PaymentStatus.partiallyRefunded:
        return '#03A9F4';
    }
  }

  /// Check if payment is complete
  bool get isComplete {
    return this == PaymentStatus.successful;
  }

  /// Check if payment can be refunded
  bool get canRefund {
    return this == PaymentStatus.successful;
  }

  /// Create PaymentStatus from string
  static PaymentStatus fromString(String value) {
    final normalizedValue = value.toLowerCase();
    switch (normalizedValue) {
      case 'successful':
      case 'success':
      case 'completed':
        return PaymentStatus.successful;
      case 'failed':
      case 'failure':
        return PaymentStatus.failed;
      case 'pending':
      case 'processing':
        return PaymentStatus.pending;
      case 'refunded':
        return PaymentStatus.refunded;
      case 'voided':
      case 'cancelled':
        return PaymentStatus.voided;
      case 'partiallyrefunded':
      case 'partially_refunded':
        return PaymentStatus.partiallyRefunded;
      default:
        return PaymentStatus.pending;
    }
  }
}