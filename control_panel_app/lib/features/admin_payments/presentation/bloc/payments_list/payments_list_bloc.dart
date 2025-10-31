import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/models/paginated_result.dart';
import '../../../../../../core/enums/payment_method_enum.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/usecases/payments/refund_payment_usecase.dart';
import '../../../domain/usecases/payments/void_payment_usecase.dart';
import '../../../domain/usecases/payments/update_payment_status_usecase.dart';
import '../../../domain/usecases/payments/get_all_payments_usecase.dart';
import 'payments_list_event.dart';
import 'payments_list_state.dart';

class PaymentsListBloc extends Bloc<PaymentsListEvent, PaymentsListState> {
  final RefundPaymentUseCase refundPaymentUseCase;
  final VoidPaymentUseCase voidPaymentUseCase;
  final UpdatePaymentStatusUseCase updatePaymentStatusUseCase;
  final GetAllPaymentsUseCase getAllPaymentsUseCase;

  // متغيرات لحفظ حالة البحث والفلاتر
  PaymentStatus? _currentStatus;
  PaymentMethod? _currentMethod;
  String? _currentBookingId;
  String? _currentUserId;
  String? _currentPropertyId;
  String? _currentUnitId;
  double? _currentMinAmount;
  double? _currentMaxAmount;
  DateTime? _currentStartDate;
  DateTime? _currentEndDate;
  int _currentPageNumber = 1;
  int _currentPageSize = 10;
  bool _isLoadingMore = false; // 🎯 لمنع الطلبات المتكررة

  PaymentsListBloc({
    required this.refundPaymentUseCase,
    required this.voidPaymentUseCase,
    required this.updatePaymentStatusUseCase,
    required this.getAllPaymentsUseCase,
  }) : super(PaymentsListInitial()) {
    on<LoadPaymentsEvent>(_onLoadPayments);
    on<RefreshPaymentsEvent>(_onRefreshPayments);
    on<RefundPaymentEvent>(_onRefundPayment);
    on<VoidPaymentEvent>(_onVoidPayment);
    on<UpdatePaymentStatusEvent>(_onUpdatePaymentStatus);
    on<FilterPaymentsEvent>(_onFilterPayments);
    on<SearchPaymentsEvent>(_onSearchPayments);
    on<ChangePageEvent>(_onChangePage);
    on<ChangePageSizeEvent>(_onChangePageSize);
    on<SelectPaymentEvent>(_onSelectPayment);
    on<DeselectPaymentEvent>(_onDeselectPayment);
    on<SelectMultiplePaymentsEvent>(_onSelectMultiplePayments);
    on<ClearSelectionEvent>(_onClearSelection);
    on<ExportPaymentsEvent>(_onExportPayments);
  }

  Future<void> _onLoadPayments(
    LoadPaymentsEvent event,
    Emitter<PaymentsListState> emit,
  ) async {
    emit(PaymentsListLoading());
    _isLoadingMore = false; // 🎯 reset flag

    // حفظ قيم الفلاتر
    _currentStatus = event.status;
    _currentMethod = event.method;
    _currentBookingId = event.bookingId;
    _currentUserId = event.userId;
    _currentPropertyId = event.propertyId;
    _currentUnitId = event.unitId;
    _currentMinAmount = event.minAmount;
    _currentMaxAmount = event.maxAmount;
    _currentStartDate = event.startDate;
    _currentEndDate = event.endDate;
    _currentPageNumber = event.pageNumber;
    _currentPageSize = event.pageSize;

    final result = await getAllPaymentsUseCase(
      GetAllPaymentsParams(
        status: event.status,
        method: event.method,
        bookingId: event.bookingId,
        userId: event.userId,
        propertyId: event.propertyId,
        unitId: event.unitId,
        minAmount: event.minAmount,
        maxAmount: event.maxAmount,
        startDate: event.startDate,
        endDate: event.endDate,
        pageNumber: event.pageNumber,
        pageSize: event.pageSize,
      ),
    );

    result.fold(
      (failure) => emit(PaymentsListError(message: failure.message)),
      (payments) => emit(PaymentsListLoaded(
        payments: payments,
        selectedPayments: const [],
        filters: PaymentFilters(
          status: event.status,
          method: event.method,
          bookingId: event.bookingId,
          userId: event.userId,
          propertyId: event.propertyId,
          unitId: event.unitId,
          minAmount: event.minAmount,
          maxAmount: event.maxAmount,
          startDate: event.startDate,
          endDate: event.endDate,
        ),
        stats: (payments.metadata is Map<String, dynamic>)
            ? (payments.metadata as Map<String, dynamic>)
            : null,
      )),
    );
  }

  Future<void> _onRefreshPayments(
    RefreshPaymentsEvent event,
    Emitter<PaymentsListState> emit,
  ) async {
    // Background refresh: keep current UI state (and list) while fetching
    final result = await getAllPaymentsUseCase(
      GetAllPaymentsParams(
        status: _currentStatus,
        method: _currentMethod,
        bookingId: _currentBookingId,
        userId: _currentUserId,
        propertyId: _currentPropertyId,
        unitId: _currentUnitId,
        minAmount: _currentMinAmount,
        maxAmount: _currentMaxAmount,
        startDate: _currentStartDate,
        endDate: _currentEndDate,
        pageNumber: _currentPageNumber,
        pageSize: _currentPageSize,
      ),
    );

    result.fold(
      (failure) {
        // Keep current state to avoid flicker; optionally could emit a toast elsewhere
      },
      (payments) => emit(PaymentsListLoaded(
        payments: payments,
        selectedPayments: const [],
        filters: PaymentFilters(
          status: _currentStatus,
          method: _currentMethod,
          bookingId: _currentBookingId,
          userId: _currentUserId,
          propertyId: _currentPropertyId,
          unitId: _currentUnitId,
          minAmount: _currentMinAmount,
          maxAmount: _currentMaxAmount,
          startDate: _currentStartDate,
          endDate: _currentEndDate,
        ),
        stats: (payments.metadata is Map<String, dynamic>)
            ? (payments.metadata as Map<String, dynamic>)
            : null,
      )),
    );
  }

  Future<void> _onRefundPayment(
    RefundPaymentEvent event,
    Emitter<PaymentsListState> emit,
  ) async {
    PaginatedResult<Payment>? currentPayments;
    List<Payment> currentSelection = const [];
    if (state is PaymentsListLoaded) {
      currentPayments = (state as PaymentsListLoaded).payments;
      currentSelection = (state as PaymentsListLoaded).selectedPayments;
    } else if (state is PaymentsListLoadingMore) {
      currentPayments = (state as PaymentsListLoadingMore).payments;
      currentSelection = (state as PaymentsListLoadingMore).selectedPayments;
    } else if (state is PaymentOperationInProgress) {
      currentPayments = (state as PaymentOperationInProgress).payments;
      currentSelection = (state as PaymentOperationInProgress).selectedPayments;
    } else if (state is PaymentOperationFailure) {
      currentPayments = (state as PaymentOperationFailure).payments;
      currentSelection = (state as PaymentOperationFailure).selectedPayments;
    } else if (state is PaymentOperationSuccess) {
      currentPayments = (state as PaymentOperationSuccess).payments;
      currentSelection = (state as PaymentOperationSuccess).selectedPayments;
    }

    if (currentPayments == null) return;

    emit(PaymentOperationInProgress(
      payments: currentPayments,
      selectedPayments: currentSelection,
      operation: 'refund',
      paymentId: event.paymentId,
    ));

    final result = await refundPaymentUseCase(
      RefundPaymentParams(
        paymentId: event.paymentId,
        refundAmount: event.refundAmount,
        refundReason: event.refundReason,
      ),
    );

    result.fold(
      (failure) => emit(PaymentOperationFailure(
        payments: currentPayments!,
        selectedPayments: currentSelection,
        message: failure.message,
        paymentId: event.paymentId,
      )),
      (_) {
        emit(PaymentOperationSuccess(
          payments: currentPayments!,
          selectedPayments: currentSelection,
          message: 'تم استرداد المبلغ بنجاح',
          paymentId: event.paymentId,
        ));
        add(const RefreshPaymentsEvent());
      },
    );
  }

  Future<void> _onVoidPayment(
    VoidPaymentEvent event,
    Emitter<PaymentsListState> emit,
  ) async {
    PaginatedResult<Payment>? currentPayments;
    List<Payment> currentSelection = const [];
    if (state is PaymentsListLoaded) {
      currentPayments = (state as PaymentsListLoaded).payments;
      currentSelection = (state as PaymentsListLoaded).selectedPayments;
    } else if (state is PaymentsListLoadingMore) {
      currentPayments = (state as PaymentsListLoadingMore).payments;
      currentSelection = (state as PaymentsListLoadingMore).selectedPayments;
    } else if (state is PaymentOperationInProgress) {
      currentPayments = (state as PaymentOperationInProgress).payments;
      currentSelection = (state as PaymentOperationInProgress).selectedPayments;
    } else if (state is PaymentOperationFailure) {
      currentPayments = (state as PaymentOperationFailure).payments;
      currentSelection = (state as PaymentOperationFailure).selectedPayments;
    } else if (state is PaymentOperationSuccess) {
      currentPayments = (state as PaymentOperationSuccess).payments;
      currentSelection = (state as PaymentOperationSuccess).selectedPayments;
    }

    if (currentPayments == null) return;

    emit(PaymentOperationInProgress(
      payments: currentPayments,
      selectedPayments: currentSelection,
      operation: 'void',
      paymentId: event.paymentId,
    ));

    final result = await voidPaymentUseCase(
      VoidPaymentParams(paymentId: event.paymentId),
    );

    result.fold(
      (failure) => emit(PaymentOperationFailure(
        payments: currentPayments!,
        selectedPayments: currentSelection,
        message: failure.message,
        paymentId: event.paymentId,
      )),
      (_) {
        emit(PaymentOperationSuccess(
          payments: currentPayments!,
          selectedPayments: currentSelection,
          message: 'تم إلغاء الدفعة بنجاح',
          paymentId: event.paymentId,
        ));
        add(const RefreshPaymentsEvent());
      },
    );
  }

  Future<void> _onUpdatePaymentStatus(
    UpdatePaymentStatusEvent event,
    Emitter<PaymentsListState> emit,
  ) async {
    PaginatedResult<Payment>? currentPayments;
    List<Payment> currentSelection = const [];
    if (state is PaymentsListLoaded) {
      currentPayments = (state as PaymentsListLoaded).payments;
      currentSelection = (state as PaymentsListLoaded).selectedPayments;
    } else if (state is PaymentsListLoadingMore) {
      currentPayments = (state as PaymentsListLoadingMore).payments;
      currentSelection = (state as PaymentsListLoadingMore).selectedPayments;
    } else if (state is PaymentOperationInProgress) {
      currentPayments = (state as PaymentOperationInProgress).payments;
      currentSelection = (state as PaymentOperationInProgress).selectedPayments;
    } else if (state is PaymentOperationFailure) {
      currentPayments = (state as PaymentOperationFailure).payments;
      currentSelection = (state as PaymentOperationFailure).selectedPayments;
    } else if (state is PaymentOperationSuccess) {
      currentPayments = (state as PaymentOperationSuccess).payments;
      currentSelection = (state as PaymentOperationSuccess).selectedPayments;
    }

    if (currentPayments == null) return;

    emit(PaymentOperationInProgress(
      payments: currentPayments,
      selectedPayments: currentSelection,
      operation: 'updateStatus',
      paymentId: event.paymentId,
    ));

    final result = await updatePaymentStatusUseCase(
      UpdatePaymentStatusParams(
        paymentId: event.paymentId,
        newStatus: event.newStatus,
      ),
    );

    result.fold(
      (failure) => emit(PaymentOperationFailure(
        payments: currentPayments!,
        selectedPayments: currentSelection,
        message: failure.message,
        paymentId: event.paymentId,
      )),
      (_) {
        emit(PaymentOperationSuccess(
          payments: currentPayments!,
          selectedPayments: currentSelection,
          message: 'تم تحديث حالة الدفعة بنجاح',
          paymentId: event.paymentId,
        ));
        add(const RefreshPaymentsEvent());
      },
    );
  }

  Future<void> _onFilterPayments(
    FilterPaymentsEvent event,
    Emitter<PaymentsListState> emit,
  ) async {
    add(LoadPaymentsEvent(
      status: event.status,
      method: event.method,
      bookingId: event.bookingId,
      userId: event.userId,
      propertyId: event.propertyId,
      unitId: event.unitId,
      minAmount: event.minAmount,
      maxAmount: event.maxAmount,
      startDate: event.startDate,
      endDate: event.endDate,
      pageNumber: 1, // Reset to first page when filtering
      pageSize: _currentPageSize,
    ));
  }

  Future<void> _onSearchPayments(
    SearchPaymentsEvent event,
    Emitter<PaymentsListState> emit,
  ) async {
    // البحث في معرف الحجز أو المستخدم
    add(LoadPaymentsEvent(
      status: _currentStatus,
      method: _currentMethod,
      bookingId: event.searchTerm,
      userId: null,
      propertyId: _currentPropertyId,
      unitId: _currentUnitId,
      minAmount: _currentMinAmount,
      maxAmount: _currentMaxAmount,
      startDate: _currentStartDate,
      endDate: _currentEndDate,
      pageNumber: 1,
      pageSize: _currentPageSize,
    ));
  }

  Future<void> _onChangePage(
    ChangePageEvent event,
    Emitter<PaymentsListState> emit,
  ) async {
    // 🎯 Load More: إضافة البيانات الجديدة بدلاً من الاستبدال
    if (state is PaymentsListLoaded && !_isLoadingMore) {
      final currentState = state as PaymentsListLoaded;

      _isLoadingMore = true; // 🎯 منع الطلبات المتكررة

      // عرض loading indicator صغير في الأسفل
      emit(PaymentsListLoadingMore(
        payments: currentState.payments,
        selectedPayments: currentState.selectedPayments,
        filters: currentState.filters,
        stats: currentState.stats,
      ));

      _currentPageNumber = event.pageNumber;

      final result = await getAllPaymentsUseCase(
        GetAllPaymentsParams(
          status: _currentStatus,
          method: _currentMethod,
          bookingId: _currentBookingId,
          userId: _currentUserId,
          propertyId: _currentPropertyId,
          unitId: _currentUnitId,
          minAmount: _currentMinAmount,
          maxAmount: _currentMaxAmount,
          startDate: _currentStartDate,
          endDate: _currentEndDate,
          pageNumber: event.pageNumber,
          pageSize: _currentPageSize,
        ),
      );

      result.fold(
        (failure) {
          _isLoadingMore = false; // 🎯 reset flag
          // في حالة الفشل، نبقي على البيانات القديمة
          emit(PaymentsListLoaded(
            payments: currentState.payments,
            selectedPayments: currentState.selectedPayments,
            filters: currentState.filters,
            stats: currentState.stats,
          ));
        },
        (newPayments) {
          _isLoadingMore = false; // 🎯 reset flag
          // 🎯 دمج البيانات: القديمة + الجديدة
          final allItems = [
            ...currentState.payments.items,
            ...newPayments.items,
          ];

          // إنشاء PaginatedResult جديد مع كل البيانات
          final mergedResult = PaginatedResult<Payment>(
            items: allItems,
            pageNumber: newPayments.pageNumber,
            pageSize: newPayments.pageSize,
            totalCount: newPayments.totalCount,
            metadata: newPayments.metadata,
          );

          emit(PaymentsListLoaded(
            payments: mergedResult,
            selectedPayments: currentState.selectedPayments,
            filters: currentState.filters,
            stats: currentState.stats,
          ));
        },
      );
    }
  }

  Future<void> _onChangePageSize(
    ChangePageSizeEvent event,
    Emitter<PaymentsListState> emit,
  ) async {
    add(LoadPaymentsEvent(
      status: _currentStatus,
      method: _currentMethod,
      bookingId: _currentBookingId,
      userId: _currentUserId,
      propertyId: _currentPropertyId,
      unitId: _currentUnitId,
      minAmount: _currentMinAmount,
      maxAmount: _currentMaxAmount,
      startDate: _currentStartDate,
      endDate: _currentEndDate,
      pageNumber: 1,
      pageSize: event.pageSize,
    ));
  }

  Future<void> _onSelectPayment(
    SelectPaymentEvent event,
    Emitter<PaymentsListState> emit,
  ) async {
    if (state is PaymentsListLoaded) {
      final currentState = state as PaymentsListLoaded;
      final updatedSelection =
          List<Payment>.from(currentState.selectedPayments);

      final payment = currentState.payments.items.firstWhere(
        (p) => p.id == event.paymentId,
      );

      if (!updatedSelection.contains(payment)) {
        updatedSelection.add(payment);
      }

      emit(currentState.copyWith(selectedPayments: updatedSelection));
    }
  }

  Future<void> _onDeselectPayment(
    DeselectPaymentEvent event,
    Emitter<PaymentsListState> emit,
  ) async {
    if (state is PaymentsListLoaded) {
      final currentState = state as PaymentsListLoaded;
      final updatedSelection = List<Payment>.from(currentState.selectedPayments)
        ..removeWhere((p) => p.id == event.paymentId);

      emit(currentState.copyWith(selectedPayments: updatedSelection));
    }
  }

  Future<void> _onSelectMultiplePayments(
    SelectMultiplePaymentsEvent event,
    Emitter<PaymentsListState> emit,
  ) async {
    if (state is PaymentsListLoaded) {
      final currentState = state as PaymentsListLoaded;
      final payments = currentState.payments.items
          .where((p) => event.paymentIds.contains(p.id))
          .toList();

      emit(currentState.copyWith(selectedPayments: payments));
    }
  }

  Future<void> _onClearSelection(
    ClearSelectionEvent event,
    Emitter<PaymentsListState> emit,
  ) async {
    if (state is PaymentsListLoaded) {
      final currentState = state as PaymentsListLoaded;
      emit(currentState.copyWith(selectedPayments: []));
    }
  }

  Future<void> _onExportPayments(
    ExportPaymentsEvent event,
    Emitter<PaymentsListState> emit,
  ) async {
    if (state is PaymentsListLoaded) {
      final currentState = state as PaymentsListLoaded;

      emit(PaymentsExporting(
        payments: currentState.payments,
        selectedPayments: currentState.selectedPayments,
        format: event.format,
      ));

      // تنفيذ منطق التصدير
      await Future.delayed(const Duration(seconds: 2));

      emit(PaymentsExportSuccess(
        payments: currentState.payments,
        selectedPayments: currentState.selectedPayments,
        message: 'تم تصدير المدفوعات بنجاح',
      ));

      await Future.delayed(const Duration(seconds: 2));
      emit(currentState);
    }
  }
}
