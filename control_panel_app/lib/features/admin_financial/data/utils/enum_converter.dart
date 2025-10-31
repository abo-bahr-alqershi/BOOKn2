// lib/features/admin_financial/data/utils/enum_converter.dart

/// 🔄 محول Enums للتوافق مع الباك اند
/// Enum Converter for Backend Compatibility
class EnumConverter {
  
  /// تحويل قيمة enum من الباك اند (يبدأ من 1) إلى Flutter (يبدأ من 0)
  /// Convert enum value from backend (starts at 1) to Flutter (starts at 0)
  static int fromBackendEnum(int backendValue) {
    return backendValue - 1;
  }
  
  /// تحويل قيمة enum من Flutter (يبدأ من 0) إلى الباك اند (يبدأ من 1)
  /// Convert enum value from Flutter (starts at 0) to backend (starts at 1)
  static int toBackendEnum(int flutterValue) {
    return flutterValue + 1;
  }
  
  /// تحويل قيمة enum آمن مع التحقق من النطاق
  /// Safe enum conversion with range checking
  static T? parseEnumSafe<T>(
    dynamic value,
    List<T> values,
    Map<String, T> stringMap,
    T defaultValue,
  ) {
    if (value == null) return defaultValue;
    
    // Handle integer values (backend enum indices start at 1)
    if (value is int) {
      final index = fromBackendEnum(value);
      if (index >= 0 && index < values.length) {
        return values[index];
      }
    }
    
    // Handle string values
    if (value is String) {
      // Try to parse as number first
      final intValue = int.tryParse(value);
      if (intValue != null) {
        return parseEnumSafe(intValue, values, stringMap, defaultValue);
      }
      
      // Try exact match
      if (stringMap.containsKey(value)) {
        return stringMap[value]!;
      }
      
      // Try case-insensitive match
      final lowerValue = value.toLowerCase();
      for (final entry in stringMap.entries) {
        if (entry.key.toLowerCase() == lowerValue) {
          return entry.value;
        }
      }
    }
    
    return defaultValue;
  }
  
  /// التحقق من صحة البيانات المالية
  /// Validate financial data
  static Map<String, dynamic> validateAndFixFinancialData(Map<String, dynamic> data) {
    final fixed = Map<String, dynamic>.from(data);
    
    // Fix field names
    final fieldMappings = {
      'taxAmount': 'tax',
      'discountAmount': 'discount',
      'documentPath': null, // Remove this field
    };
    
    for (final mapping in fieldMappings.entries) {
      if (fixed.containsKey(mapping.key)) {
        if (mapping.value != null) {
          fixed[mapping.value!] = fixed[mapping.key];
        }
        fixed.remove(mapping.key);
      }
    }
    
    // Fix enum values
    if (fixed['entryType'] is String) {
      fixed['entryType'] = _getJournalEntryTypeValue(fixed['entryType']);
    }
    
    if (fixed['transactionType'] is String) {
      fixed['transactionType'] = _getTransactionTypeValue(fixed['transactionType']);
    }
    
    if (fixed['status'] is String) {
      fixed['status'] = _getTransactionStatusValue(fixed['status']);
    }
    
    return fixed;
  }
  
  static int _getJournalEntryTypeValue(String value) {
    final map = {
      'GeneralJournal': 1,
      'Sales': 2,
      'Purchases': 3,
      'CashReceipts': 4,
      'CashPayments': 5,
      'Adjustment': 6,
      'Closing': 7,
      'Opening': 8,
      'Reversal': 9,
    };
    return map[value] ?? 1;
  }
  
  static int _getTransactionTypeValue(String value) {
    final map = {
      'NewBooking': 1,
      'AdvancePayment': 2,
      'FinalPayment': 3,
      'BookingCancellation': 4,
      'Refund': 5,
      'PlatformCommission': 6,
      'OwnerPayout': 7,
      'ServiceFee': 8,
      'Tax': 9,
      'Discount': 10,
      'LateFee': 11,
      'Compensation': 12,
      'SecurityDeposit': 13,
      'SecurityDepositRefund': 14,
      'OperationalExpense': 15,
      'OtherIncome': 16,
      'InterAccountTransfer': 17,
      'Adjustment': 18,
      'OpeningBalance': 19,
      'AgentCommission': 20,
    };
    return map[value] ?? 18; // Default to Adjustment
  }
  
  static int _getTransactionStatusValue(String value) {
    final map = {
      'Draft': 1,
      'Pending': 2,
      'Posted': 3,
      'Approved': 4,
      'Rejected': 5,
      'Cancelled': 6,
      'Reversed': 7,
    };
    return map[value] ?? 1; // Default to Draft
  }
}
