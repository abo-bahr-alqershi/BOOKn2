/// features/payment/presentation/bloc/payment_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/enums/payment_method_enum.dart';
import '../../domain/usecases/process_payment_usecase.dart';
import '../../domain/usecases/get_payment_history_usecase.dart';
import 'payment_event.dart';
import 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final ProcessPaymentUseCase processPaymentUseCase;
  final GetPaymentHistoryUseCase getPaymentHistoryUseCase;

  PaymentBloc({
    required this.processPaymentUseCase,
    required this.getPaymentHistoryUseCase,
  }) : super(const PaymentInitial()) {
    on<ProcessPaymentEvent>(_onProcessPayment);
    on<GetPaymentHistoryEvent>(_onGetPaymentHistory);
    on<SelectPaymentMethodEvent>(_onSelectPaymentMethod);
    on<ValidatePaymentDetailsEvent>(_onValidatePaymentDetails);
    on<ResetPaymentStateEvent>(_onResetPaymentState);
    on<RefundPaymentEvent>(_onRefundPayment);
    on<LoadMorePaymentHistoryEvent>(_onLoadMorePaymentHistory);
  }

  Future<void> _onProcessPayment(
    ProcessPaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentProcessing());

    final params = ProcessPaymentParams(
      bookingId: event.bookingId,
      userId: event.userId,
      amount: event.amount,
      paymentMethod: event.paymentMethod.name,
      currency: event.currency,
      paymentDetails: event.paymentDetails,
    );

    final result = await processPaymentUseCase(params);

    result.fold(
      (failure) => emit(PaymentError(message: failure.message)),
      (transaction) => emit(PaymentSuccess(transaction: transaction)),
    );
  }

  Future<void> _onGetPaymentHistory(
    GetPaymentHistoryEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentHistoryLoading());

    final params = GetPaymentHistoryParams(
      userId: event.userId,
      pageNumber: event.pageNumber,
      pageSize: event.pageSize,
      status: event.status,
      paymentMethod: event.paymentMethod,
      fromDate: event.fromDate,
      toDate: event.toDate,
      minAmount: event.minAmount,
      maxAmount: event.maxAmount,
    );

    final result = await getPaymentHistoryUseCase(params);

    result.fold(
      (failure) => emit(PaymentError(message: failure.message)),
      (paginatedTransactions) => emit(PaymentHistoryLoaded(
        transactions: paginatedTransactions.items,
        hasMore: paginatedTransactions.hasNextPage,
        currentPage: paginatedTransactions.pageNumber,
        totalCount: paginatedTransactions.totalCount,
        isLoadingMore: false,
      )),
    );
  }

  Future<void> _onLoadMorePaymentHistory(
    LoadMorePaymentHistoryEvent event,
    Emitter<PaymentState> emit,
  ) async {
    if (state is PaymentHistoryLoaded) {
      final currentState = state as PaymentHistoryLoaded;
      if (currentState.isLoadingMore || !currentState.hasMore) return;

      emit(currentState.copyWith(isLoadingMore: true));

      final params = GetPaymentHistoryParams(
        userId: event.userId,
        pageNumber: currentState.currentPage + 1,
        pageSize: event.pageSize,
        status: event.status,
        paymentMethod: event.paymentMethod,
        fromDate: event.fromDate,
        toDate: event.toDate,
        minAmount: event.minAmount,
        maxAmount: event.maxAmount,
      );

      final result = await getPaymentHistoryUseCase(params);

      result.fold(
        (failure) => emit(PaymentError(message: failure.message)),
        (paginatedTransactions) {
          final updatedTransactions = [
            ...currentState.transactions,
            ...paginatedTransactions.items,
          ];
          emit(PaymentHistoryLoaded(
            transactions: updatedTransactions,
            hasMore: paginatedTransactions.hasNextPage,
            currentPage: paginatedTransactions.pageNumber,
            totalCount: paginatedTransactions.totalCount,
            isLoadingMore: false,
          ));
        },
      );
    }
  }

  void _onSelectPaymentMethod(
    SelectPaymentMethodEvent event,
    Emitter<PaymentState> emit,
  ) {
    emit(PaymentMethodSelected(
      paymentMethod: event.paymentMethod,
      requiresDetails: _requiresAdditionalDetails(event.paymentMethod),
    ));
  }

  void _onValidatePaymentDetails(
    ValidatePaymentDetailsEvent event,
    Emitter<PaymentState> emit,
  ) {
    final errors = <String, String>{};

    if (event.paymentMethod == PaymentMethod.creditCard) {
      if (event.cardNumber?.isEmpty ?? true) {
        errors['cardNumber'] = 'رقم البطاقة مطلوب';
      } else if (!_isValidCardNumber(event.cardNumber!)) {
        errors['cardNumber'] = 'رقم البطاقة غير صالح';
      }

      if (event.cardHolderName?.isEmpty ?? true) {
        errors['cardHolderName'] = 'اسم حامل البطاقة مطلوب';
      }

      if (event.expiryDate?.isEmpty ?? true) {
        errors['expiryDate'] = 'تاريخ الانتهاء مطلوب';
      } else if (!_isValidExpiryDate(event.expiryDate!)) {
        errors['expiryDate'] = 'تاريخ الانتهاء غير صالح';
      }

      if (event.cvv?.isEmpty ?? true) {
        errors['cvv'] = 'رمز CVV مطلوب';
      } else if (!_isValidCVV(event.cvv!)) {
        errors['cvv'] = 'رمز CVV غير صالح';
      }
    } else if (event.paymentMethod.isWallet) {
      if (event.walletNumber?.isEmpty ?? true) {
        errors['walletNumber'] = 'رقم المحفظة مطلوب';
      }
      if (event.walletPin?.isEmpty ?? true) {
        errors['walletPin'] = 'رمز المحفظة مطلوب';
      }
    }

    if (errors.isEmpty) {
      emit(const PaymentDetailsValid());
    } else {
      emit(PaymentDetailsInvalid(errors: errors));
    }
  }

  void _onResetPaymentState(
    ResetPaymentStateEvent event,
    Emitter<PaymentState> emit,
  ) {
    emit(const PaymentInitial());
  }

  Future<void> _onRefundPayment(
    RefundPaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentProcessing());
    
    // Implement refund logic here
    await Future.delayed(const Duration(seconds: 2));
    
    emit(const PaymentRefundSuccess(
      message: 'تم استرداد المبلغ بنجاح',
    ));
  }

  bool _requiresAdditionalDetails(PaymentMethod method) {
    return method == PaymentMethod.creditCard || method.isWallet;
  }

  bool _isValidCardNumber(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(' ', '');
    if (cleanNumber.length < 13 || cleanNumber.length > 19) return false;
    
    // Luhn algorithm for card validation
    int sum = 0;
    bool alternate = false;
    for (int i = cleanNumber.length - 1; i >= 0; i--) {
      int digit = int.tryParse(cleanNumber[i]) ?? -1;
      if (digit < 0) return false;
      
      if (alternate) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  bool _isValidExpiryDate(String expiryDate) {
    final parts = expiryDate.split('/');
    if (parts.length != 2) return false;
    
    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);
    
    if (month == null || year == null) return false;
    if (month < 1 || month > 12) return false;
    
    final now = DateTime.now();
    final expiry = DateTime(2000 + year, month);
    
    return expiry.isAfter(now);
  }

  bool _isValidCVV(String cvv) {
    return cvv.length >= 3 && cvv.length <= 4 && int.tryParse(cvv) != null;
  }
}