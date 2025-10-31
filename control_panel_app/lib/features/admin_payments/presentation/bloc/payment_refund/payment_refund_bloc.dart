import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/money_model.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/refund.dart';
import '../../../domain/usecases/payments/refund_payment_usecase.dart';
import '../../../domain/usecases/payments/get_payment_by_id_usecase.dart';
import '../../../domain/repositories/payments_repository.dart';
import 'payment_refund_event.dart';
import 'payment_refund_state.dart';

class PaymentRefundBloc extends Bloc<PaymentRefundEvent, PaymentRefundState> {
  final RefundPaymentUseCase refundPaymentUseCase;
  final GetPaymentByIdUseCase getPaymentByIdUseCase;
  final PaymentsRepository repository;

  Payment? _currentPayment;

  PaymentRefundBloc({
    required this.refundPaymentUseCase,
    required this.getPaymentByIdUseCase,
    required this.repository,
  }) : super(PaymentRefundInitial()) {
    on<InitializeRefundEvent>(_onInitializeRefund);
    on<CalculateRefundAmountEvent>(_onCalculateRefundAmount);
    on<ValidateRefundEvent>(_onValidateRefund);
    on<ProcessRefundEvent>(_onProcessRefund);
    on<ChangeRefundTypeEvent>(_onChangeRefundType);
    on<UpdateRefundReasonEvent>(_onUpdateRefundReason);
    on<LoadRefundHistoryEvent>(_onLoadRefundHistory);
    on<CancelRefundEvent>(_onCancelRefund);
    on<RetryRefundEvent>(_onRetryRefund);
  }

  Future<void> _onInitializeRefund(
    InitializeRefundEvent event,
    Emitter<PaymentRefundState> emit,
  ) async {
    emit(PaymentRefundLoading());

    final result = await getPaymentByIdUseCase(
      GetPaymentByIdParams(paymentId: event.paymentId),
    );

    await result.fold(
      (failure) async {
        emit(PaymentRefundError(message: failure.message));
      },
      (payment) async {
        _currentPayment = payment;

        // جلب تاريخ الاستردادات
        final detailsResult = await repository.getPaymentDetails(
          paymentId: event.paymentId,
        );

        final refundHistory = detailsResult.fold(
          (_) => <Refund>[],
          (details) => details.refunds,
        );

        // حساب المبلغ المتاح للاسترداد
        final totalRefunded = refundHistory
            .where((r) => r.status == RefundStatus.completed)
            .fold(0.0, (sum, refund) => sum + refund.amount.amount);

        final availableAmount = payment.amount.amount - totalRefunded;

        emit(PaymentRefundReady(
          payment: payment,
          availableAmount: MoneyModel(
            amount: availableAmount,
            currency: payment.amount.currency,
            formattedAmount:
                '${payment.amount.currency} ${availableAmount.toStringAsFixed(2)}',
          ),
          refundHistory: refundHistory,
          refundType: RefundType.full,
          refundAmount: null,
          refundReason: '',
          canRefund: payment.canRefund && availableAmount > 0,
        ));
      },
    );
  }

  Future<void> _onCalculateRefundAmount(
    CalculateRefundAmountEvent event,
    Emitter<PaymentRefundState> emit,
  ) async {
    if (state is PaymentRefundReady) {
      final currentState = state as PaymentRefundReady;

      Money calculatedAmount;
      if (event.refundType == RefundType.full) {
        calculatedAmount = currentState.availableAmount;
      } else {
        calculatedAmount = event.customAmount ?? currentState.availableAmount;
      }

      emit(currentState.copyWith(
        refundType: event.refundType,
        refundAmount: calculatedAmount,
      ));
    }
  }

  Future<void> _onValidateRefund(
    ValidateRefundEvent event,
    Emitter<PaymentRefundState> emit,
  ) async {
    if (state is PaymentRefundReady) {
      final currentState = state as PaymentRefundReady;

      // التحقق من صحة البيانات
      final errors = <String>[];

      if (currentState.refundAmount == null ||
          currentState.refundAmount!.amount <= 0) {
        errors.add('يجب تحديد مبلغ الاسترداد');
      }

      if (currentState.refundAmount != null &&
          currentState.refundAmount!.amount >
              currentState.availableAmount.amount) {
        errors.add('مبلغ الاسترداد أكبر من المبلغ المتاح');
      }

      if (currentState.refundReason.isEmpty) {
        errors.add('يجب إدخال سبب الاسترداد');
      }

      if (errors.isNotEmpty) {
        emit(PaymentRefundValidationError(
          payment: currentState.payment,
          availableAmount: currentState.availableAmount,
          refundHistory: currentState.refundHistory,
          errors: errors,
        ));
      } else {
        emit(PaymentRefundValidated(
          payment: currentState.payment,
          availableAmount: currentState.availableAmount,
          refundHistory: currentState.refundHistory,
          refundAmount: currentState.refundAmount!,
          refundReason: currentState.refundReason,
          refundType: currentState.refundType,
        ));
      }
    }
  }

  Future<void> _onProcessRefund(
    ProcessRefundEvent event,
    Emitter<PaymentRefundState> emit,
  ) async {
    if (state is PaymentRefundReady || state is PaymentRefundValidated) {
      final currentState = state as dynamic;

      emit(PaymentRefundProcessing(
        payment: currentState.payment,
        refundAmount: event.refundAmount,
        refundReason: event.refundReason,
      ));

      final result = await refundPaymentUseCase(
        RefundPaymentParams(
          paymentId: event.paymentId,
          refundAmount: event.refundAmount,
          refundReason: event.refundReason,
        ),
      );

      await result.fold(
        (failure) async {
          emit(PaymentRefundFailure(
            payment: currentState.payment,
            message: failure.message,
            canRetry: true,
          ));
        },
        (_) async {
          emit(PaymentRefundSuccess(
            payment: currentState.payment,
            refundAmount: event.refundAmount,
            message: 'تم استرداد المبلغ بنجاح',
            refundId: DateTime.now().millisecondsSinceEpoch.toString(),
          ));
        },
      );
    }
  }

  Future<void> _onChangeRefundType(
    ChangeRefundTypeEvent event,
    Emitter<PaymentRefundState> emit,
  ) async {
    if (state is PaymentRefundReady) {
      final currentState = state as PaymentRefundReady;

      Money? refundAmount;
      if (event.refundType == RefundType.full) {
        refundAmount = currentState.availableAmount;
      } else if (event.refundType == RefundType.partial) {
        refundAmount = null; // سيتم تحديده من قبل المستخدم
      }

      emit(currentState.copyWith(
        refundType: event.refundType,
        refundAmount: refundAmount,
      ));
    }
  }

  Future<void> _onUpdateRefundReason(
    UpdateRefundReasonEvent event,
    Emitter<PaymentRefundState> emit,
  ) async {
    if (state is PaymentRefundReady) {
      final currentState = state as PaymentRefundReady;
      emit(currentState.copyWith(refundReason: event.reason));
    }
  }

  Future<void> _onLoadRefundHistory(
    LoadRefundHistoryEvent event,
    Emitter<PaymentRefundState> emit,
  ) async {
    if (state is PaymentRefundReady) {
      final currentState = state as PaymentRefundReady;

      final detailsResult = await repository.getPaymentDetails(
        paymentId: event.paymentId,
      );

      final refundHistory = detailsResult.fold(
        (_) => currentState.refundHistory,
        (details) => details.refunds,
      );

      emit(currentState.copyWith(refundHistory: refundHistory));
    }
  }

  Future<void> _onCancelRefund(
    CancelRefundEvent event,
    Emitter<PaymentRefundState> emit,
  ) async {
    emit(PaymentRefundCancelled());
  }

  Future<void> _onRetryRefund(
    RetryRefundEvent event,
    Emitter<PaymentRefundState> emit,
  ) async {
    if (_currentPayment != null) {
      add(InitializeRefundEvent(paymentId: _currentPayment!.id));
    }
  }
}
