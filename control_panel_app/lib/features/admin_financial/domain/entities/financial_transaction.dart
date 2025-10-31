// lib/features/admin_financial/domain/entities/financial_transaction.dart

import 'package:equatable/equatable.dart';

import 'chart_of_account.dart';

/// 💳 كيان القيود المحاسبية
class FinancialTransaction extends Equatable {
  final String id;
  final String transactionNumber;
  final DateTime transactionDate;
  final JournalEntryType entryType;
  final TransactionType transactionType;
  final String debitAccountId;
  final String creditAccountId;
  final ChartOfAccount? debitAccount;
  final ChartOfAccount? creditAccount;
  final double amount;
  final String currency;
  final double exchangeRate;
  final double baseAmount;
  final String description;
  final String? narration;
  final String? referenceNumber;
  final String? documentType;
  final String? bookingId;
  final String? paymentId;
  final String? firstPartyUserId;
  final String? secondPartyUserId;
  final String? propertyId;
  final String? unitId;
  final TransactionStatus status;
  final bool isPosted;
  final DateTime? postingDate;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectedBy;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final int fiscalYear;
  final int fiscalPeriod;
  final double? tax;
  final double? taxPercentage;
  final double? commission;
  final double? commissionPercentage;
  final double? discount;
  final double? discountPercentage;
  final double? netAmount;
  final String? journalId;
  final String? batchNumber;
  final String? attachmentsJson;
  final String? notes;
  final String? tags;
  final String? costCenter;
  final String? project;
  final String? department;
  final bool isReversed;
  final String? reverseTransactionId;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final String? cancelledBy;
  final String createdBy;
  final DateTime createdAt;
  final String? updatedBy;
  final DateTime? updatedAt;
  final bool isAutomatic;
  final String? automaticSource;

  const FinancialTransaction({
    required this.id,
    required this.transactionNumber,
    required this.transactionDate,
    required this.entryType,
    required this.transactionType,
    required this.debitAccountId,
    required this.creditAccountId,
    this.debitAccount,
    this.creditAccount,
    required this.amount,
    this.currency = 'YER',
    this.exchangeRate = 1.0,
    required this.baseAmount,
    required this.description,
    this.narration,
    this.referenceNumber,
    this.documentType,
    this.bookingId,
    this.paymentId,
    this.firstPartyUserId,
    this.secondPartyUserId,
    this.propertyId,
    this.unitId,
    this.status = TransactionStatus.draft,
    this.isPosted = false,
    this.postingDate,
    this.approvedBy,
    this.approvedAt,
    this.rejectedBy,
    this.rejectedAt,
    this.rejectionReason,
    required this.fiscalYear,
    required this.fiscalPeriod,
    this.tax,
    this.taxPercentage,
    this.commission,
    this.commissionPercentage,
    this.discount,
    this.discountPercentage,
    this.netAmount,
    this.journalId,
    this.batchNumber,
    this.attachmentsJson,
    this.notes,
    this.tags,
    this.costCenter,
    this.project,
    this.department,
    this.isReversed = false,
    this.reverseTransactionId,
    this.cancellationReason,
    this.cancelledAt,
    this.cancelledBy,
    required this.createdBy,
    required this.createdAt,
    this.updatedBy,
    this.updatedAt,
    this.isAutomatic = false,
    this.automaticSource,
  });

  // 🎯 Helper Methods
  bool get isPending => status == TransactionStatus.pending;
  bool get isApproved => status == TransactionStatus.approved;
  bool get isRejected => status == TransactionStatus.rejected;
  bool get isCancelled => status == TransactionStatus.cancelled;
  bool get canEdit => status == TransactionStatus.draft;
  bool get canPost => status == TransactionStatus.approved && !isPosted;
  bool get canReverse => isPosted && !isReversed;

  // 🎨 Get status color
  String get statusColor {
    switch (status) {
      case TransactionStatus.draft:
        return '#B8C4E6';
      case TransactionStatus.pending:
        return '#FFB800';
      case TransactionStatus.approved:
        return '#00FF88';
      case TransactionStatus.posted:
        return '#4FACFE';
      case TransactionStatus.rejected:
        return '#FF3366';
      case TransactionStatus.cancelled:
        return '#8B95B7';
      case TransactionStatus.reversed:
        return '#9D50FF';
    }
  }

  // 🔢 Get transaction type icon
  String get transactionIcon {
    switch (transactionType) {
      case TransactionType.newBooking:
        return '📝';
      case TransactionType.advancePayment:
        return '💵';
      case TransactionType.finalPayment:
        return '✅';
      case TransactionType.bookingCancellation:
        return '❌';
      case TransactionType.refund:
        return '💸';
      case TransactionType.platformCommission:
        return '💰';
      case TransactionType.ownerPayout:
        return '🏦';
      case TransactionType.serviceFee:
        return '🔧';
      case TransactionType.tax:
        return '📊';
      case TransactionType.discount:
        return '🎯';
      case TransactionType.lateFee:
        return '⏰';
      case TransactionType.compensation:
        return '🔧';
      case TransactionType.securityDeposit:
        return '🔒';
      case TransactionType.securityDepositRefund:
        return '🔓';
      case TransactionType.operationalExpense:
        return '💼';
      case TransactionType.otherIncome:
        return '➕';
      case TransactionType.interAccountTransfer:
        return '🔁';
      case TransactionType.adjustment:
        return '⚖️';
      case TransactionType.openingBalance:
        return '📊';
      case TransactionType.agentCommission:
        return '👤';
    }
  }

  @override
  List<Object?> get props => [
        id,
        transactionNumber,
        transactionDate,
        entryType,
        transactionType,
        debitAccountId,
        creditAccountId,
        amount,
        currency,
        exchangeRate,
        baseAmount,
        description,
        narration,
        referenceNumber,
        documentType,
        bookingId,
        paymentId,
        firstPartyUserId,
        secondPartyUserId,
        propertyId,
        unitId,
        status,
        isPosted,
        postingDate,
        fiscalYear,
        fiscalPeriod,
        commission,
        netAmount,
        isReversed,
        reverseTransactionId,
        createdBy,
        createdAt,
        isAutomatic,
      ];
}

/// 📋 نوع القيد المحاسبي - متوافق مع ترتيب Backend
enum JournalEntryType {
  generalJournal('قيد يومية عام', 'General Journal'),
  sales('قيد مبيعات', 'Sales'),
  purchases('قيد مشتريات', 'Purchases'),
  cashReceipts('قيد مقبوضات', 'Cash Receipts'),
  cashPayments('قيد مدفوعات', 'Cash Payments'),
  adjustment('قيد تسوية', 'Adjustment'),
  closing('قيد إقفال', 'Closing'),
  opening('قيد افتتاحي', 'Opening'),
  reversal('قيد عكسي', 'Reversal');

  final String nameAr;
  final String nameEn;
  const JournalEntryType(this.nameAr, this.nameEn);
}

/// 💰 نوع المعاملة المالية - متوافق مع Backend
enum TransactionType {
  newBooking('حجز جديد', 'New Booking'),
  advancePayment('دفعة مقدمة', 'Advance Payment'),
  finalPayment('دفعة نهائية', 'Final Payment'),
  bookingCancellation('إلغاء حجز', 'Booking Cancellation'),
  refund('استرداد مبلغ', 'Refund'),
  platformCommission('عمولة منصة', 'Platform Commission'),
  ownerPayout('دفعة للمالك', 'Owner Payout'),
  serviceFee('رسوم خدمة', 'Service Fee'),
  tax('ضريبة', 'Tax'),
  discount('خصم', 'Discount'),
  lateFee('غرامة تأخير', 'Late Fee'),
  compensation('تعويض', 'Compensation'),
  securityDeposit('إيداع ضمان', 'Security Deposit'),
  securityDepositRefund('استرداد ضمان', 'Security Deposit Refund'),
  operationalExpense('مصروفات تشغيلية', 'Operational Expense'),
  otherIncome('إيرادات أخرى', 'Other Income'),
  interAccountTransfer('تحويل بين حسابات', 'Inter Account Transfer'),
  adjustment('تسوية', 'Adjustment'),
  openingBalance('رصيد افتتاحي', 'Opening Balance'),
  agentCommission('عمولة وكيل', 'Agent Commission');

  final String nameAr;
  final String nameEn;
  const TransactionType(this.nameAr, this.nameEn);
}

/// 🚦 حالة القيد - متوافق مع Backend
enum TransactionStatus {
  draft('مسودة', 'Draft'),
  pending('معلق', 'Pending'),
  posted('مرحّل', 'Posted'),
  approved('موافق عليه', 'Approved'),
  rejected('مرفوض', 'Rejected'),
  cancelled('ملغي', 'Cancelled'),
  reversed('معكوس', 'Reversed');

  final String nameAr;
  final String nameEn;
  const TransactionStatus(this.nameAr, this.nameEn);
}
