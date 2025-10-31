/// features/payment/presentation/bloc/payment_state.dart

import 'package:equatable/equatable.dart';
import '../../../../core/enums/payment_method_enum.dart';
import '../../domain/entities/transaction.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {
  const PaymentInitial();
}

class PaymentProcessing extends PaymentState {
  const PaymentProcessing();
}

class PaymentSuccess extends PaymentState {
  final Transaction transaction;

  const PaymentSuccess({required this.transaction});

  @override
  List<Object> get props => [transaction];
}

class PaymentError extends PaymentState {
  final String message;

  const PaymentError({required this.message});

  @override
  List<Object> get props => [message];
}

class PaymentMethodSelected extends PaymentState {
  final PaymentMethod paymentMethod;
  final bool requiresDetails;

  const PaymentMethodSelected({
    required this.paymentMethod,
    required this.requiresDetails,
  });

  @override
  List<Object> get props => [paymentMethod, requiresDetails];
}

class PaymentDetailsValid extends PaymentState {
  const PaymentDetailsValid();
}

class PaymentDetailsInvalid extends PaymentState {
  final Map<String, String> errors;

  const PaymentDetailsInvalid({required this.errors});

  @override
  List<Object> get props => [errors];
}

class PaymentHistoryLoading extends PaymentState {
  const PaymentHistoryLoading();
}

class PaymentHistoryLoaded extends PaymentState {
  final List<Transaction> transactions;
  final bool hasMore;
  final int currentPage;
  final int totalCount;
  final bool isLoadingMore;

  const PaymentHistoryLoaded({
    required this.transactions,
    required this.hasMore,
    required this.currentPage,
    required this.totalCount,
    required this.isLoadingMore,
  });

  PaymentHistoryLoaded copyWith({
    List<Transaction>? transactions,
    bool? hasMore,
    int? currentPage,
    int? totalCount,
    bool? isLoadingMore,
  }) {
    return PaymentHistoryLoaded(
      transactions: transactions ?? this.transactions,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object> get props => [
        transactions,
        hasMore,
        currentPage,
        totalCount,
        isLoadingMore,
      ];
}

class PaymentRefundSuccess extends PaymentState {
  final String message;

  const PaymentRefundSuccess({required this.message});

  @override
  List<Object> get props => [message];
}