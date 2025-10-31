using System;
using System.Collections.Generic;
using System.Linq;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;

namespace YemenBooking.Core.Seeds
{
    /// <summary>
    /// مولد العمليات المالية للدفعات - يضمن أن كل دفعة لها عملية مالية
    /// Payment Transaction Seeder - Ensures every payment has a financial transaction
    /// ✅ سيدر حرج لضمان المحاكاة الواقعية للعمليات المالية
    /// </summary>
    public class PaymentTransactionSeeder
    {
        private readonly List<Payment> _payments;
        private readonly List<Booking> _bookings;
        private readonly List<ChartOfAccount> _accounts;
        private readonly List<Unit> _units;
        private readonly List<Property> _properties;
        private int _transactionCounter = 5000; // نبدأ من 5000 لتجنب التعارض

        public PaymentTransactionSeeder(
            List<Payment> payments,
            List<Booking> bookings,
            List<ChartOfAccount> accounts,
            List<Unit> units,
            List<Property> properties)
        {
            _payments = payments ?? new List<Payment>();
            _bookings = bookings ?? new List<Booking>();
            _accounts = accounts ?? new List<ChartOfAccount>();
            _units = units ?? new List<Unit>();
            _properties = properties ?? new List<Property>();
        }

        /// <summary>
        /// إنشاء العمليات المالية لجميع الدفعات
        /// Generate financial transactions for all payments
        /// </summary>
        public IEnumerable<FinancialTransaction> SeedPaymentTransactions()
        {
            var transactions = new List<FinancialTransaction>();
            
            // الحسابات الأساسية
            var cashAccount = _accounts.FirstOrDefault(a => a.AccountNumber == "1101");
            var bankAccount = _accounts.FirstOrDefault(a => a.AccountNumber == "1102");
            var walletAccount = _accounts.FirstOrDefault(a => a.AccountNumber == "1103");
            var revenueAccount = _accounts.FirstOrDefault(a => a.AccountNumber == "4101");
            var refundExpenseAccount = _accounts.FirstOrDefault(a => a.AccountNumber == "5110");
            
            if (cashAccount == null || bankAccount == null || revenueAccount == null)
            {
                Console.WriteLine("⚠️ تحذير: الحسابات الأساسية غير موجودة!");
                return transactions;
            }

            var adminUserId = Guid.Parse("AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA");
            var processedPayments = 0;
            var skippedPayments = 0;

            foreach (var payment in _payments)
            {
                try
                {
                    // البحث عن الحجز المرتبط
                    var booking = _bookings.FirstOrDefault(b => b.Id == payment.BookingId);
                    if (booking == null)
                    {
                        Console.WriteLine($"⚠️ لم يتم العثور على الحجز للدفعة {payment.Id}");
                        skippedPayments++;
                        continue;
                    }

                    // البحث عن الوحدة والعقار
                    var unit = _units.FirstOrDefault(u => u.Id == booking.UnitId);
                    var property = unit != null ? 
                        _properties.FirstOrDefault(p => p.Id == unit.PropertyId) : null;

                    // تحديد الحساب المناسب حسب طريقة الدفع
                    ChartOfAccount paymentMethodAccount;
                    switch (payment.PaymentMethod)
                    {
                        case PaymentMethodEnum.Cash:
                            paymentMethodAccount = cashAccount;
                            break;
                        case PaymentMethodEnum.CreditCard:
                        case PaymentMethodEnum.Paypal:
                            paymentMethodAccount = bankAccount;
                            break;
                        case PaymentMethodEnum.JwaliWallet:
                        case PaymentMethodEnum.CashWallet:
                        case PaymentMethodEnum.OneCashWallet:
                        case PaymentMethodEnum.FloskWallet:
                        case PaymentMethodEnum.JaibWallet:
                            paymentMethodAccount = walletAccount ?? bankAccount;
                            break;
                        default:
                            paymentMethodAccount = bankAccount;
                            break;
                    }

                    // الحصول على حساب العميل
                    var customerAccount = GetUserAccount(booking.UserId, AccountType.Assets) 
                        ?? _accounts.FirstOrDefault(a => a.AccountNumber == "1110");

                    if (customerAccount == null)
                    {
                        Console.WriteLine($"⚠️ لم يتم العثور على حساب للعميل للدفعة {payment.Id}");
                        continue;
                    }

                    // إنشاء القيد المحاسبي حسب حالة الدفعة
                    switch (payment.Status)
                    {
                        case PaymentStatus.Successful:
                            // قيد استلام الدفعة الناجحة
                            transactions.Add(CreateSuccessfulPaymentTransaction(
                                payment, booking, paymentMethodAccount, customerAccount, 
                                property, unit, adminUserId));
                            processedPayments++;
                            break;

                        case PaymentStatus.Refunded:
                            // قيد استرداد المبلغ
                            transactions.Add(CreateRefundTransaction(
                                payment, booking, paymentMethodAccount, customerAccount,
                                refundExpenseAccount, property, unit, adminUserId));
                            processedPayments++;
                            break;

                        case PaymentStatus.PartiallyRefunded:
                            // قيد استرداد جزئي
                            var refundAmount = payment.Amount.Amount * 0.5m; // 50% كمثال
                            transactions.Add(CreatePartialRefundTransaction(
                                payment, booking, paymentMethodAccount, customerAccount,
                                refundExpenseAccount, refundAmount, property, unit, adminUserId));
                            processedPayments++;
                            break;

                        case PaymentStatus.Failed:
                            // لا نسجل قيود للدفعات الفاشلة
                            Console.WriteLine($"⏩ تخطي الدفعة الفاشلة {payment.Id}");
                            skippedPayments++;
                            break;

                        case PaymentStatus.Pending:
                            // قيد دفعة معلقة (مؤقت)
                            Console.WriteLine($"⏳ الدفعة {payment.Id} ما زالت معلقة");
                            skippedPayments++;
                            break;

                        case PaymentStatus.Voided:
                            // قيد إلغاء الدفعة
                            Console.WriteLine($"🚫 الدفعة {payment.Id} ملغاة");
                            skippedPayments++;
                            break;
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"❌ خطأ في معالجة الدفعة {payment.Id}: {ex.Message}");
                    skippedPayments++;
                }
            }

            Console.WriteLine($"✅ تمت معالجة {processedPayments} دفعة بنجاح");
            Console.WriteLine($"⚠️ تم تخطي {skippedPayments} دفعة");

            return transactions;
        }

        /// <summary>
        /// إنشاء قيد لدفعة ناجحة
        /// </summary>
        private FinancialTransaction CreateSuccessfulPaymentTransaction(
            Payment payment, Booking booking, ChartOfAccount paymentMethodAccount,
            ChartOfAccount customerAccount, Property property, Unit unit, Guid adminUserId)
        {
            return new FinancialTransaction
            {
                Id = Guid.NewGuid(),
                TransactionNumber = GenerateTransactionNumber(),
                TransactionDate = payment.PaymentDate,
                EntryType = JournalEntryType.CashReceipts,
                TransactionType = TransactionType.FinalPayment,
                DebitAccountId = paymentMethodAccount.Id,
                CreditAccountId = customerAccount.Id,
                Amount = payment.Amount.Amount,
                Currency = payment.Amount.Currency,
                ExchangeRate = 1,
                BaseAmount = payment.Amount.Amount,
                Description = $"استلام دفعة للحجز {booking.Id.ToString().Substring(0, 8)}",
                Narration = $"دفعة بواسطة {payment.PaymentMethod} - {payment.TransactionId}",
                ReferenceNumber = payment.TransactionId,
                DocumentType = "PaymentReceipt",
                BookingId = booking.Id,
                PaymentId = payment.Id,
                FirstPartyUserId = booking.UserId,
                PropertyId = property?.Id,
                UnitId = unit?.Id,
                Status = TransactionStatus.Posted,
                IsPosted = true,
                PostingDate = payment.ProcessedAt ?? payment.PaymentDate,
                FiscalYear = payment.PaymentDate.Year,
                FiscalPeriod = payment.PaymentDate.Month,
                NetAmount = payment.Amount.Amount,
                CreatedBy = adminUserId,
                CreatedAt = payment.PaymentDate,
                UpdatedAt = DateTime.UtcNow,
                IsAutomatic = true,
                AutomaticSource = "PaymentTransactionSeeder"
            };
        }

        /// <summary>
        /// إنشاء قيد استرداد كامل
        /// </summary>
        private FinancialTransaction CreateRefundTransaction(
            Payment payment, Booking booking, ChartOfAccount paymentMethodAccount,
            ChartOfAccount customerAccount, ChartOfAccount refundExpenseAccount,
            Property property, Unit unit, Guid adminUserId)
        {
            var refundAccount = refundExpenseAccount ?? customerAccount;
            var refundDate = payment.UpdatedAt != default(DateTime) ? payment.UpdatedAt : payment.PaymentDate.AddDays(1);
            
            return new FinancialTransaction
            {
                Id = Guid.NewGuid(),
                TransactionNumber = GenerateTransactionNumber(),
                TransactionDate = refundDate,
                EntryType = JournalEntryType.CashPayments,
                TransactionType = TransactionType.Refund,
                DebitAccountId = refundAccount.Id,
                CreditAccountId = paymentMethodAccount.Id,
                Amount = payment.Amount.Amount,
                Currency = payment.Amount.Currency,
                ExchangeRate = 1,
                BaseAmount = payment.Amount.Amount,
                Description = $"استرداد مبلغ للحجز {booking.Id.ToString().Substring(0, 8)}",
                Narration = $"استرداد كامل للدفعة {payment.TransactionId}",
                ReferenceNumber = $"REF-{payment.TransactionId}",
                DocumentType = "RefundVoucher",
                BookingId = booking.Id,
                PaymentId = payment.Id,
                FirstPartyUserId = booking.UserId,
                PropertyId = property?.Id,
                UnitId = unit?.Id,
                Status = TransactionStatus.Posted,
                IsPosted = true,
                PostingDate = refundDate,
                FiscalYear = refundDate.Year,
                FiscalPeriod = refundDate.Month,
                NetAmount = -payment.Amount.Amount, // سالب لأنه استرداد
                CreatedBy = adminUserId,
                CreatedAt = refundDate,
                UpdatedAt = DateTime.UtcNow,
                IsAutomatic = true,
                AutomaticSource = "PaymentTransactionSeeder"
            };
        }

        /// <summary>
        /// إنشاء قيد استرداد جزئي
        /// </summary>
        private FinancialTransaction CreatePartialRefundTransaction(
            Payment payment, Booking booking, ChartOfAccount paymentMethodAccount,
            ChartOfAccount customerAccount, ChartOfAccount refundExpenseAccount,
            decimal refundAmount, Property property, Unit unit, Guid adminUserId)
        {
            var refundAccount = refundExpenseAccount ?? customerAccount;
            var refundDate = payment.UpdatedAt != default(DateTime) ? payment.UpdatedAt : payment.PaymentDate.AddDays(1);
            
            return new FinancialTransaction
            {
                Id = Guid.NewGuid(),
                TransactionNumber = GenerateTransactionNumber(),
                TransactionDate = refundDate,
                EntryType = JournalEntryType.CashPayments,
                TransactionType = TransactionType.Refund,
                DebitAccountId = refundAccount.Id,
                CreditAccountId = paymentMethodAccount.Id,
                Amount = refundAmount,
                Currency = payment.Amount.Currency,
                ExchangeRate = 1,
                BaseAmount = refundAmount,
                Description = $"استرداد جزئي للحجز {booking.Id.ToString().Substring(0, 8)}",
                Narration = $"استرداد {(refundAmount / payment.Amount.Amount * 100):F0}% من الدفعة {payment.TransactionId}",
                ReferenceNumber = $"PREF-{payment.TransactionId}",
                DocumentType = "PartialRefundVoucher",
                BookingId = booking.Id,
                PaymentId = payment.Id,
                FirstPartyUserId = booking.UserId,
                PropertyId = property?.Id,
                UnitId = unit?.Id,
                Status = TransactionStatus.Posted,
                IsPosted = true,
                PostingDate = refundDate,
                FiscalYear = refundDate.Year,
                FiscalPeriod = refundDate.Month,
                NetAmount = -refundAmount, // سالب لأنه استرداد
                CreatedBy = adminUserId,
                CreatedAt = refundDate,
                UpdatedAt = DateTime.UtcNow,
                IsAutomatic = true,
                AutomaticSource = "PaymentTransactionSeeder"
            };
        }

        /// <summary>
        /// الحصول على حساب المستخدم
        /// </summary>
        private ChartOfAccount GetUserAccount(Guid userId, AccountType accountType)
        {
            return _accounts.FirstOrDefault(a => 
                a.UserId == userId && a.AccountType == accountType);
        }

        /// <summary>
        /// توليد رقم قيد تسلسلي
        /// </summary>
        private string GenerateTransactionNumber()
        {
            return $"PAY-{DateTime.UtcNow.Year}-{_transactionCounter++:D6}";
        }
    }
}
