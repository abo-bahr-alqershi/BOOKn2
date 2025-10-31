using System;
using System.Collections.Generic;
using System.Linq;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Core.ValueObjects;

namespace YemenBooking.Core.Seeds
{
    /// <summary>
    /// مولد البيانات الأولية لكائن Payment مع ربطه بالحجوزات بشكل احترافي
    /// Generates professional seed data for Payment entities linked to bookings
    /// مع دعم حالات متنوعة: دفعات مكتملة، ناقصة، مردودة، معلقة، فاشلة
    /// With support for diverse scenarios: completed, partial, refunded, pending, failed payments
    /// 
    /// ✅ تحديث مهم: الدفعات تُنشأ الآن بنفس عملة الحجز المرتبط بها
    /// ✅ Important Update: Payments are now created with the same currency as their associated booking
    /// </summary>
    public class PaymentSeeder : ISeeder<Payment>
    {
        private readonly IEnumerable<Booking> _bookings;
        private readonly Guid _processedByUserId;

        public PaymentSeeder(IEnumerable<Booking> bookings, Guid processedByUserId)
        {
            _bookings = bookings;
            _processedByUserId = processedByUserId;
        }

        public IEnumerable<Payment> SeedData()
        {
            var payments = new List<Payment>();
            var random = new Random(12345); // Seed ثابت للحصول على نتائج متسقة
            var bookingsList = _bookings.ToList();

            // استخدام 75 حجز لإنشاء دفعات متنوعة (حوالي 120+ دفعة)
            var selectedBookings = bookingsList.Take(Math.Min(75, bookingsList.Count)).ToList();
            
            // طرق الدفع من PaymentMethodEnum
            var paymentMethods = new[]
            {
                PaymentMethodEnum.JwaliWallet,
                PaymentMethodEnum.CashWallet,
                PaymentMethodEnum.OneCashWallet,
                PaymentMethodEnum.FloskWallet,
                PaymentMethodEnum.JaibWallet,
                PaymentMethodEnum.Cash,
                PaymentMethodEnum.Paypal,
                PaymentMethodEnum.CreditCard
            };

            int paymentCounter = 1;

            foreach (var booking in selectedBookings)
            {
                // تحديد عدد الدفعات لهذا الحجز بناءً على المبلغ والعملة وحالة الحجز
                // Determine number of payments based on amount, currency and booking status
                int paymentsCount;
                
                if (booking.TotalPrice.Currency == "USD")
                {
                    // للحجوزات بالدولار
                    if (booking.TotalPrice.Amount > 500)
                    {
                        // حجوزات كبيرة بالدولار: 2-3 دفعات
                        paymentsCount = random.Next(2, 4);
                    }
                    else if (booking.TotalPrice.Amount > 200)
                    {
                        // حجوزات متوسطة بالدولار: 1-2 دفعة
                        paymentsCount = random.Next(1, 3);
                    }
                    else
                    {
                        // حجوزات صغيرة بالدولار: دفعة واحدة
                        paymentsCount = 1;
                    }
                }
                else
                {
                    // للحجوزات بالريال اليمني
                    if (booking.FinalAmount > 500000)
                    {
                        // حجوزات كبيرة بالريال: 2-3 دفعات
                        paymentsCount = random.Next(2, 4);
                    }
                    else if (paymentCounter % 3 == 0)
                    {
                        // بعض الحجوزات المتوسطة: دفعتين
                        paymentsCount = 2;
                    }
                    else
                    {
                        // الحجوزات الصغيرة: دفعة واحدة
                        paymentsCount = 1;
                    }
                }
                
                // حساب المبلغ الإجمالي للحجز بناءً على العملة
                // Calculate total booking amount based on currency
                decimal bookingTotalAmount = booking.TotalPrice.Currency == "USD" 
                    ? booking.TotalPrice.Amount 
                    : booking.FinalAmount;
                
                for (int i = 0; i < paymentsCount; i++)
                {
                    var payment = CreatePayment(
                        booking,
                        i,
                        paymentsCount,
                        bookingTotalAmount,
                        paymentMethods,
                        random,
                        paymentCounter
                    );
                    
                    payments.Add(payment);
                    paymentCounter++;
                }
            }

            return payments;
        }

        private Payment CreatePayment(
            Booking booking,
            int paymentIndex,
            int totalPayments,
            decimal bookingTotalAmount,
            PaymentMethodEnum[] paymentMethods,
            Random random,
            int globalCounter)
        {
            var payment = new Payment
            {
                Id = Guid.NewGuid(),
                BookingId = booking.Id,
                ProcessedBy = _processedByUserId,
                // BaseEntity properties - مهم جداً!
                CreatedAt = DateTime.UtcNow.AddDays(-random.Next(1, 30)),
                UpdatedAt = DateTime.UtcNow.AddDays(-random.Next(0, 5)),
                IsActive = true,
                IsDeleted = false,
                CreatedBy = _processedByUserId
            };

            // تحديد طريقة الدفع بشكل متنوع
            var methodIndex = (globalCounter - 1) % paymentMethods.Length;
            payment.PaymentMethod = paymentMethods[methodIndex];

            // تحديد حالة الدفع بشكل متنوع واحترافي
            PaymentStatus status;
            decimal paymentAmount;
            string transactionPrefix;
            string gatewayPrefix;

            // توزيع الحالات بنسب واقعية:
            // Successful: 60%
            // Pending: 15%
            // Failed: 10%
            // Refunded: 8%
            // PartiallyRefunded: 5%
            // Voided: 2%
            
            int statusSelector = globalCounter % 100;

            if (statusSelector < 60)
            {
                // الدفعات الناجحة (60%)
                status = PaymentStatus.Successful;
                
                // توزيع المبلغ بناءً على ترتيب الدفعة
                if (totalPayments == 1)
                {
                    paymentAmount = bookingTotalAmount;
                }
                else if (totalPayments == 2)
                {
                    paymentAmount = paymentIndex == 0 ? bookingTotalAmount * 0.5m : bookingTotalAmount * 0.5m;
                }
                else // 3 دفعات
                {
                    paymentAmount = paymentIndex == 0 ? bookingTotalAmount * 0.3m 
                        : paymentIndex == 1 ? bookingTotalAmount * 0.4m 
                        : bookingTotalAmount * 0.3m;
                }
                
                transactionPrefix = "TXN-SUCCESS";
                gatewayPrefix = "GW-OK";
                payment.ProcessedAt = booking.BookedAt.AddMinutes(random.Next(5, 30));
                payment.PaymentDate = booking.BookedAt.AddMinutes(random.Next(1, 20));
            }
            else if (statusSelector < 75)
            {
                // الدفعات المعلقة (15%)
                status = PaymentStatus.Pending;
                paymentAmount = totalPayments > 1 && paymentIndex > 0 
                    ? bookingTotalAmount * (1.0m / totalPayments)
                    : bookingTotalAmount * 0.3m;
                transactionPrefix = "TXN-PENDING";
                gatewayPrefix = "GW-PROC";
                payment.ProcessedAt = null;
                payment.PaymentDate = booking.BookedAt.AddMinutes(random.Next(-5, 10));
            }
            else if (statusSelector < 85)
            {
                // الدفعات الفاشلة (10%)
                status = PaymentStatus.Failed;
                paymentAmount = totalPayments == 1 ? bookingTotalAmount : bookingTotalAmount * 0.5m;
                transactionPrefix = "TXN-FAIL";
                gatewayPrefix = "GW-ERR";
                payment.ProcessedAt = booking.BookedAt.AddMinutes(random.Next(1, 5));
                payment.PaymentDate = booking.BookedAt.AddMinutes(random.Next(1, 5));
            }
            else if (statusSelector < 93)
            {
                // الدفعات المستردة كلياً (8%)
                status = PaymentStatus.Refunded;
                paymentAmount = bookingTotalAmount;
                transactionPrefix = "TXN-REFUND";
                gatewayPrefix = "GW-REF";
                payment.ProcessedAt = booking.CheckOut.AddDays(random.Next(1, 5));
                payment.PaymentDate = booking.BookedAt.AddHours(random.Next(1, 12));
            }
            else if (statusSelector < 98)
            {
                // الدفعات المستردة جزئياً (5%)
                status = PaymentStatus.PartiallyRefunded;
                paymentAmount = bookingTotalAmount;
                transactionPrefix = "TXN-PARTREF";
                gatewayPrefix = "GW-PREF";
                payment.ProcessedAt = booking.CheckOut.AddDays(random.Next(1, 3));
                payment.PaymentDate = booking.BookedAt.AddHours(random.Next(2, 24));
            }
            else
            {
                // الدفعات الملغاة (2%)
                status = PaymentStatus.Voided;
                paymentAmount = bookingTotalAmount * 0.5m;
                transactionPrefix = "TXN-VOID";
                gatewayPrefix = "GW-VOID";
                payment.ProcessedAt = booking.BookedAt.AddMinutes(random.Next(30, 120));
                payment.PaymentDate = booking.BookedAt.AddMinutes(random.Next(10, 60));
            }

            payment.Status = status;
            
            // ✅ استخدام نفس عملة الحجز للدفعة - حل احترافي ودقيق
            // Use the same currency as the booking for consistency
            string currency = booking.TotalPrice.Currency;
            
            // ✅ لا حاجة لأي تحويل - المبلغ محسوب بالفعل بالعملة الصحيحة
            // No conversion needed - amount is already calculated in the correct currency
            // paymentAmount محسوب من bookingTotalAmount الذي يستخدم نفس عملة الحجز
            
            // ✅ تأكد من أن المبلغ لا يتجاوز المبلغ الإجمالي للحجز
            // Ensure payment amount doesn't exceed total booking amount
            decimal maxAllowedAmount = bookingTotalAmount * 1.1m; // السماح بـ 10% زيادة للرسوم
            paymentAmount = Math.Min(paymentAmount, maxAllowedAmount);
            
            // ✅ تأكد من أن المبلغ موجب وليس صفر
            // Ensure amount is positive and not zero
            if (paymentAmount <= 0)
            {
                paymentAmount = bookingTotalAmount * 0.1m; // على الأقل 10% من المبلغ
            }

            payment.Amount = new Money(Math.Round(paymentAmount, 2), currency);

            // إنشاء معرفات المعاملات بشكل واقعي
            var timestamp = payment.PaymentDate.ToString("yyyyMMddHHmmss");
            var uniqueId = random.Next(1000, 9999);
            payment.TransactionId = $"{transactionPrefix}-{timestamp}-{uniqueId}";
            payment.GatewayTransactionId = $"{gatewayPrefix}-{booking.Id.ToString().Substring(0, 8).ToUpper()}-{uniqueId}";

            // تحديث تواريخ BaseEntity لتكون منطقية مع تاريخ الدفع
            payment.CreatedAt = payment.PaymentDate.AddMinutes(-random.Next(1, 10));
            payment.UpdatedAt = payment.ProcessedAt ?? payment.PaymentDate.AddMinutes(random.Next(0, 5));

            return payment;
        }
    }
}
 