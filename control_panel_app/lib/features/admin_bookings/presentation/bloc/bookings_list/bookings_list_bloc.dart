import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/error/failures.dart';
import '../../../../../../core/models/paginated_result.dart';
import '../../../../../../core/enums/booking_status.dart';
import '../../../domain/entities/booking.dart';
import '../../../domain/usecases/bookings/cancel_booking_usecase.dart';
import '../../../domain/usecases/bookings/update_booking_usecase.dart';
import '../../../domain/usecases/bookings/confirm_booking_usecase.dart';
import '../../../domain/usecases/bookings/get_bookings_by_date_range_usecase.dart';
import '../../../domain/usecases/bookings/check_in_usecase.dart';
import '../../../domain/usecases/bookings/check_out_usecase.dart';
import 'bookings_list_event.dart';
import 'bookings_list_state.dart';

class BookingsListBloc extends Bloc<BookingsListEvent, BookingsListState> {
  final CancelBookingUseCase cancelBookingUseCase;
  final UpdateBookingUseCase updateBookingUseCase;
  final ConfirmBookingUseCase confirmBookingUseCase;
  final GetBookingsByDateRangeUseCase getBookingsByDateRangeUseCase;
  final CheckInUseCase checkInUseCase;
  final CheckOutUseCase checkOutUseCase;

  // متغيرات لحفظ حالة البحث والفلاتر
  DateTime? _currentStartDate;
  DateTime? _currentEndDate;
  String? _currentUserId;
  String? _currentGuestNameOrEmail;
  String? _currentUnitId;
  String? _currentBookingSource;
  int _currentPageNumber = 1;
  int _currentPageSize = 10;
  bool _isLoadingMore = false;

  BookingsListBloc({
    required this.cancelBookingUseCase,
    required this.updateBookingUseCase,
    required this.confirmBookingUseCase,
    required this.getBookingsByDateRangeUseCase,
    required this.checkInUseCase,
    required this.checkOutUseCase,
  }) : super(BookingsListInitial()) {
    on<LoadBookingsEvent>(_onLoadBookings);
    on<RefreshBookingsEvent>(_onRefreshBookings);
    on<CancelBookingEvent>(_onCancelBooking);
    on<UpdateBookingEvent>(_onUpdateBooking);
    on<ConfirmBookingEvent>(_onConfirmBooking);
    on<CheckInBookingEvent>(_onCheckInBooking);
    on<CheckOutBookingEvent>(_onCheckOutBooking);
    on<FilterBookingsEvent>(_onFilterBookings);
    on<SearchBookingsEvent>(_onSearchBookings);
    on<ChangePageEvent>(_onChangePage);
    on<ChangePageSizeEvent>(_onChangePageSize);
    on<SelectBookingEvent>(_onSelectBooking);
    on<DeselectBookingEvent>(_onDeselectBooking);
    on<SelectMultipleBookingsEvent>(_onSelectMultipleBookings);
    on<ClearSelectionEvent>(_onClearSelection);
  }

  Future<void> _onLoadBookings(
    LoadBookingsEvent event,
    Emitter<BookingsListState> emit,
  ) async {
    // لا تعرض حالة التحميل إذا كان لدينا بيانات حالية لتجنب الوميض
    final hasExistingData = state is BookingsListLoaded;
    final isLoadMoreRequest = hasExistingData && event.pageNumber > 1;
    if (!hasExistingData) {
      emit(BookingsListLoading());
    } else if (isLoadMoreRequest) {
      // حظر الطلبات المتعددة أثناء التحميل المستمر
      if (_isLoadingMore) return;
      _isLoadingMore = true;
    }

    // حفظ قيم الفلاتر
    _currentStartDate = event.startDate;
    _currentEndDate = event.endDate;
    _currentUserId = event.userId;
    _currentGuestNameOrEmail = event.guestNameOrEmail;
    _currentUnitId = event.unitId;
    _currentBookingSource = event.bookingSource;
    _currentPageNumber = event.pageNumber;
    _currentPageSize = event.pageSize;

    final result = await getBookingsByDateRangeUseCase(
      GetBookingsByDateRangeParams(
        startDate: event.startDate,
        endDate: event.endDate,
        pageNumber: event.pageNumber,
        pageSize: event.pageSize,
        userId: event.userId,
        guestNameOrEmail: event.guestNameOrEmail,
        unitId: event.unitId,
        bookingSource: event.bookingSource,
      ),
    );

    result.fold(
      (failure) {
        _isLoadingMore = false;
        if (hasExistingData) {
          // في حال الفشل ومع وجود بيانات حالية، أبقِ البيانات واظهر فشل العملية
          final current = state as BookingsListLoaded;
          emit(BookingOperationFailure(
            bookings: current.bookings,
            selectedBookings: current.selectedBookings,
            message: failure.message,
          ));
        } else {
          emit(BookingsListError(message: failure.message));
        }
      },
      (bookingsPage) {
        // دمج الاختيار الحالي إن وجد
        final selected = state is BookingsListLoaded
            ? (state as BookingsListLoaded).selectedBookings
            : const <Booking>[];

        PaginatedResult<Booking> effectivePage = bookingsPage;

        if (isLoadMoreRequest) {
          final current = state as BookingsListLoaded;
          // دمج العناصر مع إزالة التكرارات حسب المعرّف
          final List<Booking> combinedItems = <Booking>[
            ...current.bookings.items,
            ...bookingsPage.items.where(
              (nb) => !current.bookings.items.any((cb) => cb.id == nb.id),
            ),
          ];

          effectivePage = PaginatedResult<Booking>(
            items: combinedItems,
            pageNumber: bookingsPage.pageNumber,
            pageSize: bookingsPage.pageSize,
            totalCount: bookingsPage.totalCount,
            metadata: bookingsPage.metadata,
          );
        }

        emit(BookingsListLoaded(
          bookings: effectivePage,
          selectedBookings: selected
              .where((b) => effectivePage.items.any((nb) => nb.id == b.id))
              .toList(),
          filters: BookingFilters(
            startDate: event.startDate,
            endDate: event.endDate,
            userId: event.userId,
            guestNameOrEmail: event.guestNameOrEmail,
            unitId: event.unitId,
            bookingSource: event.bookingSource,
          ),
          stats: (effectivePage.metadata is Map<String, dynamic>)
              ? (effectivePage.metadata as Map<String, dynamic>)
              : null,
        ));

        _isLoadingMore = false;
      },
    );
  }

  Future<void> _onRefreshBookings(
    RefreshBookingsEvent event,
    Emitter<BookingsListState> emit,
  ) async {
    // Ensure date range
    if (_currentStartDate == null || _currentEndDate == null) {
      _currentEndDate = DateTime.now();
      _currentStartDate = DateTime.now().subtract(const Duration(days: 30));
    }

    // Show overlay but keep current list
    PaginatedResult<Booking>? currentPage;
    List<Booking> currentSelection = const [];
    if (state is BookingsListLoaded) {
      currentPage = (state as BookingsListLoaded).bookings;
      currentSelection = (state as BookingsListLoaded).selectedBookings;
      emit(BookingOperationInProgress(
        bookings: currentPage,
        selectedBookings: currentSelection,
        operation: 'refresh',
      ));
    }

    final result = await getBookingsByDateRangeUseCase(
      GetBookingsByDateRangeParams(
        startDate: _currentStartDate!,
        endDate: _currentEndDate!,
        pageNumber: _currentPageNumber,
        pageSize: _currentPageSize,
        userId: _currentUserId,
        guestNameOrEmail: _currentGuestNameOrEmail,
        unitId: _currentUnitId,
        bookingSource: _currentBookingSource,
      ),
    );

    result.fold(
      (failure) {
        // Keep existing state on failure; optionally could emit a transient error
        if (currentPage != null) {
          emit(BookingOperationFailure(
            bookings: currentPage,
            selectedBookings: currentSelection,
            message: failure.message,
          ));
        } else {
          emit(BookingsListError(message: failure.message));
        }
      },
      (bookingsPage) {
        emit(BookingsListLoaded(
          bookings: bookingsPage,
          selectedBookings: currentSelection
              .where((b) => bookingsPage.items.any((nb) => nb.id == b.id))
              .toList(),
          filters: BookingFilters(
            startDate: _currentStartDate,
            endDate: _currentEndDate,
            userId: _currentUserId,
            guestNameOrEmail: _currentGuestNameOrEmail,
            unitId: _currentUnitId,
            bookingSource: _currentBookingSource,
          ),
          stats: (bookingsPage.metadata is Map<String, dynamic>)
              ? (bookingsPage.metadata as Map<String, dynamic>)
              : null,
        ));
      },
    );
  }

  Future<void> _onCancelBooking(
    CancelBookingEvent event,
    Emitter<BookingsListState> emit,
  ) async {
    if (state is BookingsListLoaded) {
      final currentState = state as BookingsListLoaded;

      emit(BookingOperationInProgress(
        bookings: currentState.bookings,
        selectedBookings: currentState.selectedBookings,
        operation: 'cancel',
        bookingId: event.bookingId,
      ));

      final result = await cancelBookingUseCase(
        CancelBookingParams(
          bookingId: event.bookingId,
          cancellationReason: event.cancellationReason,
          refundPayments: event.refundPayments,
        ),
      );

      result.fold(
        (failure) {
          String message = failure.message;
          if (failure is ServerFailure && failure.showAsDialog) {
            message = failure.code ?? failure.message;
          }
          emit(BookingOperationFailure(
            bookings: currentState.bookings,
            selectedBookings: currentState.selectedBookings,
            message: message,
            bookingId: event.bookingId,
          ));
        },
        (_) {
          emit(BookingOperationSuccess(
            bookings: currentState.bookings,
            selectedBookings: currentState.selectedBookings,
            message: 'تم إلغاء الحجز بنجاح',
            bookingId: event.bookingId,
          ));
          // إعادة تحميل القائمة
          add(RefreshBookingsEvent());
        },
      );
    }
  }

  Future<void> _onUpdateBooking(
    UpdateBookingEvent event,
    Emitter<BookingsListState> emit,
  ) async {
    if (state is BookingsListLoaded) {
      final currentState = state as BookingsListLoaded;

      emit(BookingOperationInProgress(
        bookings: currentState.bookings,
        selectedBookings: currentState.selectedBookings,
        operation: 'update',
        bookingId: event.bookingId,
      ));

      final result = await updateBookingUseCase(
        UpdateBookingParams(
          bookingId: event.bookingId,
          checkIn: event.checkIn,
          checkOut: event.checkOut,
          guestsCount: event.guestsCount,
        ),
      );

      result.fold(
        (failure) => emit(BookingOperationFailure(
          bookings: currentState.bookings,
          selectedBookings: currentState.selectedBookings,
          message: failure.message,
          bookingId: event.bookingId,
        )),
        (_) {
          emit(BookingOperationSuccess(
            bookings: currentState.bookings,
            selectedBookings: currentState.selectedBookings,
            message: 'تم تحديث الحجز بنجاح',
            bookingId: event.bookingId,
          ));
          // إعادة تحميل القائمة
          add(RefreshBookingsEvent());
        },
      );
    }
  }

  Future<void> _onConfirmBooking(
    ConfirmBookingEvent event,
    Emitter<BookingsListState> emit,
  ) async {
    if (state is BookingsListLoaded) {
      final currentState = state as BookingsListLoaded;

      emit(BookingOperationInProgress(
        bookings: currentState.bookings,
        selectedBookings: currentState.selectedBookings,
        operation: 'confirm',
        bookingId: event.bookingId,
      ));

      final result = await confirmBookingUseCase(
        ConfirmBookingParams(bookingId: event.bookingId),
      );

      result.fold(
        (failure) => emit(BookingOperationFailure(
          bookings: currentState.bookings,
          selectedBookings: currentState.selectedBookings,
          message: failure.message,
          bookingId: event.bookingId,
        )),
        (_) {
          emit(BookingOperationSuccess(
            bookings: currentState.bookings,
            selectedBookings: currentState.selectedBookings,
            message: 'تم تأكيد الحجز بنجاح',
            bookingId: event.bookingId,
          ));
          // إعادة تحميل القائمة
          add(RefreshBookingsEvent());
        },
      );
    }
  }

  Future<void> _onCheckInBooking(
    CheckInBookingEvent event,
    Emitter<BookingsListState> emit,
  ) async {
    if (state is BookingsListLoaded) {
      final currentState = state as BookingsListLoaded;

      emit(BookingOperationInProgress(
        bookings: currentState.bookings,
        selectedBookings: currentState.selectedBookings,
        operation: 'checkIn',
        bookingId: event.bookingId,
      ));

      final result = await checkInUseCase(
        CheckInParams(bookingId: event.bookingId),
      );

      result.fold(
        (failure) => emit(BookingOperationFailure(
          bookings: currentState.bookings,
          selectedBookings: currentState.selectedBookings,
          message: failure.message,
          bookingId: event.bookingId,
        )),
        (_) {
          emit(BookingOperationSuccess(
            bookings: currentState.bookings,
            selectedBookings: currentState.selectedBookings,
            message: 'تم تسجيل الوصول بنجاح',
            bookingId: event.bookingId,
          ));
          // إعادة تحميل القائمة
          add(RefreshBookingsEvent());
        },
      );
    }
  }

  Future<void> _onCheckOutBooking(
    CheckOutBookingEvent event,
    Emitter<BookingsListState> emit,
  ) async {
    if (state is BookingsListLoaded) {
      final currentState = state as BookingsListLoaded;

      emit(BookingOperationInProgress(
        bookings: currentState.bookings,
        selectedBookings: currentState.selectedBookings,
        operation: 'checkOut',
        bookingId: event.bookingId,
      ));

      final result = await checkOutUseCase(
        CheckOutParams(bookingId: event.bookingId),
      );

      result.fold(
        (failure) => emit(BookingOperationFailure(
          bookings: currentState.bookings,
          selectedBookings: currentState.selectedBookings,
          message: failure.message,
          bookingId: event.bookingId,
        )),
        (_) {
          emit(BookingOperationSuccess(
            bookings: currentState.bookings,
            selectedBookings: currentState.selectedBookings,
            message: 'تم تسجيل المغادرة بنجاح',
            bookingId: event.bookingId,
          ));
          // إعادة تحميل القائمة
          add(RefreshBookingsEvent());
        },
      );
    }
  }

  Future<void> _onFilterBookings(
    FilterBookingsEvent event,
    Emitter<BookingsListState> emit,
  ) async {
    add(LoadBookingsEvent(
      startDate: event.startDate ??
          _currentStartDate ??
          DateTime.now().subtract(const Duration(days: 30)),
      endDate: event.endDate ?? _currentEndDate ?? DateTime.now(),
      pageNumber: 1, // Reset to first page when filtering
      pageSize: _currentPageSize,
      userId: event.userId,
      guestNameOrEmail: event.guestNameOrEmail,
      unitId: event.unitId,
      bookingSource: event.bookingSource,
    ));
  }

  Future<void> _onSearchBookings(
    SearchBookingsEvent event,
    Emitter<BookingsListState> emit,
  ) async {
    add(LoadBookingsEvent(
      startDate: _currentStartDate ??
          DateTime.now().subtract(const Duration(days: 30)),
      endDate: _currentEndDate ?? DateTime.now(),
      pageNumber: 1, // Reset to first page when searching
      pageSize: _currentPageSize,
      userId: _currentUserId,
      guestNameOrEmail: event.searchTerm,
      unitId: _currentUnitId,
      bookingSource: _currentBookingSource,
    ));
  }

  Future<void> _onChangePage(
    ChangePageEvent event,
    Emitter<BookingsListState> emit,
  ) async {
    // إذا كنا بالفعل في الصفحة المطلوبة، تجاهل لتجنب إعادة التحميل غير الضرورية
    if (state is BookingsListLoaded) {
      final current = state as BookingsListLoaded;
      if (current.bookings.pageNumber == event.pageNumber) {
        return;
      }
    }

    add(LoadBookingsEvent(
      startDate: _currentStartDate ??
          DateTime.now().subtract(const Duration(days: 30)),
      endDate: _currentEndDate ?? DateTime.now(),
      pageNumber: event.pageNumber,
      pageSize: _currentPageSize,
      userId: _currentUserId,
      guestNameOrEmail: _currentGuestNameOrEmail,
      unitId: _currentUnitId,
      bookingSource: _currentBookingSource,
    ));
  }

  Future<void> _onChangePageSize(
    ChangePageSizeEvent event,
    Emitter<BookingsListState> emit,
  ) async {
    if (event.pageSize == _currentPageSize) {
      return;
    }

    add(LoadBookingsEvent(
      startDate: _currentStartDate ??
          DateTime.now().subtract(const Duration(days: 30)),
      endDate: _currentEndDate ?? DateTime.now(),
      pageNumber: 1, // Reset to first page when changing page size
      pageSize: event.pageSize,
      userId: _currentUserId,
      guestNameOrEmail: _currentGuestNameOrEmail,
      unitId: _currentUnitId,
      bookingSource: _currentBookingSource,
    ));
  }

  Future<void> _onSelectBooking(
    SelectBookingEvent event,
    Emitter<BookingsListState> emit,
  ) async {
    if (state is BookingsListLoaded) {
      final currentState = state as BookingsListLoaded;
      final updatedSelection =
          List<Booking>.from(currentState.selectedBookings);

      final booking = currentState.bookings.items.firstWhere(
        (b) => b.id == event.bookingId,
      );

      if (!updatedSelection.contains(booking)) {
        updatedSelection.add(booking);
      }

      emit(currentState.copyWith(selectedBookings: updatedSelection));
    }
  }

  Future<void> _onDeselectBooking(
    DeselectBookingEvent event,
    Emitter<BookingsListState> emit,
  ) async {
    if (state is BookingsListLoaded) {
      final currentState = state as BookingsListLoaded;
      final updatedSelection = List<Booking>.from(currentState.selectedBookings)
        ..removeWhere((b) => b.id == event.bookingId);

      emit(currentState.copyWith(selectedBookings: updatedSelection));
    }
  }

  Future<void> _onSelectMultipleBookings(
    SelectMultipleBookingsEvent event,
    Emitter<BookingsListState> emit,
  ) async {
    if (state is BookingsListLoaded) {
      final currentState = state as BookingsListLoaded;
      final bookings = currentState.bookings.items
          .where((b) => event.bookingIds.contains(b.id))
          .toList();

      emit(currentState.copyWith(selectedBookings: bookings));
    }
  }

  Future<void> _onClearSelection(
    ClearSelectionEvent event,
    Emitter<BookingsListState> emit,
  ) async {
    if (state is BookingsListLoaded) {
      final currentState = state as BookingsListLoaded;
      emit(currentState.copyWith(selectedBookings: []));
    }
  }
}
