import 'package:bookn_cp_app/core/enums/booking_status.dart';
import 'package:bookn_cp_app/core/enums/payment_method_enum.dart';
import 'package:bookn_cp_app/features/admin_bookings/domain/entities/booking.dart';
import 'package:bookn_cp_app/features/admin_bookings/domain/entities/booking_details.dart';
import 'package:bookn_cp_app/features/admin_bookings/presentation/widgets/booking_payment_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BookingPaymentSummary', () {
    testWidgets('renders totals using booking details money values',
        (tester) async {
      const totalPrice = Money(
        amount: 300,
        currency: 'USD',
        formattedAmount: 'USD 300.00',
      );

      final booking = Booking(
        id: 'b-1',
        userId: 'u-1',
        unitId: 'unit-1',
        checkIn: DateTime(2024, 1, 1),
        checkOut: DateTime(2024, 1, 4),
        guestsCount: 2,
        totalPrice: totalPrice,
        status: BookingStatus.confirmed,
        bookedAt: DateTime(2023, 12, 20),
        userName: 'Guest One',
        unitName: 'Luxury Suite',
        userEmail: 'guest@example.com',
        userPhone: '+1234567890',
      );

      const paymentMoney = Money(
        amount: 150,
        currency: 'USD',
        formattedAmount: 'USD 150.00',
      );

      final payment = Payment(
        id: 'p-1',
        bookingId: booking.id,
        amount: paymentMoney,
        transactionId: 'txn-1',
        method: PaymentMethod.cash,
        status: PaymentStatus.successful,
        paymentDate: DateTime(2023, 12, 21),
      );

      final details = BookingDetails(
        booking: booking,
        payments: [payment],
        services: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingPaymentSummary(
              booking: booking,
              bookingDetails: details,
            ),
          ),
        ),
      );

      expect(find.text('USD 300.00'), findsOneWidget);
      expect(find.text('USD 150.00'), findsNWidgets(2));
      expect(find.text('مدفوع بالكامل'), findsOneWidget);
    });
  });
}
