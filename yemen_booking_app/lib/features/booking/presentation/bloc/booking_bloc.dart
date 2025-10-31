import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_booking_usecase.dart';
import '../../domain/usecases/get_booking_details_usecase.dart';
import '../../domain/usecases/cancel_booking_usecase.dart';
import '../../domain/usecases/get_user_bookings_usecase.dart';
import '../../domain/usecases/get_user_bookings_summary_usecase.dart';
import '../../domain/usecases/add_services_to_booking_usecase.dart';
import '../../domain/usecases/check_availability_usecase.dart';
import '../../../payment/domain/usecases/process_payment_usecase.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final CreateBookingUseCase createBookingUseCase;
  final GetBookingDetailsUseCase getBookingDetailsUseCase;
  final CancelBookingUseCase cancelBookingUseCase;
  final GetUserBookingsUseCase getUserBookingsUseCase;
  final GetUserBookingsSummaryUseCase getUserBookingsSummaryUseCase;
  final AddServicesToBookingUseCase addServicesToBookingUseCase;
  final CheckAvailabilityUseCase checkAvailabilityUseCase;
  final ProcessPaymentUseCase processPaymentUseCase;
  
  BookingBloc({
    required this.createBookingUseCase,
    required this.getBookingDetailsUseCase,
    required this.cancelBookingUseCase,
    required this.getUserBookingsUseCase,
    required this.getUserBookingsSummaryUseCase,
    required this.addServicesToBookingUseCase,
    required this.checkAvailabilityUseCase,
    required this.processPaymentUseCase,
  }) : super(const BookingInitial()) {
    on<CreateBookingEvent>(_onCreateBooking);
    on<GetBookingDetailsEvent>(_onGetBookingDetails);
    on<CancelBookingEvent>(_onCancelBooking);
    on<GetUserBookingsEvent>(_onGetUserBookings);
    on<GetUserBookingsSummaryEvent>(_onGetUserBookingsSummary);
    on<AddServicesToBookingEvent>(_onAddServicesToBooking);
    on<CheckAvailabilityEvent>(_onCheckAvailability);
    on<UpdateBookingFormEvent>(_onUpdateBookingForm);
    on<ResetBookingStateEvent>(_onResetBookingState);
    on<ProcessBookingPaymentEvent>(_onProcessBookingPayment);
  }

  Future<void> _onCreateBooking(
    CreateBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading());

    final result = await createBookingUseCase(event.bookingRequest);

    result.fold(
      (failure) => emit(BookingError(message: failure.message)),
      (booking) => emit(BookingCreated(booking: booking)),
    );
  }

  Future<void> _onGetBookingDetails(
    GetBookingDetailsEvent event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading());

    final params = GetBookingDetailsParams(
      bookingId: event.bookingId,
      userId: event.userId,
    );

    final result = await getBookingDetailsUseCase(params);

    result.fold(
      (failure) => emit(BookingError(message: failure.message)),
      (booking) => emit(BookingDetailsLoaded(booking: booking)),
    );
  }

  Future<void> _onCancelBooking(
    CancelBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading());

    final params = CancelBookingParams(
      bookingId: event.bookingId,
      userId: event.userId,
      reason: event.reason,
    );

    final result = await cancelBookingUseCase(params);

    result.fold(
      (failure) => emit(BookingError(message: failure.message)),
      (success) => emit(const BookingCancelled()),
    );
  }

  Future<void> _onGetUserBookings(
    GetUserBookingsEvent event,
    Emitter<BookingState> emit,
  ) async {
    if (event.loadMore && state is UserBookingsLoaded) {
      final currentState = state as UserBookingsLoaded;
      if (currentState.isLoadingMore || !currentState.hasMore) return;
      
      emit(currentState.copyWith(isLoadingMore: true));
    } else {
      emit(const BookingLoading());
    }

    final params = GetUserBookingsParams(
      userId: event.userId,
      status: event.status,
      pageNumber: event.pageNumber,
      pageSize: event.pageSize,
    );

    final result = await getUserBookingsUseCase(params);

    result.fold(
      (failure) => emit(BookingError(message: failure.message)),
      (paginatedBookings) {
        if (event.loadMore && state is UserBookingsLoaded) {
          final currentState = state as UserBookingsLoaded;
          final updatedBookings = [
            ...currentState.bookings,
            ...paginatedBookings.items,
          ];
          emit(UserBookingsLoaded(
            bookings: updatedBookings,
            hasMore: paginatedBookings.hasNextPage,
            currentPage: paginatedBookings.pageNumber,
            totalCount: paginatedBookings.totalCount,
            isLoadingMore: false,
          ));
        } else {
          emit(UserBookingsLoaded(
            bookings: paginatedBookings.items,
            hasMore: paginatedBookings.hasNextPage,
            currentPage: paginatedBookings.pageNumber,
            totalCount: paginatedBookings.totalCount,
            isLoadingMore: false,
          ));
        }
      },
    );
  }

  Future<void> _onGetUserBookingsSummary(
    GetUserBookingsSummaryEvent event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading());

    final params = GetUserBookingsSummaryParams(
      userId: event.userId,
      year: event.year,
    );

    final result = await getUserBookingsSummaryUseCase(params);

    result.fold(
      (failure) => emit(BookingError(message: failure.message)),
      (summary) => emit(UserBookingsSummaryLoaded(summary: summary)),
    );
  }

  Future<void> _onAddServicesToBooking(
    AddServicesToBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading());

    final params = AddServicesToBookingParams(
      bookingId: event.bookingId,
      serviceId: event.serviceId,
      quantity: event.quantity,
    );

    final result = await addServicesToBookingUseCase(params);

    result.fold(
      (failure) => emit(BookingError(message: failure.message)),
      (booking) => emit(ServicesAddedToBooking(booking: booking)),
    );
  }

  Future<void> _onCheckAvailability(
    CheckAvailabilityEvent event,
    Emitter<BookingState> emit,
  ) async {
    emit(const CheckingAvailability());

    final params = CheckAvailabilityParams(
      unitId: event.unitId,
      checkIn: event.checkIn,
      checkOut: event.checkOut,
      guestsCount: event.guestsCount,
    );

    final result = await checkAvailabilityUseCase(params);

    result.fold(
      (failure) => emit(BookingError(message: failure.message)),
      (isAvailable) => emit(AvailabilityChecked(isAvailable: isAvailable)),
    );
  }

  void _onUpdateBookingForm(
    UpdateBookingFormEvent event,
    Emitter<BookingState> emit,
  ) {
    emit(BookingFormUpdated(formData: event.formData));
  }

  void _onResetBookingState(
    ResetBookingStateEvent event,
    Emitter<BookingState> emit,
  ) {
    emit(const BookingInitial());
  }

  Future<void> _onProcessBookingPayment(
    ProcessBookingPaymentEvent event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading());

    final paymentParams = ProcessPaymentParams(
      bookingId: event.bookingId,
      userId: event.userId,
      amount: event.amount,
      paymentMethod: event.paymentMethod,
      currency: 'YER',
      paymentDetails: event.paymentDetails,
    );

    final paymentResult = await processPaymentUseCase(paymentParams);

    await paymentResult.fold(
      (failure) async => emit(BookingError(message: failure.message)),
      (transaction) async {
        if (transaction.isSuccessful) {
          // Get booking details after successful payment
          final bookingResult = await getBookingDetailsUseCase(
            GetBookingDetailsParams(
              bookingId: event.bookingId,
              userId: event.userId,
            ),
          );
          
          bookingResult.fold(
            (failure) => emit(BookingError(message: failure.message)),
            (booking) => emit(BookingCreated(booking: booking)),
          );
        } else {
          emit(BookingError(message: 'فشل الدفع: ${transaction.failureReason ?? "خطأ غير معروف"}'));
        }
      },
    );
  }
}