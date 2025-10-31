// lib/features/admin_financial/data/models/financial_transaction_model.dart

import '../../domain/entities/financial_transaction.dart';
import 'chart_of_account_model.dart';

/// 💳 نموذج القيود المحاسبية
class FinancialTransactionModel extends FinancialTransaction {
  const FinancialTransactionModel({
    required super.id,
    required super.transactionNumber,
    required super.transactionDate,
    required super.entryType,
    required super.transactionType,
    required super.debitAccountId,
    required super.creditAccountId,
    super.debitAccount,
    super.creditAccount,
    required super.amount,
    super.currency,
    super.exchangeRate,
    required super.baseAmount,
    required super.description,
    super.narration,
    super.referenceNumber,
    super.documentType,
    super.bookingId,
    super.paymentId,
    super.firstPartyUserId,
    super.secondPartyUserId,
    super.propertyId,
    super.unitId,
    super.status,
    super.isPosted,
    super.postingDate,
    super.approvedBy,
    super.approvedAt,
    super.rejectedBy,
    super.rejectedAt,
    super.rejectionReason,
    required super.fiscalYear,
    required super.fiscalPeriod,
    super.tax,
    super.taxPercentage,
    super.commission,
    super.commissionPercentage,
    super.discount,
    super.discountPercentage,
    super.netAmount,
    super.journalId,
    super.batchNumber,
    super.attachmentsJson,
    super.notes,
    super.tags,
    super.costCenter,
    super.project,
    super.department,
    super.isReversed,
    super.reverseTransactionId,
    super.cancellationReason,
    super.cancelledAt,
    super.cancelledBy,
    required super.createdBy,
    required super.createdAt,
    super.updatedBy,
    super.updatedAt,
    super.isAutomatic,
    super.automaticSource,
  });

  factory FinancialTransactionModel.fromJson(Map<String, dynamic> json) {
    return FinancialTransactionModel(
      id: json['id']?.toString() ?? '',
      transactionNumber: json['transactionNumber']?.toString() ?? '',
      transactionDate: json['transactionDate'] != null 
          ? DateTime.parse(json['transactionDate'])
          : DateTime.now(),
      entryType: _parseJournalEntryType(json['entryType']),
      transactionType: _parseTransactionType(json['transactionType']),
      debitAccountId: json['debitAccountId']?.toString() ?? '',
      creditAccountId: json['creditAccountId']?.toString() ?? '',
      debitAccount: json['debitAccount'] != null
          ? ChartOfAccountModel.fromJson(json['debitAccount'])
          : null,
      creditAccount: json['creditAccount'] != null
          ? ChartOfAccountModel.fromJson(json['creditAccount'])
          : null,
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'YER',
      exchangeRate: (json['exchangeRate'] ?? 1).toDouble(),
      baseAmount: (json['baseAmount'] ?? 0).toDouble(),
      description: json['description']?.toString() ?? '',
      narration: json['narration']?.toString(),
      referenceNumber: json['referenceNumber']?.toString(),
      documentType: json['documentType']?.toString(),
      bookingId: json['bookingId']?.toString(),
      paymentId: json['paymentId']?.toString(),
      firstPartyUserId: json['firstPartyUserId']?.toString(),
      secondPartyUserId: json['secondPartyUserId']?.toString(),
      propertyId: json['propertyId']?.toString(),
      unitId: json['unitId']?.toString(),
      status: _parseTransactionStatus(json['status']),
      isPosted: json['isPosted'] ?? false,
      postingDate: json['postingDate'] != null 
          ? DateTime.parse(json['postingDate']) 
          : null,
      approvedBy: json['approvedBy']?.toString(),
      approvedAt: json['approvedAt'] != null 
          ? DateTime.parse(json['approvedAt']) 
          : null,
      rejectedBy: json['rejectedBy']?.toString(),
      rejectedAt: json['rejectedAt'] != null 
          ? DateTime.parse(json['rejectedAt']) 
          : null,
      rejectionReason: json['rejectionReason']?.toString(),
      fiscalYear: json['fiscalYear'] ?? DateTime.now().year,
      fiscalPeriod: json['fiscalPeriod'] ?? DateTime.now().month,
      tax: json['tax']?.toDouble(),
      taxPercentage: json['taxPercentage']?.toDouble(),
      commission: json['commission']?.toDouble(),
      commissionPercentage: json['commissionPercentage']?.toDouble(),
      discount: json['discount']?.toDouble(),
      discountPercentage: json['discountPercentage']?.toDouble(),
      netAmount: json['netAmount']?.toDouble() ?? 0,
      journalId: json['journalId']?.toString(),
      batchNumber: json['batchNumber']?.toString(),
      attachmentsJson: json['attachmentsJson']?.toString(),
      notes: json['notes']?.toString(),
      tags: json['tags']?.toString(),
      costCenter: json['costCenter']?.toString(),
      project: json['project']?.toString(),
      department: json['department']?.toString(),
      isReversed: json['isReversed'] ?? false,
      reverseTransactionId: json['reverseTransactionId']?.toString(),
      cancellationReason: json['cancellationReason']?.toString(),
      cancelledAt: json['cancelledAt'] != null 
          ? DateTime.parse(json['cancelledAt']) 
          : null,
      cancelledBy: json['cancelledBy']?.toString(),
      createdBy: json['createdBy']?.toString() ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedBy: json['updatedBy']?.toString(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
      isAutomatic: json['isAutomatic'] ?? false,
      automaticSource: json['automaticSource']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionNumber': transactionNumber,
      'transactionDate': transactionDate.toIso8601String(),
      'entryType': entryType.index + 1, // Backend enums start at 1
      'transactionType': transactionType.index + 1, // Backend enums start at 1
      'debitAccountId': debitAccountId,
      'creditAccountId': creditAccountId,
      'amount': amount,
      'currency': currency,
      'exchangeRate': exchangeRate,
      'baseAmount': baseAmount,
      'description': description,
      'narration': narration,
      'referenceNumber': referenceNumber,
      'documentType': documentType,
      'bookingId': bookingId,
      'paymentId': paymentId,
      'firstPartyUserId': firstPartyUserId,
      'secondPartyUserId': secondPartyUserId,
      'propertyId': propertyId,
      'unitId': unitId,
      'status': status.index + 1, // Backend enums start at 1
      'isPosted': isPosted,
      'postingDate': postingDate?.toIso8601String(),
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectedBy': rejectedBy,
      'rejectedAt': rejectedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'fiscalYear': fiscalYear,
      'fiscalPeriod': fiscalPeriod,
      'tax': tax,
      'taxPercentage': taxPercentage,
      'commission': commission,
      'commissionPercentage': commissionPercentage,
      'discount': discount,
      'discountPercentage': discountPercentage,
      'netAmount': netAmount,
      'journalId': journalId,
      'batchNumber': batchNumber,
      'attachmentsJson': attachmentsJson,
      'notes': notes,
      'tags': tags,
      'costCenter': costCenter,
      'project': project,
      'department': department,
      'isReversed': isReversed,
      'reverseTransactionId': reverseTransactionId,
      'cancellationReason': cancellationReason,
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancelledBy': cancelledBy,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedBy': updatedBy,
      'updatedAt': updatedAt?.toIso8601String(),
      'isAutomatic': isAutomatic,
      'automaticSource': automaticSource,
    };
  }

  static JournalEntryType _parseJournalEntryType(dynamic value) {
    if (value == null) return JournalEntryType.generalJournal;
    
    // Handle integer values (backend enum indices start at 1)
    if (value is int) {
      final index = value - 1; // Backend starts at 1, Flutter at 0
      if (index >= 0 && index < JournalEntryType.values.length) {
        return JournalEntryType.values[index];
      }
    }
    
    // Handle string values
    if (value is String) {
      // Try to parse as number first
      final intValue = int.tryParse(value);
      if (intValue != null) {
        return _parseJournalEntryType(intValue);
      }
      
      // Map backend string names to Flutter enum values (order matches backend now)
      final enumMap = <String, JournalEntryType>{
        'GeneralJournal': JournalEntryType.generalJournal,
        'Sales': JournalEntryType.sales,
        'Purchases': JournalEntryType.purchases,
        'CashReceipts': JournalEntryType.cashReceipts,
        'CashPayments': JournalEntryType.cashPayments,
        'Adjustment': JournalEntryType.adjustment,
        'Closing': JournalEntryType.closing,
        'Opening': JournalEntryType.opening,
        'Reversal': JournalEntryType.reversal,
      };
      
      // Try exact match
      if (enumMap.containsKey(value)) {
        return enumMap[value]!;
      }
      
      // Try case-insensitive match
      final lowerValue = value.toLowerCase();
      for (final entry in enumMap.entries) {
        if (entry.key.toLowerCase() == lowerValue) {
          return entry.value;
        }
      }
    }
    
    return JournalEntryType.generalJournal;
  }

  static TransactionType _parseTransactionType(dynamic value) {
    if (value == null) return TransactionType.adjustment;
    
    // Handle integer values (backend enum indices start at 1)
    if (value is int) {
      final index = value - 1; // Backend starts at 1, Flutter at 0
      if (index >= 0 && index < TransactionType.values.length) {
        return TransactionType.values[index];
      }
    }
    
    // Handle string values
    if (value is String) {
      // Try to parse as number first
      final intValue = int.tryParse(value);
      if (intValue != null) {
        return _parseTransactionType(intValue);
      }
      
      // Map backend string names to Flutter enum values
      final enumMap = <String, TransactionType>{
        'NewBooking': TransactionType.newBooking,
        'AdvancePayment': TransactionType.advancePayment,
        'FinalPayment': TransactionType.finalPayment,
        'BookingCancellation': TransactionType.bookingCancellation,
        'Refund': TransactionType.refund,
        'PlatformCommission': TransactionType.platformCommission,
        'OwnerPayout': TransactionType.ownerPayout,
        'ServiceFee': TransactionType.serviceFee,
        'Tax': TransactionType.tax,
        'Discount': TransactionType.discount,
        'LateFee': TransactionType.lateFee,
        'Compensation': TransactionType.compensation,
        'SecurityDeposit': TransactionType.securityDeposit,
        'SecurityDepositRefund': TransactionType.securityDepositRefund,
        'OperationalExpense': TransactionType.operationalExpense,
        'OtherIncome': TransactionType.otherIncome,
        'InterAccountTransfer': TransactionType.interAccountTransfer,
        'Adjustment': TransactionType.adjustment,
        'OpeningBalance': TransactionType.openingBalance,
        'AgentCommission': TransactionType.agentCommission,
      };
      
      // Try exact match
      if (enumMap.containsKey(value)) {
        return enumMap[value]!;
      }
      
      // Try case-insensitive match
      final lowerValue = value.toLowerCase();
      for (final entry in enumMap.entries) {
        if (entry.key.toLowerCase() == lowerValue) {
          return entry.value;
        }
      }
    }
    
    return TransactionType.adjustment;
  }

  static TransactionStatus _parseTransactionStatus(dynamic value) {
    if (value == null) return TransactionStatus.draft;
    
    // Handle integer values (backend enum indices start at 1)
    if (value is int) {
      final index = value - 1; // Backend starts at 1, Flutter at 0
      if (index >= 0 && index < TransactionStatus.values.length) {
        return TransactionStatus.values[index];
      }
    }
    
    // Handle string values
    if (value is String) {
      // Try to parse as number first
      final intValue = int.tryParse(value);
      if (intValue != null) {
        return _parseTransactionStatus(intValue);
      }
      
      // Map backend string names to Flutter enum values
      final enumMap = <String, TransactionStatus>{
        'Draft': TransactionStatus.draft,
        'Pending': TransactionStatus.pending,
        'Posted': TransactionStatus.posted,
        'Approved': TransactionStatus.approved,
        'Rejected': TransactionStatus.rejected,
        'Cancelled': TransactionStatus.cancelled,
        'Reversed': TransactionStatus.reversed,
      };
      
      // Try exact match
      if (enumMap.containsKey(value)) {
        return enumMap[value]!;
      }
      
      // Try case-insensitive match
      final lowerValue = value.toLowerCase();
      for (final entry in enumMap.entries) {
        if (entry.key.toLowerCase() == lowerValue) {
          return entry.value;
        }
      }
    }
    
    return TransactionStatus.draft;
  }
}
