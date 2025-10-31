import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/payment_details.dart';
import '../../../domain/entities/refund.dart';
import '../../../domain/usecases/payments/get_payment_by_id_usecase.dart';
import '../../../domain/usecases/payments/refund_payment_usecase.dart';
import '../../../domain/usecases/payments/void_payment_usecase.dart';
import '../../../domain/usecases/payments/update_payment_status_usecase.dart';
import '../../../domain/repositories/payments_repository.dart';
import 'payment_details_event.dart';
import 'payment_details_state.dart';

class PaymentDetailsBloc
    extends Bloc<PaymentDetailsEvent, PaymentDetailsState> {
  final GetPaymentByIdUseCase getPaymentByIdUseCase;
  final RefundPaymentUseCase refundPaymentUseCase;
  final VoidPaymentUseCase voidPaymentUseCase;
  final UpdatePaymentStatusUseCase updatePaymentStatusUseCase;
  final PaymentsRepository repository;

  String? _currentPaymentId;

  PaymentDetailsBloc({
    required this.getPaymentByIdUseCase,
    required this.refundPaymentUseCase,
    required this.voidPaymentUseCase,
    required this.updatePaymentStatusUseCase,
    required this.repository,
  }) : super(PaymentDetailsInitial()) {
    on<LoadPaymentDetailsEvent>(_onLoadPaymentDetails);
    on<RefreshPaymentDetailsEvent>(_onRefreshPaymentDetails);
    on<RefundPaymentDetailsEvent>(_onRefundPaymentDetails);
    on<VoidPaymentDetailsEvent>(_onVoidPaymentDetails);
    on<UpdatePaymentStatusDetailsEvent>(_onUpdatePaymentStatusDetails);
    on<LoadPaymentActivitiesEvent>(_onLoadPaymentActivities);
    on<LoadRefundHistoryEvent>(_onLoadRefundHistory);
    on<PrintReceiptEvent>(_onPrintReceipt);
    on<SendReceiptEvent>(_onSendReceipt);
    on<DownloadInvoiceEvent>(_onDownloadInvoice);
    on<AddNoteEvent>(_onAddNote);
    on<ResendNotificationEvent>(_onResendNotification);
  }

  Future<void> _onLoadPaymentDetails(
    LoadPaymentDetailsEvent event,
    Emitter<PaymentDetailsState> emit,
  ) async {
    emit(PaymentDetailsLoading());
    _currentPaymentId = event.paymentId;

    // جلب البيانات الأساسية
    final paymentResult = await getPaymentByIdUseCase(
      GetPaymentByIdParams(paymentId: event.paymentId),
    );

    await paymentResult.fold(
      (failure) async {
        emit(PaymentDetailsError(message: failure.message));
      },
      (payment) async {
        // جلب التفاصيل الإضافية
        final detailsResult = await repository.getPaymentDetails(
          paymentId: event.paymentId,
        );

        await detailsResult.fold(
          (failure) async {
            // إذا فشل جلب التفاصيل، عرض البيانات الأساسية فقط
            emit(PaymentDetailsLoaded(
              payment: payment,
              paymentDetails: null,
              refunds: const [],
              activities: const [],
              isRefreshing: false,
            ));
          },
          (details) async {
            // Use the payment from the details if available, otherwise use the one we fetched
            final finalPayment = details.payment;
            emit(PaymentDetailsLoaded(
              payment: finalPayment,
              paymentDetails: details,
              refunds: details.refunds,
              activities: details.activities,
              isRefreshing: false,
            ));
          },
        );
      },
    );
  }

  Future<void> _onRefreshPaymentDetails(
    RefreshPaymentDetailsEvent event,
    Emitter<PaymentDetailsState> emit,
  ) async {
    if (state is PaymentDetailsLoaded && _currentPaymentId != null) {
      final currentState = state as PaymentDetailsLoaded;
      emit(currentState.copyWith(isRefreshing: true));

      add(LoadPaymentDetailsEvent(paymentId: _currentPaymentId!));
    }
  }

  Future<void> _onRefundPaymentDetails(
    RefundPaymentDetailsEvent event,
    Emitter<PaymentDetailsState> emit,
  ) async {
    if (state is PaymentDetailsLoaded) {
      final currentState = state as PaymentDetailsLoaded;

      emit(PaymentDetailsOperationInProgress(
        payment: currentState.payment,
        paymentDetails: currentState.paymentDetails,
        refunds: currentState.refunds,
        activities: currentState.activities,
        operation: 'refund',
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
          emit(PaymentDetailsOperationFailure(
            payment: currentState.payment,
            paymentDetails: currentState.paymentDetails,
            refunds: currentState.refunds,
            activities: currentState.activities,
            message: failure.message,
          ));
        },
        (_) async {
          emit(PaymentDetailsOperationSuccess(
            payment: currentState.payment,
            paymentDetails: currentState.paymentDetails,
            refunds: currentState.refunds,
            activities: currentState.activities,
            message: 'تم استرداد المبلغ بنجاح',
          ));
          // إعادة تحميل التفاصيل
          add(RefreshPaymentDetailsEvent());
        },
      );
    }
  }

  Future<void> _onVoidPaymentDetails(
    VoidPaymentDetailsEvent event,
    Emitter<PaymentDetailsState> emit,
  ) async {
    if (state is PaymentDetailsLoaded) {
      final currentState = state as PaymentDetailsLoaded;

      emit(PaymentDetailsOperationInProgress(
        payment: currentState.payment,
        paymentDetails: currentState.paymentDetails,
        refunds: currentState.refunds,
        activities: currentState.activities,
        operation: 'void',
      ));

      final result = await voidPaymentUseCase(
        VoidPaymentParams(paymentId: event.paymentId),
      );

      await result.fold(
        (failure) async {
          emit(PaymentDetailsOperationFailure(
            payment: currentState.payment,
            paymentDetails: currentState.paymentDetails,
            refunds: currentState.refunds,
            activities: currentState.activities,
            message: failure.message,
          ));
        },
        (_) async {
          emit(PaymentDetailsOperationSuccess(
            payment: currentState.payment,
            paymentDetails: currentState.paymentDetails,
            refunds: currentState.refunds,
            activities: currentState.activities,
            message: 'تم إلغاء الدفعة بنجاح',
          ));
          // إعادة تحميل التفاصيل
          add(RefreshPaymentDetailsEvent());
        },
      );
    }
  }

  Future<void> _onUpdatePaymentStatusDetails(
    UpdatePaymentStatusDetailsEvent event,
    Emitter<PaymentDetailsState> emit,
  ) async {
    if (state is PaymentDetailsLoaded) {
      final currentState = state as PaymentDetailsLoaded;

      emit(PaymentDetailsOperationInProgress(
        payment: currentState.payment,
        paymentDetails: currentState.paymentDetails,
        refunds: currentState.refunds,
        activities: currentState.activities,
        operation: 'updateStatus',
      ));

      final result = await updatePaymentStatusUseCase(
        UpdatePaymentStatusParams(
          paymentId: event.paymentId,
          newStatus: event.newStatus,
        ),
      );

      await result.fold(
        (failure) async {
          emit(PaymentDetailsOperationFailure(
            payment: currentState.payment,
            paymentDetails: currentState.paymentDetails,
            refunds: currentState.refunds,
            activities: currentState.activities,
            message: failure.message,
          ));
        },
        (_) async {
          emit(PaymentDetailsOperationSuccess(
            payment: currentState.payment,
            paymentDetails: currentState.paymentDetails,
            refunds: currentState.refunds,
            activities: currentState.activities,
            message: 'تم تحديث حالة الدفعة بنجاح',
          ));
          // إعادة تحميل التفاصيل
          add(RefreshPaymentDetailsEvent());
        },
      );
    }
  }

  Future<void> _onLoadPaymentActivities(
    LoadPaymentActivitiesEvent event,
    Emitter<PaymentDetailsState> emit,
  ) async {
    // يمكن تنفيذها إذا توفر endpoint للأنشطة
    if (state is PaymentDetailsLoaded) {
      final currentState = state as PaymentDetailsLoaded;
      // جلب الأنشطة من الخادم إذا لزم الأمر
      emit(currentState);
    }
  }

  Future<void> _onLoadRefundHistory(
    LoadRefundHistoryEvent event,
    Emitter<PaymentDetailsState> emit,
  ) async {
    // يمكن تنفيذها إذا توفر endpoint لتاريخ الاستردادات
    if (state is PaymentDetailsLoaded) {
      final currentState = state as PaymentDetailsLoaded;
      // جلب تاريخ الاستردادات من الخادم
      emit(currentState);
    }
  }

  Future<void> _onPrintReceipt(
    PrintReceiptEvent event,
    Emitter<PaymentDetailsState> emit,
  ) async {
    if (state is PaymentDetailsLoaded) {
      final currentState = state as PaymentDetailsLoaded;
      emit(PaymentDetailsPrinting(
        payment: currentState.payment,
        paymentDetails: currentState.paymentDetails,
        refunds: currentState.refunds,
        activities: currentState.activities,
      ));
      // تنفيذ منطق الطباعة
      await Future.delayed(const Duration(seconds: 2));
      emit(currentState);
    }
  }

  Future<void> _onSendReceipt(
    SendReceiptEvent event,
    Emitter<PaymentDetailsState> emit,
  ) async {
    if (state is PaymentDetailsLoaded) {
      final currentState = state as PaymentDetailsLoaded;
      emit(PaymentDetailsSending(
        payment: currentState.payment,
        paymentDetails: currentState.paymentDetails,
        refunds: currentState.refunds,
        activities: currentState.activities,
        recipient: event.email ?? event.phone ?? '',
      ));
      // تنفيذ منطق الإرسال
      await Future.delayed(const Duration(seconds: 2));
      emit(PaymentDetailsOperationSuccess(
        payment: currentState.payment,
        paymentDetails: currentState.paymentDetails,
        refunds: currentState.refunds,
        activities: currentState.activities,
        message: 'تم إرسال الإيصال بنجاح',
      ));
      await Future.delayed(const Duration(seconds: 2));
      emit(currentState);
    }
  }

  Future<void> _onDownloadInvoice(
    DownloadInvoiceEvent event,
    Emitter<PaymentDetailsState> emit,
  ) async {
    if (state is PaymentDetailsLoaded) {
      final currentState = state as PaymentDetailsLoaded;
      emit(PaymentDetailsDownloading(
        payment: currentState.payment,
        paymentDetails: currentState.paymentDetails,
        refunds: currentState.refunds,
        activities: currentState.activities,
      ));
      // تنفيذ منطق التحميل
      await Future.delayed(const Duration(seconds: 2));
      emit(PaymentDetailsOperationSuccess(
        payment: currentState.payment,
        paymentDetails: currentState.paymentDetails,
        refunds: currentState.refunds,
        activities: currentState.activities,
        message: 'تم تحميل الفاتورة بنجاح',
      ));
      await Future.delayed(const Duration(seconds: 2));
      emit(currentState);
    }
  }

  Future<void> _onAddNote(
    AddNoteEvent event,
    Emitter<PaymentDetailsState> emit,
  ) async {
    if (state is PaymentDetailsLoaded) {
      final currentState = state as PaymentDetailsLoaded;
      // إضافة الملاحظة
      emit(PaymentDetailsOperationSuccess(
        payment: currentState.payment,
        paymentDetails: currentState.paymentDetails,
        refunds: currentState.refunds,
        activities: currentState.activities,
        message: 'تمت إضافة الملاحظة بنجاح',
      ));
      await Future.delayed(const Duration(seconds: 2));
      emit(currentState);
    }
  }

  Future<void> _onResendNotification(
    ResendNotificationEvent event,
    Emitter<PaymentDetailsState> emit,
  ) async {
    if (state is PaymentDetailsLoaded) {
      final currentState = state as PaymentDetailsLoaded;
      emit(PaymentDetailsSending(
        payment: currentState.payment,
        paymentDetails: currentState.paymentDetails,
        refunds: currentState.refunds,
        activities: currentState.activities,
        recipient: '',
      ));
      // إعادة إرسال الإشعار
      await Future.delayed(const Duration(seconds: 2));
      emit(PaymentDetailsOperationSuccess(
        payment: currentState.payment,
        paymentDetails: currentState.paymentDetails,
        refunds: currentState.refunds,
        activities: currentState.activities,
        message: 'تم إعادة إرسال الإشعار بنجاح',
      ));
      await Future.delayed(const Duration(seconds: 2));
      emit(currentState);
    }
  }
}
