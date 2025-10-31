import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'arabic_text_utils.dart';
import '../../features/admin_bookings/domain/entities/booking.dart';
import '../../features/admin_bookings/domain/entities/booking_details.dart';
import '../utils/formatters.dart';

class InvoicePdfGenerator {
  InvoicePdfGenerator._();

  // Professional Colors - Similar to Booking.com
  static const PdfColor primaryBlue =
      PdfColor.fromInt(0xFF003580); // Booking.com blue
  static const PdfColor darkBlue = PdfColor.fromInt(0xFF00224F);
  static const PdfColor lightBlue = PdfColor.fromInt(0xFF0077CC);
  static const PdfColor green = PdfColor.fromInt(0xFF008009);
  static const PdfColor orange = PdfColor.fromInt(0xFFFF8000);
  static const PdfColor red = PdfColor.fromInt(0xFFCC0000);

  // Neutral Colors
  static const PdfColor black = PdfColor.fromInt(0xFF262626);
  static const PdfColor darkGray = PdfColor.fromInt(0xFF333333);
  static const PdfColor gray = PdfColor.fromInt(0xFF6B6B6B);
  static const PdfColor lightGray = PdfColor.fromInt(0xFFE7E7E7);
  static const PdfColor veryLightGray = PdfColor.fromInt(0xFFF5F5F5);
  static const PdfColor white = PdfColors.white;

  static Future<Uint8List> generate(BookingDetails details) async {
    final doc = pw.Document();
    final booking = details.booking;
    final property = details.propertyDetails;
    final guest = details.guestInfo;
    final guestContact = resolveGuestContact(booking, guest);

    final currency = booking.totalPrice.currency;
    final bookingReference = _formatBookingReference(booking.id);
    final invoiceNumber = _generateInvoiceNumber(
      bookingId: booking.id,
      bookedAt: booking.bookedAt,
    );
    final issueDate = booking.bookedAt;

    // Load fonts
    pw.Font arabicFont;
    pw.Font arabicBold;
    Uint8List? logoData;

    try {
      final regularData =
          await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
      arabicFont = pw.Font.ttf(regularData);
      arabicBold = pw.Font.ttf(boldData);
    } catch (_) {
      arabicFont = pw.Font.helvetica();
      arabicBold = pw.Font.helveticaBold();
    }

    try {
      logoData = (await rootBundle.load('assets/images/logo.png'))
          .buffer
          .asUint8List();
    } catch (_) {
      logoData = null;
    }

    // Professional Header - Clean and Simple
    pw.Widget buildHeader() {
      return pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Invoice Title (moved to left for Arabic)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: primaryBlue,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: _rtlText(
                      'فاتورة',
                      style: pw.TextStyle(
                        font: arabicBold,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: white,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  _rtlText(
                    'رقم الفاتورة: $invoiceNumber',
                    style: pw.TextStyle(
                      font: arabicBold,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: black,
                    ),
                  ),
                  _rtlText(
                    'التاريخ: ${DateFormat('dd/MM/yyyy').format(issueDate)}',
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontSize: 10,
                      color: gray,
                    ),
                  ),
                ],
              ),
              // Logo and Company Info (moved to right for Arabic)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if (logoData != null)
                    pw.Image(
                      pw.MemoryImage(logoData),
                      height: 40,
                      width: 120,
                      fit: pw.BoxFit.contain,
                    )
                  else
                    _rtlText(
                      'يمن بوكينج',
                      style: pw.TextStyle(
                        font: arabicBold,
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryBlue,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  pw.SizedBox(height: 4),
                  _rtlText(
                    'منصة الحجوزات الإلكترونية',
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontSize: 10,
                      color: gray,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(color: lightGray, thickness: 1),
        ],
      );
    }

    // Booking Confirmation Section
    pw.Widget buildBookingConfirmation() {
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: veryLightGray,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: lightGray, width: 1),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: _getStatusColor(booking.status.name),
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: _rtlText(
                    _getStatusTextArabic(booking.status.name),
                    style: pw.TextStyle(
                      font: arabicBold,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: white,
                    ),
                  ),
                ),
                _rtlText(
                  'تأكيد الحجز',
                  style: pw.TextStyle(
                    font: arabicBold,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: darkBlue,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            _rtlText(
              'رقم التأكيد: $bookingReference',
              style: pw.TextStyle(
                font: arabicBold,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: primaryBlue,
              ),
            ),
          ],
        ),
      );
    }

    // Guest and Property Information
    pw.Widget buildGuestPropertyInfo() {
      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Property Information (moved to right for Arabic)
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _rtlText(
                  'معلومات المنشأة',
                  style: pw.TextStyle(
                    font: arabicBold,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: darkBlue,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: lightGray, width: 1),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _buildInfoRowArabic('المنشأة:',
                          property?.name ?? 'يمن بوكينج', arabicFont),
                      if (property?.address != null)
                        _buildInfoRowArabic(
                            'العنوان:', property?.address ?? '---', arabicFont),
                      if (property?.phone != null)
                        _buildInfoRowArabic('رقم التواصل:',
                            property?.phone ?? '---', arabicFont),
                      _buildInfoRowArabic(
                          'الرقم الضريبي:', '------------', arabicFont),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 20),
          // Guest Information (moved to left for Arabic)
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _rtlText(
                  'معلومات النزيل',
                  style: pw.TextStyle(
                    font: arabicBold,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: darkBlue,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: lightGray, width: 1),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _buildInfoRowArabic(
                          'الاسم:', guestContact.name, arabicFont),
                      if (guestContact.phone != null)
                        _buildInfoRowArabic(
                            'الهاتف:', guestContact.phone!, arabicFont),
                      if (guestContact.email != null)
                        _buildInfoRowArabic('البريد الإلكتروني:',
                            guestContact.email!, arabicFont),
                      _buildInfoRowArabic('الجنسية:',
                          guest?.nationality ?? 'غير محدد', arabicFont),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Booking Details Section
    pw.Widget buildBookingDetails() {
      final guestCount = booking.guestsCount;

      return pw.Container(
        margin: const pw.EdgeInsets.symmetric(vertical: 16),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _rtlText(
              'تفاصيل الحجز',
              style: pw.TextStyle(
                font: arabicBold,
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: darkBlue,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: lightGray, width: 1),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                children: [
                  // Header Row
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: const pw.BoxDecoration(
                      color: veryLightGray,
                      border: pw.Border(
                        bottom: pw.BorderSide(color: lightGray, width: 1),
                      ),
                    ),
                    child: _rtlRow(
                      children: [
                        pw.Expanded(
                          child: _rtlText(
                            'عدد الضيوف',
                            style: pw.TextStyle(
                              font: arabicBold,
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: darkGray,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Expanded(
                          child: _rtlText(
                            'الليالي',
                            style: pw.TextStyle(
                              font: arabicBold,
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: darkGray,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Expanded(
                          child: _rtlText(
                            'المغادرة',
                            style: pw.TextStyle(
                              font: arabicBold,
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: darkGray,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Expanded(
                          child: _rtlText(
                            'الوصول',
                            style: pw.TextStyle(
                              font: arabicBold,
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: darkGray,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: _rtlText(
                            'الوحدة',
                            style: pw.TextStyle(
                              font: arabicBold,
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: darkGray,
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Data Row
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    child: _rtlRow(
                      children: [
                        pw.Expanded(
                          child: _rtlText(
                            '$guestCount',
                            style: pw.TextStyle(
                              font: arabicFont,
                              fontSize: 11,
                              color: black,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Expanded(
                          child: _rtlText(
                            '${booking.nights}',
                            style: pw.TextStyle(
                              font: arabicFont,
                              fontSize: 11,
                              color: black,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Expanded(
                          child: _rtlText(
                            DateFormat('dd/MM/yyyy').format(booking.checkOut),
                            style: pw.TextStyle(
                              font: arabicFont,
                              fontSize: 10,
                              color: black,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Expanded(
                          child: _rtlText(
                            DateFormat('dd/MM/yyyy').format(booking.checkIn),
                            style: pw.TextStyle(
                              font: arabicFont,
                              fontSize: 10,
                              color: black,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: _rtlText(
                            booking.unitName,
                            style: pw.TextStyle(
                              font: arabicFont,
                              fontSize: 11,
                              color: black,
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Pricing Breakdown
    pw.Widget buildPricingBreakdown() {
      final services = details.services;
      final servicesTotal = services.fold<double>(
          0.0, (sum, service) => sum + service.totalPrice.amount);
      final basePrice =
          math.max(0.0, booking.totalPrice.amount - servicesTotal);
      final subtotal = basePrice + servicesTotal;

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _rtlText(
            'تفاصيل السعر',
            style: pw.TextStyle(
              font: arabicBold,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: darkBlue,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: lightGray, width: 1),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              children: [
                // Room charges
                _buildPriceRowArabic(
                  'رسوم الغرفة (${booking.nights} ليالي)',
                  _formatMoneyArabic(basePrice, currency),
                  arabicFont,
                  arabicBold,
                  isHeader: false,
                ),
                // Additional services
                ...services.map(
                  (service) => _buildPriceRowArabic(
                    '${service.name} (${service.quantity}x)',
                    _formatMoneyArabic(
                      service.totalPrice.amount,
                      service.totalPrice.currency,
                    ),
                    arabicFont,
                    arabicBold,
                  ),
                ),
                if (services.isNotEmpty) ...[
                  _buildPriceRowArabic(
                    'إجمالي الخدمات الإضافية',
                    _formatMoneyArabic(servicesTotal, currency),
                    arabicFont,
                    arabicBold,
                  ),
                  pw.Container(
                    margin: const pw.EdgeInsets.symmetric(horizontal: 12),
                    height: 1,
                    color: lightGray,
                  ),
                ],
                _buildPriceRowArabic(
                  'إجمالي الرسوم',
                  _formatMoneyArabic(subtotal, currency),
                  arabicFont,
                  arabicBold,
                  isHeader: services.isNotEmpty,
                ),
                // Total
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: const pw.BoxDecoration(
                    color: veryLightGray,
                  ),
                  child: _rtlRow(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _rtlText(
                        _formatMoneyArabic(booking.totalPrice.amount, currency),
                        style: pw.TextStyle(
                          font: arabicBold,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: darkBlue,
                        ),
                      ),
                      _rtlText(
                        'المبلغ الإجمالي',
                        style: pw.TextStyle(
                          font: arabicBold,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: darkBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Payment Information
    pw.Widget buildPaymentInfo() {
      final paid = details.totalPaid;
      final remaining = details.remainingAmount;
      final payments = details.payments;

      return pw.Container(
        margin: const pw.EdgeInsets.symmetric(vertical: 16),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Payment History (moved to left for Arabic)
            if (payments.isNotEmpty)
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _rtlText(
                      'سجل المدفوعات',
                      style: pw.TextStyle(
                        font: arabicBold,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: darkBlue,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: lightGray, width: 1),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Column(
                        children: payments
                            .map((payment) => pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(
                                      vertical: 4),
                                  decoration: const pw.BoxDecoration(
                                    border: pw.Border(
                                      bottom: pw.BorderSide(
                                          color: lightGray, width: 0.5),
                                    ),
                                  ),
                                  child: _rtlRow(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      _rtlText(
                                        _formatMoneyArabic(
                                            payment.amount.amount,
                                            payment.amount.currency),
                                        style: pw.TextStyle(
                                          font: arabicBold,
                                          fontSize: 10,
                                          fontWeight: pw.FontWeight.bold,
                                          color: green,
                                        ),
                                      ),
                                      _rtlText(
                                        DateFormat('dd/MM/yyyy')
                                            .format(payment.paymentDate),
                                        style: pw.TextStyle(
                                            font: arabicFont,
                                            fontSize: 10,
                                            color: gray),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            pw.SizedBox(width: 20),
            // Payment Summary (moved to right for Arabic)
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: remaining.amount > 0
                      ? PdfColors.orange50
                      : PdfColors.green50,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(
                    color: remaining.amount > 0 ? orange : green,
                    width: 1,
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _rtlText(
                      'ملخص المدفوعات',
                      style: pw.TextStyle(
                        font: arabicBold,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: darkBlue,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    _buildPaymentRowArabic(
                        'المبلغ الإجمالي:',
                        _formatMoneyArabic(booking.totalPrice.amount, currency),
                        arabicFont,
                        arabicBold),
                    _buildPaymentRowArabic(
                        'المبلغ المدفوع:',
                        _formatMoneyArabic(paid.amount, currency),
                        arabicFont,
                        arabicBold,
                        color: green),
                    if (remaining.amount > 0)
                      _buildPaymentRowArabic(
                          'المبلغ المتبقي:',
                          _formatMoneyArabic(remaining.amount, currency),
                          arabicFont,
                          arabicBold,
                          color: orange),
                    pw.SizedBox(height: 8),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: remaining.amount > 0 ? orange : green,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: _rtlText(
                        remaining.amount > 0
                            ? 'الدفع عند الوصول'
                            : 'مدفوع بالكامل',
                        style: pw.TextStyle(
                          font: arabicBold,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: white,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Important Information
    pw.Widget buildImportantInfo() {
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.blue50,
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border.all(color: lightBlue, width: 1),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _rtlRow(
              children: [
                pw.Container(
                  width: 20,
                  height: 20,
                  decoration: const pw.BoxDecoration(
                    color: lightBlue,
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'i',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: white,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                _rtlText(
                  'معلومات مهمة',
                  style: pw.TextStyle(
                    font: arabicBold,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: darkBlue,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            _buildBulletPointArabic(
                'وقت تسجيل الوصول: 12:00 ظهرا - وقت المغادرة: 12:00 ظهرا',
                arabicFont),
            _buildBulletPointArabic(
                'مطلوب إثبات هوية صالح عند تسجيل الوصول', arabicFont),
            _buildBulletPointArabic(
                'تطبق سياسة الإلغاء حسب شروط الحجز', arabicFont),
            _buildBulletPointArabic(
                'للمساعدة، تواصل مع خدمة العملاء على مدار الساعة', arabicFont),
          ],
        ),
      );
    }

    // Footer
    pw.Widget buildFooter() {
      return pw.Container(
        margin: const pw.EdgeInsets.only(top: 20),
        padding: const pw.EdgeInsets.only(top: 16),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(color: lightGray, width: 1),
          ),
        ),
        child: pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data:
                      'BOOKING:$bookingReference|AMOUNT:${booking.totalPrice.amount}|INV:$invoiceNumber',
                  width: 60,
                  height: 60,
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    _rtlText(
                      'خدمة العملاء',
                      style: pw.TextStyle(
                        font: arabicBold,
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: darkGray,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 4),
                    _rtlText(
                      '+967 772 878 087',
                      style: pw.TextStyle(
                          font: arabicFont, fontSize: 10, color: gray),
                      textAlign: pw.TextAlign.center,
                    ),
                    _rtlText(
                      'متاح 24/7',
                      style: pw.TextStyle(
                          font: arabicFont, fontSize: 9, color: gray),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _rtlText(
                      'منصة يمن بوكينج',
                      style: pw.TextStyle(
                        font: arabicBold,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    _rtlText(
                      'www.yemenbooking.com',
                      style: pw.TextStyle(
                          font: arabicFont, fontSize: 10, color: gray),
                    ),
                    _rtlText(
                      'support@yemenbooking.com',
                      style: pw.TextStyle(
                          font: arabicFont, fontSize: 10, color: gray),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: veryLightGray,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Center(
                child: _rtlText(
                  'شكراً لاختياركم يمن بوكينج. نتمنى لكم إقامة سعيدة!',
                  style: pw.TextStyle(
                    font: arabicBold,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: darkBlue,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            _rtlText(
              '© ${DateTime.now().year} يمن بوكينج. جميع الحقوق محفوظة. هذه فاتورة إلكترونية صادرة من النظام.',
              style: pw.TextStyle(font: arabicFont, fontSize: 8, color: gray),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Build PDF Document
    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(40),
          theme: pw.ThemeData.withFont(
            base: arabicFont,
            bold: arabicBold,
          ),
          pageFormat: PdfPageFormat.a4,
        ),
        build: (context) => [
          buildHeader(),
          buildBookingConfirmation(),
          pw.SizedBox(height: 16),
          buildGuestPropertyInfo(),
          buildBookingDetails(),
          buildPricingBreakdown(),
          buildPaymentInfo(),
          buildImportantInfo(),
          buildFooter(),
        ],
      ),
    );

    return doc.save();
  }

  // Helper Methods for Arabic
  static pw.Widget _rtlRow({
    required List<pw.Widget> children,
    pw.MainAxisAlignment mainAxisAlignment = pw.MainAxisAlignment.start,
    pw.CrossAxisAlignment crossAxisAlignment = pw.CrossAxisAlignment.center,
    pw.MainAxisSize mainAxisSize = pw.MainAxisSize.max,
  }) {
    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: children,
      ),
    );
  }

  static String _shapeArabic(String text) => ArabicTextUtils.shape(text);

  static pw.Widget _rtlText(
    String text, {
    pw.TextStyle? style,
    pw.TextAlign textAlign = pw.TextAlign.right,
    pw.TextOverflow? overflow,
    int? maxLines,
  }) {
    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Text(
        _shapeArabic(text),
        style: style,
        textAlign: textAlign,
        overflow: overflow,
        maxLines: maxLines,
      ),
    );
  }

  static pw.Widget _buildInfoRowArabic(
      String label, String value, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: _rtlRow(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: _rtlText(
              label,
              style: pw.TextStyle(
                font: font,
                fontSize: 10,
                color: gray,
              ),
            ),
          ),
          pw.Expanded(
            child: _rtlText(
              value,
              style: pw.TextStyle(
                font: font,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPriceRowArabic(
      String label, String amount, pw.Font font, pw.Font boldFont,
      {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: isHeader ? veryLightGray : white,
        border: const pw.Border(
          bottom: pw.BorderSide(color: lightGray, width: 0.5),
        ),
      ),
      child: _rtlRow(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _rtlText(
            amount,
            style: pw.TextStyle(
              font: isHeader ? boldFont : font,
              fontSize: 11,
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isHeader ? darkGray : black,
            ),
          ),
          _rtlText(
            label,
            style: pw.TextStyle(
              font: isHeader ? boldFont : font,
              fontSize: 11,
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isHeader ? darkGray : black,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPaymentRowArabic(
      String label, String amount, pw.Font font, pw.Font boldFont,
      {PdfColor? color}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: _rtlRow(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _rtlText(
            amount,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: color ?? black,
            ),
          ),
          _rtlText(
            label,
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
              color: gray,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBulletPointArabic(String text, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: _rtlRow(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 4,
            height: 4,
            margin: const pw.EdgeInsets.only(top: 4, left: 8),
            decoration: const pw.BoxDecoration(
              color: gray,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: _rtlText(
              text,
              style: pw.TextStyle(
                font: font,
                fontSize: 10,
                color: darkGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatMoneyArabic(double amount, String currency) {
    final formatter = NumberFormat('#,##0.00');
    final currencyArabic = _getCurrencyArabic(currency);
    return '${formatter.format(amount)} $currencyArabic';
  }

  static String _getCurrencyArabic(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return 'دولار';
      case 'YER':
        return 'ريال';
      case 'SAR':
        return 'ريال سعودي';
      case 'EUR':
        return 'يورو';
      default:
        return currency;
    }
  }

  static String _getStatusTextArabic(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'مؤكد';
      case 'pending':
        return 'معلق';
      case 'cancelled':
        return 'ملغي';
      case 'completed':
        return 'مكتمل';
      default:
        return status;
    }
  }

  static PdfColor _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return green;
      case 'pending':
        return orange;
      case 'cancelled':
        return red;
      case 'completed':
        return primaryBlue;
      default:
        return gray;
    }
  }

  static String _generateInvoiceNumber({
    required String bookingId,
    required DateTime bookedAt,
  }) {
    final sanitizedId =
        bookingId.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    final idSegment = sanitizedId.isEmpty
        ? '000000'
        : sanitizedId.length >= 6
            ? sanitizedId.substring(0, 6)
            : sanitizedId.padRight(6, '0');

    final year = bookedAt.year.toString();
    final month = bookedAt.month.toString().padLeft(2, '0');
    final day = bookedAt.day.toString().padLeft(2, '0');

    return 'INV$year$month$day-$idSegment';
  }

  static String _formatBookingReference(String bookingId) {
    if (bookingId.isEmpty) return 'N/A';

    final cleaned =
        bookingId.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    if (cleaned.isEmpty) return 'N/A';

    final padded = cleaned.length >= 9
        ? cleaned.substring(0, 9)
        : cleaned.padRight(9, '0');

    return '${padded.substring(0, 3)}-${padded.substring(3, 6)}-${padded.substring(6, 9)}';
  }

  @visibleForTesting
  static ({String name, String? phone, String? email}) resolveGuestContact(
    Booking booking,
    GuestInfo? guest,
  ) {
    final name = _coalesceNonEmpty([
          guest?.name,
          booking.userName,
        ]) ??
        'ضيف';

    final phone = _coalesceNonEmpty([
      guest?.phone,
      booking.userPhone,
    ]);

    final email = _coalesceNonEmpty([
      guest?.email,
      booking.userEmail,
    ]);

    return (
      name: name,
      phone: phone != null ? Formatters.formatPhoneNumber(phone) : null,
      email: email,
    );
  }

  static String? _coalesceNonEmpty(List<String?> values) {
    for (final value in values) {
      final normalized = _normalize(value);
      if (normalized != null) {
        return normalized;
      }
    }
    return null;
  }

  static String? _normalize(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }
}
