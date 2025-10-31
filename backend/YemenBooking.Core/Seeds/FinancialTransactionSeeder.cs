using System;
using System.Collections.Generic;
using System.Linq;
using Bogus;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Core.ValueObjects;

namespace YemenBooking.Core.Seeds
{
    /// <summary>
    /// مولد البيانات الأولية للعمليات المالية
    /// Financial Transactions Seeder - Generates realistic financial transaction data
    /// يحاكي قيود محاسبية واقعية: حجوزات، عمولات، دفعات، استردادات، إلغاءات
    /// </summary>
    public class FinancialTransactionSeeder : ISeeder<FinancialTransaction>
    {
        private readonly List<Booking> _bookings;
        private readonly List<Payment> _payments;
        private readonly List<User> _users;
        private readonly List<Property> _properties;
        private readonly List<Unit> _units;
        private readonly List<ChartOfAccount> _accounts;
        
        // Counter for transaction numbers
        private int _transactionCounter = 1;
        
        public FinancialTransactionSeeder(
            List<Booking> bookings = null, 
            List<Payment> payments = null,
            List<User> users = null,
            List<Property> properties = null,
            List<Unit> units = null,
            List<ChartOfAccount> accounts = null)
        {
            _bookings = bookings ?? new List<Booking>();
            _payments = payments ?? new List<Payment>();
            _users = users ?? new List<User>();
            _properties = properties ?? new List<Property>();
            _units = units ?? new List<Unit>();
            _accounts = accounts ?? new List<ChartOfAccount>();
        }
        
        public IEnumerable<FinancialTransaction> SeedData()
        {
            var transactions = new List<FinancialTransaction>();
            var faker = new Faker("ar");
            var adminUserId = Guid.Parse("AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA");
            
            // إذا لم تكن هناك بيانات كافية، نعيد قائمة فارغة
            if (!_bookings.Any() || !_accounts.Any())
                return transactions;
            
            // الحصول على الحسابات الأساسية
            var cashAccount = _accounts.FirstOrDefault(a => a.NameAr == "النقدية" && a.IsSystemAccount)
                ?? _accounts.FirstOrDefault(a => a.AccountNumber == "1101");
            var bankAccount = _accounts.FirstOrDefault(a => a.NameAr == "البنك" && a.IsSystemAccount)
                ?? _accounts.FirstOrDefault(a => a.AccountNumber == "1102");
            var revenueAccount = _accounts.FirstOrDefault(a => a.NameAr == "إيرادات الحجوزات" && a.IsSystemAccount)
                ?? _accounts.FirstOrDefault(a => a.AccountNumber == "4101");
            var commissionAccount = _accounts.FirstOrDefault(a => a.NameAr == "عمولات المنصة" && a.IsSystemAccount)
                ?? _accounts.FirstOrDefault(a => a.AccountNumber == "4110");
            var platformAccount = _accounts.FirstOrDefault(a => a.NameAr == "حساب المنصة" && a.IsSystemAccount)
                ?? _accounts.FirstOrDefault(a => a.AccountNumber == "3100");
            var refundExpenseAccount = _accounts.FirstOrDefault(a => a.NameAr == "مردودات المبيعات" && a.IsSystemAccount)
                ?? _accounts.FirstOrDefault(a => a.AccountNumber == "5130");
            
            if (cashAccount == null || bankAccount == null || revenueAccount == null || 
                commissionAccount == null || platformAccount == null)
            {
                // إذا لم نجد الحسابات الأساسية، نعيد قائمة فارغة
                return transactions;
            }
            
            // معالجة كل حجز وإنشاء القيود المحاسبية المناسبة
            // ⚠️ مهم جداً: نعالج جميع الحجوزات بدون استثناء لضمان المحاكاة الواقعية
            foreach (var booking in _bookings) // نعالج جميع الحجوزات وليس فقط 50
            {
                try
                {
                    var unit = _units.FirstOrDefault(u => u.Id == booking.UnitId);
                    if (unit == null)
                    {
                        // إذا لم نجد الوحدة، نسجل تحذير ونستمر
                        Console.WriteLine($"⚠️ تحذير: لم يتم العثور على الوحدة للحجز {booking.Id}");
                        continue;
                    }
                    
                    var property = _properties.FirstOrDefault(p => p.Id == unit.PropertyId);
                    if (property == null)
                    {
                        Console.WriteLine($"⚠️ تحذير: لم يتم العثور على العقار للوحدة {unit.Id}");
                        continue;
                    }
                    
                    var totalAmount = booking.TotalPrice.Amount;
                    var currency = booking.TotalPrice.Currency;
            var commissionRate = 0.05m; // عمولة 5% وفق المواصفات
                    var commissionAmount = totalAmount * commissionRate;
                    var ownerAmount = totalAmount - commissionAmount;
                    
                    // ✅ تحسين: البحث عن حسابات المستخدم مع ضمان إنشاء حسابات بديلة
                    var customerAccount = GetOrCreateUserAccount(booking.UserId, "عميل", AccountType.Assets);
                    var ownerAccount = GetOrCreateUserAccount(property.OwnerId, "مالك", AccountType.Liabilities);
                    
                    // ✅ ضمان وجود حسابات صالحة دائماً - لا نتخطى أي حجز
                    var guaranteedDebitAccount = customerAccount ?? 
                        CreateTemporaryAccount(booking.UserId, "عميل", AccountType.Assets) ?? 
                        cashAccount ?? revenueAccount;
                    
                    var guaranteedCreditAccount = revenueAccount ?? platformAccount;
                    
                    var guaranteedOwnerAccount = ownerAccount ?? 
                        CreateTemporaryAccount(property.OwnerId, "مالك", AccountType.Liabilities) ?? 
                        platformAccount ?? revenueAccount;
                    
                    // ✅ التأكد من وجود حسابات قبل المتابعة
                    if (guaranteedDebitAccount == null || guaranteedCreditAccount == null)
                    {
                        Console.WriteLine($"❌ خطأ حرج: لا توجد حسابات أساسية للحجز {booking.Id}");
                        continue; // هذا نادر جداً ويحدث فقط إذا فشل كل شيء
                    }
                    
                    // ✅ 1. قيد الحجز الأساسي - يُنشأ دائماً لكل حجز
                    // توزيع الحجز: قيدان بدلاً من قيد واحد
                    // 1) ذمم مدينة -> أموال الملاك المعلقة (95%)
                    var ownersPending = _accounts.FirstOrDefault(a => a.AccountNumber == "2105") ?? _accounts.FirstOrDefault(a => a.NameAr == "أموال الملاك المعلقة");
                    var commissionPending = _accounts.FirstOrDefault(a => a.AccountNumber == "2107") ?? _accounts.FirstOrDefault(a => a.NameAr == "عمولات المنصة المستحقة");

                    transactions.Add(new FinancialTransaction
                    {
                        Id = Guid.NewGuid(),
                        TransactionNumber = GenerateTransactionNumber(),
                        TransactionDate = booking.CreatedAt,
                        EntryType = JournalEntryType.Sales,
                        TransactionType = TransactionType.NewBooking,
                        DebitAccountId = guaranteedDebitAccount.Id,
                        CreditAccountId = ownersPending?.Id ?? guaranteedCreditAccount.Id,
                        Amount = ownerAmount,
                        Currency = currency,
                        ExchangeRate = 1,
                        BaseAmount = ownerAmount,
                        Description = $"توزيع حجز جديد (حصة المالك) {booking.Id.ToString().Substring(0, 8)}",
                        Narration = $"حجز من {booking.CheckIn:yyyy-MM-dd} إلى {booking.CheckOut:yyyy-MM-dd}",
                        ReferenceNumber = booking.Id.ToString(),
                        DocumentType = "BookingDistribution",
                        BookingId = booking.Id,
                        FirstPartyUserId = booking.UserId,
                        SecondPartyUserId = property.OwnerId,
                        PropertyId = property.Id,
                        UnitId = unit.Id,
                        Status = TransactionStatus.Posted,
                        IsPosted = true,
                        PostingDate = booking.CreatedAt,
                        FiscalYear = booking.CreatedAt.Year,
                        FiscalPeriod = booking.CreatedAt.Month,
                        Commission = commissionAmount,
                        CommissionPercentage = commissionRate * 100,
                        NetAmount = ownerAmount,
                        CreatedBy = adminUserId,
                        CreatedAt = booking.CreatedAt,
                        IsAutomatic = true,
                        AutomaticSource = "BookingSystem"
                    });

                    // 2) ذمم مدينة -> عمولات المنصة المستحقة (5%)
                    transactions.Add(new FinancialTransaction
                    {
                        Id = Guid.NewGuid(),
                        TransactionNumber = GenerateTransactionNumber(),
                        TransactionDate = booking.CreatedAt,
                        EntryType = JournalEntryType.Sales,
                        TransactionType = TransactionType.PlatformCommission,
                        DebitAccountId = guaranteedDebitAccount.Id,
                        CreditAccountId = commissionPending?.Id ?? commissionAccount.Id,
                        Amount = commissionAmount,
                        Currency = currency,
                        ExchangeRate = 1,
                        BaseAmount = commissionAmount,
                        Description = $"توزيع حجز جديد (عمولة المنصة) {booking.Id.ToString().Substring(0, 8)}",
                        Narration = $"عمولة {commissionRate * 100}% مستحقة على الحجز",
                        ReferenceNumber = booking.Id.ToString(),
                        DocumentType = "BookingDistribution",
                        BookingId = booking.Id,
                        PropertyId = property.Id,
                        Status = TransactionStatus.Posted,
                        IsPosted = true,
                        PostingDate = booking.CreatedAt,
                        FiscalYear = booking.CreatedAt.Year,
                        FiscalPeriod = booking.CreatedAt.Month,
                        CreatedBy = adminUserId,
                        CreatedAt = booking.CreatedAt,
                        IsAutomatic = true,
                        AutomaticSource = "CommissionSystem"
                    });
                
                // 2. قيد العمولة
                if (commissionAmount > 0)
                {
                    transactions.Add(new FinancialTransaction
                    {
                        Id = Guid.NewGuid(),
                        TransactionNumber = GenerateTransactionNumber(),
                        TransactionDate = booking.CreatedAt,
                        EntryType = JournalEntryType.GeneralJournal,
                        TransactionType = TransactionType.PlatformCommission,
                        DebitAccountId = revenueAccount?.Id ?? guaranteedCreditAccount.Id,
                        CreditAccountId = commissionAccount?.Id ?? platformAccount?.Id ?? guaranteedCreditAccount.Id,
                        Amount = commissionAmount,
                        Currency = currency,
                        ExchangeRate = 1,
                        BaseAmount = commissionAmount,
                        Description = $"عمولة المنصة للحجز {booking.Id.ToString().Substring(0, 8)}",
                        Narration = $"عمولة {commissionRate * 100}% على الحجز",
                        ReferenceNumber = booking.Id.ToString(),
                        DocumentType = "Commission",
                        BookingId = booking.Id,
                        PropertyId = property.Id,
                        Status = TransactionStatus.Posted,
                        IsPosted = true,
                        PostingDate = booking.CreatedAt,
                        FiscalYear = booking.CreatedAt.Year,
                        FiscalPeriod = booking.CreatedAt.Month,
                        CreatedBy = adminUserId,
                        CreatedAt = booking.CreatedAt,
                        IsAutomatic = true,
                        AutomaticSource = "CommissionSystem"
                    });
                }
                
                // 3. معالجة الدفعات المرتبطة بالحجز
                var bookingPayments = _payments.Where(p => p.BookingId == booking.Id).ToList();
                foreach (var payment in bookingPayments)
                {
                    if (payment.Status != PaymentStatus.Successful) continue;
                    
                    var paymentAccount = payment.PaymentMethod == PaymentMethodEnum.Cash 
                        ? cashAccount 
                        : bankAccount;
                    
                    transactions.Add(new FinancialTransaction
                    {
                        Id = Guid.NewGuid(),
                        TransactionNumber = GenerateTransactionNumber(),
                        TransactionDate = payment.PaymentDate,
                        EntryType = JournalEntryType.CashReceipts,
                        TransactionType = payment.Status == PaymentStatus.Pending ? TransactionType.AdvancePayment : TransactionType.FinalPayment,
                        DebitAccountId = paymentAccount.Id,
                        CreditAccountId = guaranteedDebitAccount.Id,
                        Amount = payment.Amount.Amount,
                        Currency = payment.Amount.Currency,
                        ExchangeRate = 1,
                        BaseAmount = payment.Amount.Amount,
                        Description = $"دفعة من العميل للحجز {booking.Id.ToString().Substring(0, 8)}",
                        Narration = $"استلام دفعة بواسطة {payment.PaymentMethod}",
                        ReferenceNumber = payment.TransactionId,
                        DocumentType = "Payment",
                        BookingId = booking.Id,
                        PaymentId = payment.Id,
                        FirstPartyUserId = booking.UserId,
                        PropertyId = property.Id,
                        UnitId = unit.Id,
                        Status = TransactionStatus.Posted,
                        IsPosted = true,
                        PostingDate = payment.PaymentDate,
                        FiscalYear = payment.PaymentDate.Year,
                        FiscalPeriod = payment.PaymentDate.Month,
                        CreatedBy = adminUserId,
                        CreatedAt = payment.PaymentDate,
                        IsAutomatic = true,
                        AutomaticSource = "PaymentSystem"
                    });
                }
                
                // 4. قيد إكمال الحجز (للحجوزات المكتملة)
                if (booking.Status == BookingStatus.Completed)
                {
                    var completionDate = booking.UpdatedAt != default(DateTime) ? booking.UpdatedAt : booking.CheckOut.AddDays(1);
                    transactions.Add(new FinancialTransaction
                    {
                        Id = Guid.NewGuid(),
                        TransactionNumber = GenerateTransactionNumber(),
                        TransactionDate = completionDate,
                        EntryType = JournalEntryType.GeneralJournal,
                        TransactionType = TransactionType.FinalPayment,
                        DebitAccountId = (_accounts.FirstOrDefault(a => a.AccountNumber == "2105") ?? guaranteedOwnerAccount).Id,
                        CreditAccountId = guaranteedOwnerAccount.Id,
                        Amount = ownerAmount,
                        Currency = currency,
                        ExchangeRate = 1,
                        BaseAmount = ownerAmount,
                        Description = $"إكمال الحجز رقم {booking.Id.ToString().Substring(0, 8)}",
                        Narration = "تحويل المبلغ النهائي للمالك بعد خصم العمولة",
                        ReferenceNumber = booking.Id.ToString(),
                        DocumentType = "BookingCompletion",
                        BookingId = booking.Id,
                        FirstPartyUserId = booking.UserId,
                        SecondPartyUserId = property.OwnerId,
                        PropertyId = property.Id,
                        UnitId = unit.Id,
                        Status = TransactionStatus.Posted,
                        IsPosted = true,
                        PostingDate = completionDate,
                        FiscalYear = completionDate.Year,
                        FiscalPeriod = completionDate.Month,
                        Commission = commissionAmount,
                        CommissionPercentage = commissionRate * 100,
                        NetAmount = ownerAmount,
                        CreatedBy = adminUserId,
                        CreatedAt = completionDate,
                        IsAutomatic = true,
                        AutomaticSource = "BookingCompletionSystem"
                    });
                }
                
                // 5. قيد الإلغاء (للحجوزات الملغاة)
                if (booking.Status == BookingStatus.Cancelled)
                {
                    var cancellationDate = booking.UpdatedAt != default(DateTime) ? booking.UpdatedAt : booking.CreatedAt.AddDays(1);
                    transactions.Add(new FinancialTransaction
                    {
                        Id = Guid.NewGuid(),
                        TransactionNumber = GenerateTransactionNumber(),
                        TransactionDate = cancellationDate,
                        EntryType = JournalEntryType.Reversal,
                        TransactionType = TransactionType.BookingCancellation,
                        DebitAccountId = guaranteedCreditAccount.Id,
                        CreditAccountId = guaranteedDebitAccount.Id,
                        Amount = totalAmount,
                        Currency = currency,
                        ExchangeRate = 1,
                        BaseAmount = totalAmount,
                        Description = $"إلغاء الحجز رقم {booking.Id.ToString().Substring(0, 8)}",
                        Narration = $"سبب الإلغاء: {booking.CancellationReason ?? "غير محدد"}",
                        ReferenceNumber = booking.Id.ToString(),
                        DocumentType = "Cancellation",
                        BookingId = booking.Id,
                        FirstPartyUserId = booking.UserId,
                        SecondPartyUserId = property.OwnerId,
                        PropertyId = property.Id,
                        UnitId = unit.Id,
                        Status = TransactionStatus.Posted,
                        IsPosted = true,
                        PostingDate = cancellationDate,
                        FiscalYear = cancellationDate.Year,
                        FiscalPeriod = cancellationDate.Month,
                        CancellationReason = booking.CancellationReason,
                        CancelledAt = cancellationDate,
                        CancelledBy = adminUserId,
                        CreatedBy = adminUserId,
                        CreatedAt = cancellationDate,
                        IsAutomatic = true,
                        AutomaticSource = "CancellationSystem"
                    });
                    
                    // قيد استرداد إذا كانت هناك دفعات مستردة
                    var refundedPayments = bookingPayments.Where(p => p.Status == PaymentStatus.Refunded).ToList();
                    foreach (var refund in refundedPayments)
                    {
                        transactions.Add(new FinancialTransaction
                        {
                            Id = Guid.NewGuid(),
                            TransactionNumber = GenerateTransactionNumber(),
                            TransactionDate = refund.UpdatedAt != default(DateTime) ? refund.UpdatedAt : cancellationDate,
                            EntryType = JournalEntryType.CashPayments,
                            TransactionType = TransactionType.Refund,
                            DebitAccountId = refundExpenseAccount?.Id ?? (_accounts.FirstOrDefault(a => a.AccountNumber == "5130")?.Id ?? guaranteedDebitAccount.Id),
                            CreditAccountId = cashAccount.Id,
                            Amount = refund.Amount.Amount,
                            Currency = refund.Amount.Currency,
                            ExchangeRate = 1,
                            BaseAmount = refund.Amount.Amount,
                            Description = $"استرداد مبلغ للعميل - الحجز {booking.Id.ToString().Substring(0, 8)}",
                            Narration = "استرداد بسبب إلغاء الحجز",
                            ReferenceNumber = refund.TransactionId,
                            DocumentType = "Refund",
                            BookingId = booking.Id,
                            PaymentId = refund.Id,
                            FirstPartyUserId = booking.UserId,
                            PropertyId = property.Id,
                            UnitId = unit.Id,
                            Status = TransactionStatus.Posted,
                            IsPosted = true,
                            PostingDate = refund.UpdatedAt != default(DateTime) ? refund.UpdatedAt : cancellationDate,
                            FiscalYear = (refund.UpdatedAt != default(DateTime) ? refund.UpdatedAt : cancellationDate).Year,
                            FiscalPeriod = (refund.UpdatedAt != default(DateTime) ? refund.UpdatedAt : cancellationDate).Month,
                            CreatedBy = adminUserId,
                            CreatedAt = refund.UpdatedAt != default(DateTime) ? refund.UpdatedAt : cancellationDate,
                            IsAutomatic = true,
                            AutomaticSource = "RefundSystem"
                        });
                    }
                }
                }
                catch (Exception)
                {
                    // تجاهل الأخطاء لهذا الحجز والاستمرار
                    // Ignore errors for this booking and continue
                    continue;
                }
            }
            
            return transactions;
        }
        
        /// <summary>
        /// توليد رقم قيد تسلسلي
        /// Generate sequential transaction number
        /// </summary>
        private string GenerateTransactionNumber()
        {
            return $"JV-{DateTime.UtcNow.Year}-{_transactionCounter++:D6}";
        }
        
        /// <summary>
        /// ✅ محسّن: الحصول على حساب للمستخدم أو حساب افتراضي
        /// Enhanced: Get user account or default account
        /// </summary>
        private ChartOfAccount GetOrCreateUserAccount(Guid userId, string userType, AccountType accountType)
        {
            // البحث عن حساب موجود للمستخدم
            var account = _accounts.FirstOrDefault(a => 
                a.UserId == userId && a.AccountType == accountType);
            
            if (account != null)
                return account;
            
            // البحث عن حساب افتراضي حسب النوع
            if (accountType == AccountType.Assets)
            {
                // حساب ذمم مدينة عام للعملاء
                return _accounts.FirstOrDefault(a => 
                    (a.AccountNumber == "1110" || a.NameAr.Contains("ذمم مدينة")) && 
                    (a.IsSystemAccount || a.Category == AccountCategory.Sub));
            }
            else if (accountType == AccountType.Liabilities)
            {
                // حساب ذمم دائنة عام للملاك
                return _accounts.FirstOrDefault(a => 
                    (a.AccountNumber == "2101" || a.NameAr.Contains("ذمم دائنة")) && 
                    (a.IsSystemAccount || a.Category == AccountCategory.Sub));
            }
            
            return null;
        }
        
        /// <summary>
        /// ✅ جديد: إنشاء حساب مؤقت في الذاكرة (لا يُحفظ في قاعدة البيانات)
        /// New: Create temporary account in memory (not saved to database)
        /// </summary>
        private ChartOfAccount CreateTemporaryAccount(Guid userId, string userType, AccountType accountType)
        {
            // إنشاء حساب مؤقت لضمان استمرار العمليات
            var tempAccount = new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = accountType == AccountType.Assets ? "1110-TEMP" : "2101-TEMP",
                NameAr = accountType == AccountType.Assets ? 
                    $"ذمم مدينة مؤقت - {userType}" : 
                    $"ذمم دائنة مؤقت - {userType}",
                NameEn = accountType == AccountType.Assets ? 
                    $"Temp AR - {userType}" : 
                    $"Temp AP - {userType}",
                AccountType = accountType,
                Category = AccountCategory.Sub,
                NormalBalance = accountType == AccountType.Assets ? 
                    AccountNature.Debit : AccountNature.Credit,
                Level = 3,
                IsActive = true,
                CanPost = true,
                UserId = userId,
                Currency = "YER"
            };
            
            // إضافة الحساب المؤقت إلى القائمة المحلية فقط
            _accounts.Add(tempAccount);
            
            return tempAccount;
        }
    }
}
