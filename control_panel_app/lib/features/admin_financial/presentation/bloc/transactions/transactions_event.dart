// lib/features/admin_financial/presentation/bloc/transactions/transactions_event.dart

part of 'transactions_bloc.dart';

/// 📋 أحداث المعاملات المالية
abstract class TransactionsEvent extends Equatable {
  const TransactionsEvent();

  @override
  List<Object?> get props => [];
}

/// 📥 تحميل المعاملات
class LoadTransactions extends TransactionsEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final TransactionStatus? status;
  final TransactionType? type;
  final int? limit;

  const LoadTransactions({
    this.startDate,
    this.endDate,
    this.status,
    this.type,
    this.limit,
  });

  @override
  List<Object?> get props => [startDate, endDate, status, type, limit];
}

/// 🔍 البحث في المعاملات
class SearchTransactions extends TransactionsEvent {
  final String query;

  const SearchTransactions(this.query);

  @override
  List<Object?> get props => [query];
}

/// 🎯 تصفية المعاملات
class FilterTransactions extends TransactionsEvent {
  final TransactionStatus? status;
  final TransactionType? type;
  final String? accountId;

  const FilterTransactions({
    this.status,
    this.type,
    this.accountId,
  });

  @override
  List<Object?> get props => [status, type, accountId];
}

/// ✅ ترحيل معاملة
class PostTransaction extends TransactionsEvent {
  final String transactionId;

  const PostTransaction(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

/// 🔄 عكس معاملة
class ReverseTransaction extends TransactionsEvent {
  final String transactionId;
  final String reason;

  const ReverseTransaction({
    required this.transactionId,
    required this.reason,
  });

  @override
  List<Object?> get props => [transactionId, reason];
}

/// 📤 ترحيل المعاملات المعلقة
class PostPendingTransactions extends TransactionsEvent {}

/// 📥 تصدير المعاملات
class ExportTransactions extends TransactionsEvent {
  final DateTime startDate;
  final DateTime endDate;
  final String format; // excel, pdf

  const ExportTransactions({
    required this.startDate,
    required this.endDate,
    required this.format,
  });

  @override
  List<Object?> get props => [startDate, endDate, format];
}

/// 🔄 تحديث المعاملات
class RefreshTransactions extends TransactionsEvent {}

class LoadTransactionsByBooking extends TransactionsEvent {
  final String bookingId;

  const LoadTransactionsByBooking({required this.bookingId});

  @override
  List<Object?> get props => [bookingId];
}

class LoadTransactionsByUser extends TransactionsEvent {
  final String userId;

  const LoadTransactionsByUser({required this.userId});

  @override
  List<Object?> get props => [userId];
}
