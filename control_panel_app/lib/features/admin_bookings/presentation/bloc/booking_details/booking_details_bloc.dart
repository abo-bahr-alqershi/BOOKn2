import 'package:bookn_cp_app/features/admin_reviews/domain/repositories/reviews_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/booking_details.dart';
import '../../../../../../core/error/failures.dart';
import '../../../domain/usecases/bookings/get_booking_by_id_usecase.dart';
import '../../../domain/usecases/bookings/cancel_booking_usecase.dart';
import '../../../domain/usecases/bookings/update_booking_usecase.dart';
import '../../../domain/usecases/bookings/confirm_booking_usecase.dart';
import '../../../domain/usecases/bookings/check_in_usecase.dart';
import '../../../domain/usecases/bookings/check_out_usecase.dart';
import '../../../domain/usecases/services/add_service_to_booking_usecase.dart';
import '../../../domain/usecases/services/remove_service_from_booking_usecase.dart';
import '../../../domain/usecases/services/get_booking_services_usecase.dart';
import '../../../domain/repositories/bookings_repository.dart';
import 'booking_details_event.dart';
import 'booking_details_state.dart';
import '../../../../../../core/utils/invoice_pdf.dart';
import '../../../../../../core/utils/pdf_helper.dart';

class BookingDetailsBloc
    extends Bloc<BookingDetailsEvent, BookingDetailsState> {
  final GetBookingByIdUseCase getBookingByIdUseCase;
  final CancelBookingUseCase cancelBookingUseCase;
  final UpdateBookingUseCase updateBookingUseCase;
  final ConfirmBookingUseCase confirmBookingUseCase;
  final CheckInUseCase checkInUseCase;
  final CheckOutUseCase checkOutUseCase;
  final AddServiceToBookingUseCase addServiceToBookingUseCase;
  final RemoveServiceFromBookingUseCase removeServiceFromBookingUseCase;
  final GetBookingServicesUseCase getBookingServicesUseCase;
  final BookingsRepository repository;
  final ReviewsRepository reviewsRepository;

  String? _currentBookingId;

  BookingDetailsLoaded? _currentLoadedLike() {
    final s = state;
    if (s is BookingDetailsLoaded) return s;
    if (s is BookingDetailsOperationFailure) {
      return BookingDetailsLoaded(
        booking: s.booking,
        bookingDetails: s.bookingDetails,
        services: s.services,
        isRefreshing: false,
      );
    }
    if (s is BookingDetailsOperationSuccess) {
      return BookingDetailsLoaded(
        booking: s.booking,
        bookingDetails: s.bookingDetails,
        services: s.services,
        isRefreshing: false,
      );
    }
    return null;
  }

  BookingDetailsBloc({
    required this.getBookingByIdUseCase,
    required this.cancelBookingUseCase,
    required this.updateBookingUseCase,
    required this.confirmBookingUseCase,
    required this.checkInUseCase,
    required this.checkOutUseCase,
    required this.addServiceToBookingUseCase,
    required this.removeServiceFromBookingUseCase,
    required this.getBookingServicesUseCase,
    required this.repository,
    required this.reviewsRepository,
  }) : super(BookingDetailsInitial()) {
    on<LoadBookingDetailsEvent>(_onLoadBookingDetails);
    on<RefreshBookingDetailsEvent>(_onRefreshBookingDetails);
    on<UpdateBookingDetailsEvent>(_onUpdateBookingDetails);
    on<CancelBookingDetailsEvent>(_onCancelBookingDetails);
    on<ConfirmBookingDetailsEvent>(_onConfirmBookingDetails);
    on<CheckInBookingDetailsEvent>(_onCheckInBookingDetails);
    on<CheckOutBookingDetailsEvent>(_onCheckOutBookingDetails);
    on<AddServiceEvent>(_onAddService);
    on<RemoveServiceEvent>(_onRemoveService);
    on<LoadBookingServicesEvent>(_onLoadBookingServices);
    on<LoadBookingActivitiesEvent>(_onLoadBookingActivities);
    on<LoadBookingPaymentsEvent>(_onLoadBookingPayments);
    on<PrintBookingDetailsEvent>(_onPrintBookingDetails);
    on<ShareBookingDetailsEvent>(_onShareBookingDetails);
    on<SendBookingConfirmationEvent>(_onSendBookingConfirmation);
  }

  Future<void> _onLoadBookingDetails(
    LoadBookingDetailsEvent event,
    Emitter<BookingDetailsState> emit,
  ) async {
    // إذا كانت هذه عملية refresh وليس تحميل أولي، لا نُظهر شاشة loading كاملة
    if (state is! BookingDetailsLoaded) {
      emit(BookingDetailsLoading());
    }
    _currentBookingId = event.bookingId;

    // جلب البيانات الأساسية
    final bookingResult = await getBookingByIdUseCase(
      GetBookingByIdParams(bookingId: event.bookingId),
    );

    await bookingResult.fold(
      (failure) async {
        emit(BookingDetailsError(message: failure.message));
      },
      (booking) async {
        // جلب التفاصيل الإضافية
        final detailsResult = await repository.getBookingDetails(
          bookingId: event.bookingId,
        );

        await detailsResult.fold(
          (failure) async {
            // إذا فشل جلب التفاصيل، عرض البيانات الأساسية فقط
            emit(BookingDetailsLoaded(
              booking: booking,
              bookingDetails: null,
              services: const [],
              isRefreshing: false,
            ));
          },
          (details) async {
            // جلب الخدمات
            final servicesResult = await getBookingServicesUseCase(
              GetBookingServicesParams(bookingId: event.bookingId),
            );

            final services = servicesResult.fold(
              (_) => <Service>[],
              (services) => services,
            );

            // جلب التقييم المرتبط بالحجز (إن وجد)
            final reviewResult =
                await reviewsRepository.getReviewByBooking(event.bookingId);
            final review = reviewResult.fold((_) => null, (r) => r);

            emit(BookingDetailsLoaded(
              booking: booking,
              bookingDetails: details,
              services: services,
              isRefreshing: false,
              review: review,
            ));
          },
        );
      },
    );
  }

  Future<void> _onRefreshBookingDetails(
    RefreshBookingDetailsEvent event,
    Emitter<BookingDetailsState> emit,
  ) async {
    if (_currentBookingId != null) {
      final currentState = _currentLoadedLike();
      if (currentState != null) {
        emit(currentState.copyWith(isRefreshing: true));
      }
      add(LoadBookingDetailsEvent(bookingId: _currentBookingId!));
    }
  }

  Future<void> _onUpdateBookingDetails(
    UpdateBookingDetailsEvent event,
    Emitter<BookingDetailsState> emit,
  ) async {
    final currentState = _currentLoadedLike();
    if (currentState != null) {

      emit(BookingDetailsOperationInProgress(
        booking: currentState.booking,
        bookingDetails: currentState.bookingDetails,
        services: currentState.services,
        operation: 'update',
      ));

      final result = await updateBookingUseCase(
        UpdateBookingParams(
          bookingId: event.bookingId,
          checkIn: event.checkIn,
          checkOut: event.checkOut,
          guestsCount: event.guestsCount,
        ),
      );

      await result.fold(
        (failure) async {
          emit(BookingDetailsOperationFailure(
            booking: currentState.booking,
            bookingDetails: currentState.bookingDetails,
            services: currentState.services,
            message: failure.message,
          ));
        },
        (_) async {
          emit(BookingDetailsOperationSuccess(
            booking: currentState.booking,
            bookingDetails: currentState.bookingDetails,
            services: currentState.services,
            message: 'تم تحديث الحجز بنجاح',
          ));
          add(const RefreshBookingDetailsEvent());
        },
      );
    }
  }

  Future<void> _onCancelBookingDetails(
    CancelBookingDetailsEvent event,
    Emitter<BookingDetailsState> emit,
  ) async {
    debugPrint('🔴 [BookingDetailsBloc] بدء إلغاء الحجز: ${event.bookingId}');
    debugPrint('🔴 [BookingDetailsBloc] سبب الإلغاء: ${event.cancellationReason}');
    
    final currentState = _currentLoadedLike();
    if (currentState != null) {

      debugPrint('🔄 [BookingDetailsBloc] الحالة الحالية: BookingDetailsLoaded');
      
      emit(BookingDetailsOperationInProgress(
        booking: currentState.booking,
        bookingDetails: currentState.bookingDetails,
        services: currentState.services,
        operation: 'cancel',
      ));

      debugPrint('⏳ [BookingDetailsBloc] استدعاء cancelBookingUseCase...');
      
      final result = await cancelBookingUseCase(
        CancelBookingParams(
          bookingId: event.bookingId,
          cancellationReason: event.cancellationReason,
          refundPayments: event.refundPayments,
        ),
      );

      await result.fold(
        (failure) async {
          debugPrint('❌ [BookingDetailsBloc] فشل الإلغاء: ${failure.message}');
          String message = failure.message;
          if (failure is ServerFailure && failure.showAsDialog) {
            message = failure.code ?? failure.message;
          }
          emit(BookingDetailsOperationFailure(
            booking: currentState.booking,
            bookingDetails: currentState.bookingDetails,
            services: currentState.services,
            message: message,
          ));
        },
        (_) async {
          debugPrint('✅ [BookingDetailsBloc] نجح الإلغاء');
          emit(BookingDetailsOperationSuccess(
            booking: currentState.booking,
            bookingDetails: currentState.bookingDetails,
            services: currentState.services,
            message: 'تم إلغاء الحجز بنجاح',
          ));
          await Future.delayed(const Duration(milliseconds: 500));
          debugPrint('🔄 [BookingDetailsBloc] إعادة تحميل تفاصيل الحجز...');
          add(LoadBookingDetailsEvent(bookingId: event.bookingId));
        },
      );
    } else {
      debugPrint('⚠️ [BookingDetailsBloc] الحالة الحالية ليست BookingDetailsLoaded: ${state.runtimeType}');
    }
  }

  Future<void> _onConfirmBookingDetails(
    ConfirmBookingDetailsEvent event,
    Emitter<BookingDetailsState> emit,
  ) async {
    debugPrint('🔵 [BookingDetailsBloc] بدء تأكيد الحجز: ${event.bookingId}');
    
    final currentState = _currentLoadedLike();
    if (currentState != null) {

      debugPrint('📋 [BookingDetailsBloc] حالة الحجز الحالية: ${currentState.booking.status}');
      
      emit(BookingDetailsOperationInProgress(
        booking: currentState.booking,
        bookingDetails: currentState.bookingDetails,
        services: currentState.services,
        operation: 'confirm',
      ));

      debugPrint('⏳ [BookingDetailsBloc] استدعاء confirmBookingUseCase...');
      
      final result = await confirmBookingUseCase(
        ConfirmBookingParams(bookingId: event.bookingId),
      );

      await result.fold(
        (failure) async {
          debugPrint('❌ [BookingDetailsBloc] فشل التأكيد: ${failure.message}');
          String errorMessage = failure.message;
          if (failure.message.contains('غير متاحة') || 
              failure.message.toLowerCase().contains('not available') ||
              failure.message.toLowerCase().contains('no longer available')) {
            errorMessage = '''الوحدة غير متاحة في التواريخ المحددة.
            
قد يكون السبب:
• تم حجز الوحدة من قبل شخص آخر
• تعارض في التواريخ مع حجز آخر
• الوحدة محظورة أو قيد الصيانة

يرجى التحقق من جدول الإتاحة والمحاولة مرة أخرى.''';
          }
          emit(BookingDetailsOperationFailure(
            booking: currentState.booking,
            bookingDetails: currentState.bookingDetails,
            services: currentState.services,
            message: errorMessage,
          ));
        },
        (_) async {
          debugPrint('✅ [BookingDetailsBloc] نجح التأكيد');
          emit(BookingDetailsOperationSuccess(
            booking: currentState.booking,
            bookingDetails: currentState.bookingDetails,
            services: currentState.services,
            message: 'تم تأكيد الحجز بنجاح',
          ));
          await Future.delayed(const Duration(milliseconds: 500));
          debugPrint('🔄 [BookingDetailsBloc] إعادة تحميل تفاصيل الحجز...');
          add(LoadBookingDetailsEvent(bookingId: event.bookingId));
        },
      );
    } else {
      debugPrint('⚠️ [BookingDetailsBloc] الحالة الحالية ليست BookingDetailsLoaded: ${state.runtimeType}');
    }
  }

  Future<void> _onCheckInBookingDetails(
    CheckInBookingDetailsEvent event,
    Emitter<BookingDetailsState> emit,
  ) async {
    final currentState = _currentLoadedLike();
    if (currentState != null) {

      emit(BookingDetailsOperationInProgress(
        booking: currentState.booking,
        bookingDetails: currentState.bookingDetails,
        services: currentState.services,
        operation: 'checkIn',
      ));

      final result = await checkInUseCase(
        CheckInParams(bookingId: event.bookingId),
      );

      await result.fold(
        (failure) async {
          emit(BookingDetailsOperationFailure(
            booking: currentState.booking,
            bookingDetails: currentState.bookingDetails,
            services: currentState.services,
            message: failure.message,
          ));
        },
        (_) async {
          emit(BookingDetailsOperationSuccess(
            booking: currentState.booking,
            bookingDetails: currentState.bookingDetails,
            services: currentState.services,
            message: 'تم تسجيل الوصول بنجاح',
          ));
          await Future.delayed(const Duration(milliseconds: 500));
          add(LoadBookingDetailsEvent(bookingId: event.bookingId));
        },
      );
    }
  }

  Future<void> _onCheckOutBookingDetails(
    CheckOutBookingDetailsEvent event,
    Emitter<BookingDetailsState> emit,
  ) async {
    final currentState = _currentLoadedLike();
    if (currentState != null) {

      emit(BookingDetailsOperationInProgress(
        booking: currentState.booking,
        bookingDetails: currentState.bookingDetails,
        services: currentState.services,
        operation: 'checkOut',
      ));

      final result = await checkOutUseCase(
        CheckOutParams(bookingId: event.bookingId),
      );

      await result.fold(
        (failure) async {
          emit(BookingDetailsOperationFailure(
            booking: currentState.booking,
            bookingDetails: currentState.bookingDetails,
            services: currentState.services,
            message: failure.message,
          ));
        },
        (_) async {
          emit(BookingDetailsOperationSuccess(
            booking: currentState.booking,
            bookingDetails: currentState.bookingDetails,
            services: currentState.services,
            message: 'تم تسجيل المغادرة بنجاح',
          ));
          await Future.delayed(const Duration(milliseconds: 500));
          add(LoadBookingDetailsEvent(bookingId: event.bookingId));
        },
      );
    }
  }

  Future<void> _onAddService(
    AddServiceEvent event,
    Emitter<BookingDetailsState> emit,
  ) async {
    final currentState = _currentLoadedLike();
    if (currentState != null) {

      emit(BookingDetailsOperationInProgress(
        booking: currentState.booking,
        bookingDetails: currentState.bookingDetails,
        services: currentState.services,
        operation: 'addService',
      ));

      final result = await addServiceToBookingUseCase(
        AddServiceToBookingParams(
          bookingId: event.bookingId,
          serviceId: event.serviceId,
        ),
      );

      await result.fold(
        (failure) async {
          emit(BookingDetailsOperationFailure(
            booking: currentState.booking,
            bookingDetails: currentState.bookingDetails,
            services: currentState.services,
            message: failure.message,
          ));
        },
        (_) async {
          emit(BookingDetailsOperationSuccess(
            booking: currentState.booking,
            bookingDetails: currentState.bookingDetails,
            services: currentState.services,
            message: 'تمت إضافة الخدمة بنجاح',
          ));
          add(LoadBookingServicesEvent(bookingId: event.bookingId));
        },
      );
    }
  }

  Future<void> _onRemoveService(
    RemoveServiceEvent event,
    Emitter<BookingDetailsState> emit,
  ) async {
    final currentState = _currentLoadedLike();
    if (currentState != null) {

      emit(BookingDetailsOperationInProgress(
        booking: currentState.booking,
        bookingDetails: currentState.bookingDetails,
        services: currentState.services,
        operation: 'removeService',
      ));

      final result = await removeServiceFromBookingUseCase(
        RemoveServiceFromBookingParams(
          bookingId: event.bookingId,
          serviceId: event.serviceId,
        ),
      );

      await result.fold(
        (failure) async {
          emit(BookingDetailsOperationFailure(
            booking: currentState.booking,
            bookingDetails: currentState.bookingDetails,
            services: currentState.services,
            message: failure.message,
          ));
        },
        (_) async {
          emit(BookingDetailsOperationSuccess(
            booking: currentState.booking,
            bookingDetails: currentState.bookingDetails,
            services: currentState.services,
            message: 'تمت إزالة الخدمة بنجاح',
          ));
          add(LoadBookingServicesEvent(bookingId: event.bookingId));
        },
      );
    }
  }

  Future<void> _onLoadBookingServices(
    LoadBookingServicesEvent event,
    Emitter<BookingDetailsState> emit,
  ) async {
    final currentState = _currentLoadedLike();
    if (currentState != null) {

      final result = await getBookingServicesUseCase(
        GetBookingServicesParams(bookingId: event.bookingId),
      );

      result.fold(
        (_) {},
        (services) {
          emit(currentState.copyWith(services: services));
        },
      );
    }
  }

  Future<void> _onLoadBookingActivities(
    LoadBookingActivitiesEvent event,
    Emitter<BookingDetailsState> emit,
  ) async {
    // يمكن تنفيذها لاحقاً إذا توفر endpoint للأنشطة
  }

  Future<void> _onLoadBookingPayments(
    LoadBookingPaymentsEvent event,
    Emitter<BookingDetailsState> emit,
  ) async {
    // يمكن تنفيذها لاحقاً إذا توفر endpoint للمدفوعات
  }

  Future<void> _onPrintBookingDetails(
    PrintBookingDetailsEvent event,
    Emitter<BookingDetailsState> emit,
  ) async {
    if (state is BookingDetailsLoaded) {
      final currentState = state as BookingDetailsLoaded;
      emit(BookingDetailsPrinting(
        booking: currentState.booking,
        bookingDetails: currentState.bookingDetails,
        services: currentState.services,
      ));
      // توليد وحفظ ملف الفاتورة PDF مباشرة من التطبيق
      try {
        final details = currentState.bookingDetails ??
            BookingDetails(
              booking: currentState.booking,
              payments: const [],
              services: currentState.services,
            );
        final pdfBytes = await InvoicePdfGenerator.generate(details);
        final fileName = PdfHelper.generateInvoiceFileName(currentState.booking.id);
        await PdfHelper.saveAndOpenPdf(
          pdfBytes: pdfBytes,
          fileName: fileName,
        );
      } catch (error, stackTrace) {
        debugPrint(
          'Failed to generate or print invoice for booking ${currentState.booking.id}: $error',
        );
        addError(error, stackTrace);
      }
      emit(currentState);
    }
  }

  Future<void> _onShareBookingDetails(
    ShareBookingDetailsEvent event,
    Emitter<BookingDetailsState> emit,
  ) async {
    if (state is BookingDetailsLoaded) {
      final currentState = state as BookingDetailsLoaded;
      emit(BookingDetailsSharing(
        booking: currentState.booking,
        bookingDetails: currentState.bookingDetails,
        services: currentState.services,
      ));
      // تنفيذ منطق المشاركة
      await Future.delayed(const Duration(seconds: 1));
      emit(currentState);
    }
  }

  Future<void> _onSendBookingConfirmation(
    SendBookingConfirmationEvent event,
    Emitter<BookingDetailsState> emit,
  ) async {
    if (state is BookingDetailsLoaded) {
      final currentState = state as BookingDetailsLoaded;
      emit(BookingDetailsSendingConfirmation(
        booking: currentState.booking,
        bookingDetails: currentState.bookingDetails,
        services: currentState.services,
      ));
      // تنفيذ منطق إرسال التأكيد
      await Future.delayed(const Duration(seconds: 2));
      emit(BookingDetailsOperationSuccess(
        booking: currentState.booking,
        bookingDetails: currentState.bookingDetails,
        services: currentState.services,
        message: 'تم إرسال تأكيد الحجز بنجاح',
      ));
      await Future.delayed(const Duration(seconds: 2));
      emit(currentState);
    }
  }
}
