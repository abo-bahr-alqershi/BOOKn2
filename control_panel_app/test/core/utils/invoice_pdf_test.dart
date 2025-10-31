import 'package:bookn_cp_app/core/utils/invoice_pdf.dart';
import 'package:bookn_cp_app/core/enums/booking_status.dart';
import 'package:bookn_cp_app/features/admin_bookings/domain/entities/booking.dart';
import 'package:bookn_cp_app/features/admin_bookings/domain/entities/booking_details.dart'
    show BookingDetails, GuestInfo;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InvoicePdfGenerator', () {
    test('generates invoice when booking id shorter than 8 chars', () async {
      const bookingId = 'ABC123';

      final booking = Booking(
        id: bookingId,
        userId: 'user-1',
        unitId: 'unit-1',
        checkIn: DateTime(2024, 1, 1),
        checkOut: DateTime(2024, 1, 5),
        guestsCount: 2,
        totalPrice: const Money(
          amount: 100.0,
          currency: 'USD',
          formattedAmount: 'USD 100.00',
        ),
        status: BookingStatus.confirmed,
        bookedAt: DateTime(2023, 12, 1),
        userName: 'Test User',
        unitName: 'Test Unit',
      );

      final details = BookingDetails(
        booking: booking,
        payments: const [],
        services: const [],
      );

      final pdfBytes = await InvoicePdfGenerator.generate(details);

      expect(pdfBytes, isNotEmpty);
    });

    test('resolveGuestContact falls back to booking info when guest empty', () {
      final booking = Booking(
        id: 'booking-1',
        userId: 'user-1',
        unitId: 'unit-1',
        checkIn: DateTime(2024, 1, 1),
        checkOut: DateTime(2024, 1, 2),
        guestsCount: 2,
        totalPrice: const Money(
          amount: 200,
          currency: 'USD',
          formattedAmount: 'USD 200.00',
        ),
        status: BookingStatus.confirmed,
        bookedAt: DateTime(2023, 12, 20),
        userName: 'Fallback User',
        unitName: 'Test Unit',
        userPhone: '+967712345678',
        userEmail: 'user@example.com',
      );

      const emptyGuest = GuestInfo(name: '', email: '', phone: '');

      final contact = InvoicePdfGenerator.resolveGuestContact(
        booking,
        emptyGuest,
      );

      expect(contact.name, 'Fallback User');
      expect(contact.phone, '+967 712 345 678');
      expect(contact.email, 'user@example.com');
    });

    test('resolveGuestContact prefers non-empty guest info', () {
      final booking = Booking(
        id: 'booking-2',
        userId: 'user-2',
        unitId: 'unit-2',
        checkIn: DateTime(2024, 2, 1),
        checkOut: DateTime(2024, 2, 3),
        guestsCount: 3,
        totalPrice: const Money(
          amount: 300,
          currency: 'USD',
          formattedAmount: 'USD 300.00',
        ),
        status: BookingStatus.confirmed,
        bookedAt: DateTime(2023, 12, 25),
        userName: 'Booking User',
        unitName: 'Another Unit',
        userPhone: '+967733333333',
        userEmail: 'booking@example.com',
      );

      const guest = GuestInfo(
        name: 'Guest Name',
        email: 'guest@example.com',
        phone: '+967701234567',
      );

      final contact = InvoicePdfGenerator.resolveGuestContact(
        booking,
        guest,
      );

      expect(contact.name, 'Guest Name');
      expect(contact.phone, '+967 701 234 567');
      expect(contact.email, 'guest@example.com');
    });
  });
}
