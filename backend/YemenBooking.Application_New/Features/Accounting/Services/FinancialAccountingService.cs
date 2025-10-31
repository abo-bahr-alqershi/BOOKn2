using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Persistence.Repositories;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Analytics.DTOs;
using YemenBooking.Application.Features.Reports.DTOs;
using PaymentStatus = YemenBooking.Core.Enums.PaymentStatus;

namespace YemenBooking.Application.Features.Accounting.Services;

/// <summary>
/// خدمة المحاسبة المالية - تدير جميع العمليات المحاسبية والقيود المالية
/// Financial Accounting Service - Manages all accounting operations and financial transactions
/// </summary>
public class FinancialAccountingService : IFinancialAccountingService
{
    private readonly IFinancialTransactionRepository _transactionRepository;
    private readonly IChartOfAccountRepository _accountRepository;
    private readonly IBookingRepository _bookingRepository;
    private readonly IPaymentRepository _paymentRepository;
    private readonly IUserRepository _userRepository;
    private readonly IPropertyRepository _propertyRepository;
    private readonly IUnitRepository _unitRepository;
    private readonly ILogger<FinancialAccountingService> _logger;

    // حسابات النظام الأساسية
    private const string SYSTEM_CASH_ACCOUNT = "النقدية";
    private const string SYSTEM_BANK_ACCOUNT = "البنك";
    private const string SYSTEM_REVENUE_ACCOUNT = "إيرادات الحجوزات";
    private const string SYSTEM_COMMISSION_ACCOUNT = "عمولات المنصة";
    private const string SYSTEM_TAX_ACCOUNT = "الضرائب المستحقة";
    private const string SYSTEM_RECEIVABLE_ACCOUNT = "ذمم مدينة - عملاء";
    private const string SYSTEM_PAYABLE_ACCOUNT = "ذمم دائنة - ملاك";
    private const string PLATFORM_ACCOUNT = "حساب المنصة";
    private const string OWNERS_FUNDS_PENDING_ACCOUNT = "أموال الملاك المعلقة";
    private const string PLATFORM_COMMISSION_PENDING_ACCOUNT = "عمولات المنصة المستحقة";
    private const string CANCELLATION_FEES_ACCOUNT = "رسوم الإلغاء";
    private const string SALES_RETURNS_ACCOUNT = "مردودات المبيعات";

    public FinancialAccountingService(
        IFinancialTransactionRepository transactionRepository,
        IChartOfAccountRepository accountRepository,
        IBookingRepository bookingRepository,
        IPaymentRepository paymentRepository,
        IUserRepository userRepository,
        IPropertyRepository propertyRepository,
        IUnitRepository unitRepository,
        ILogger<FinancialAccountingService> logger)
    {
        _transactionRepository = transactionRepository;
        _accountRepository = accountRepository;
        _bookingRepository = bookingRepository;
        _paymentRepository = paymentRepository;
        _userRepository = userRepository;
        _propertyRepository = propertyRepository;
        _unitRepository = unitRepository;
        _logger = logger;
    }

    /// <summary>
    /// تسجيل عملية حجز جديدة
    /// Record new booking transaction
    /// </summary>
    public async Task<FinancialTransaction> RecordBookingTransactionAsync(Guid bookingId, Guid userId)
    {
        try
        {
            var booking = await _bookingRepository.GetByIdAsync(bookingId);
            if (booking == null)
                throw new ArgumentException($"BookingDto {bookingId} not found");

            var user = await _userRepository.GetByIdAsync(booking.UserId);
            var unit = await _unitRepository.GetByIdAsync(booking.UnitId);
            var property = await _propertyRepository.GetByIdAsync(unit.PropertyId);

            // الحصول على أو إنشاء حسابات الأطراف
            var customerAccount = await GetOrCreateCustomerAccountAsync(booking.UserId, user.Name);
            var ownersPendingAccount = await _accountRepository.GetSystemAccountAsync(OWNERS_FUNDS_PENDING_ACCOUNT);
            var commissionPendingAccount = await _accountRepository.GetSystemAccountAsync(PLATFORM_COMMISSION_PENDING_ACCOUNT);

            // حساب العمولة حسب المواصفات (5%)
            var commissionRate = 0.05m;
            var totalAmount = booking.TotalPrice.Amount;
            var commissionAmount = Math.Round(totalAmount * commissionRate, 2);
            var ownerAmount = totalAmount - commissionAmount;

            // 1) من ح/ ذمم مدينة - عملاء (بنسبة 95%) إلى ح/ أموال الملاك المعلقة
            var ownerDistributionTx = new FinancialTransaction
            {
                TransactionNumber = await _transactionRepository.GenerateTransactionNumberAsync(),
                TransactionDate = DateTime.UtcNow,
                EntryType = JournalEntryType.Sales,
                TransactionType = TransactionType.NewBooking,
                DebitAccountId = customerAccount.Id,
                CreditAccountId = ownersPendingAccount.Id,
                Amount = ownerAmount,
                Currency = booking.TotalPrice.Currency,
                ExchangeRate = 1,
                BaseAmount = ownerAmount,
                Description = $"توزيع حجز جديد (حصة المالك) للحجز {booking.Id}",
                Narration = $"حجز الوحدة {unit.Name} في {property.Name} للفترة {booking.CheckIn:yyyy-MM-dd} إلى {booking.CheckOut:yyyy-MM-dd}",
                ReferenceNumber = booking.Id.ToString(),
                DocumentType = "BookingDistribution",
                BookingId = bookingId,
                FirstPartyUserId = booking.UserId,
                SecondPartyUserId = property.OwnerId,
                PropertyId = property.Id,
                UnitId = unit.Id,
                Status = TransactionStatus.Posted,
                IsPosted = true,
                PostingDate = DateTime.UtcNow,
                FiscalYear = DateTime.UtcNow.Year,
                FiscalPeriod = DateTime.UtcNow.Month,
                Commission = commissionAmount,
                CommissionPercentage = commissionRate * 100,
                NetAmount = ownerAmount,
                CreatedBy = userId,
                CreatedAt = DateTime.UtcNow,
                IsAutomatic = true,
                AutomaticSource = "BookingSystem"
            };
            await _transactionRepository.AddAsync(ownerDistributionTx);

            // 2) من ح/ ذمم مدينة - عملاء (بنسبة 5%) إلى ح/ عمولات المنصة المستحقة
            var commissionPendingTx = new FinancialTransaction
            {
                TransactionNumber = await _transactionRepository.GenerateTransactionNumberAsync(),
                TransactionDate = DateTime.UtcNow,
                EntryType = JournalEntryType.Sales,
                TransactionType = TransactionType.PlatformCommission,
                DebitAccountId = customerAccount.Id,
                CreditAccountId = commissionPendingAccount.Id,
                Amount = commissionAmount,
                Currency = booking.TotalPrice.Currency,
                ExchangeRate = 1,
                BaseAmount = commissionAmount,
                Description = $"توزيع حجز جديد (عمولة المنصة) للحجز {booking.Id}",
                Narration = $"عمولة {commissionRate * 100}% مستحقة على الحجز",
                ReferenceNumber = booking.Id.ToString(),
                DocumentType = "BookingDistribution",
                BookingId = bookingId,
                FirstPartyUserId = booking.UserId,
                SecondPartyUserId = property.OwnerId,
                PropertyId = property.Id,
                UnitId = unit.Id,
                Status = TransactionStatus.Posted,
                IsPosted = true,
                PostingDate = DateTime.UtcNow,
                FiscalYear = DateTime.UtcNow.Year,
                FiscalPeriod = DateTime.UtcNow.Month,
                Commission = commissionAmount,
                CommissionPercentage = commissionRate * 100,
                NetAmount = ownerAmount,
                CreatedBy = userId,
                CreatedAt = DateTime.UtcNow,
                IsAutomatic = true,
                AutomaticSource = "BookingSystem"
            };
            await _transactionRepository.AddAsync(commissionPendingTx);

            _logger.LogInformation($"BookingDto distribution recorded for booking {bookingId}");
            return ownerDistributionTx;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error recording booking transaction for booking {bookingId}");
            throw;
        }
    }

    /// <summary>
    /// تسجيل عملية دفع
    /// Record payment transaction
    /// </summary>
    public async Task<FinancialTransaction> RecordPaymentTransactionAsync(Guid paymentId, Guid userId)
    {
        try
        {
            var payment = await _paymentRepository.GetByIdAsync(paymentId);
            if (payment == null)
                throw new ArgumentException($"Payment {paymentId} not found");

            var booking = await _bookingRepository.GetByIdAsync(payment.BookingId);
            var user = await _userRepository.GetByIdAsync(booking.UserId);
            var unit = await _unitRepository.GetByIdAsync(booking.UnitId);
            var property = await _propertyRepository.GetByIdAsync(unit.PropertyId);

            // تحديد حسابات القيد بناءً على طريقة الدفع
            var paymentMethodAccount = payment.PaymentMethod switch
            {
                PaymentMethodEnum.CreditCard => await _accountRepository.GetSystemAccountAsync(SYSTEM_BANK_ACCOUNT),
                PaymentMethodEnum.CashWallet => await _accountRepository.GetSystemAccountAsync("المحافظ الإلكترونية"),
                PaymentMethodEnum.JwaliWallet => await _accountRepository.GetSystemAccountAsync("المحافظ الإلكترونية"),
                PaymentMethodEnum.OneCashWallet => await _accountRepository.GetSystemAccountAsync("المحافظ الإلكترونية"),
                PaymentMethodEnum.FloskWallet => await _accountRepository.GetSystemAccountAsync("المحافظ الإلكترونية"),
                PaymentMethodEnum.JaibWallet => await _accountRepository.GetSystemAccountAsync("المحافظ الإلكترونية"),
                PaymentMethodEnum.EWallet => await _accountRepository.GetSystemAccountAsync("المحافظ الإلكترونية"),
                PaymentMethodEnum.Paypal => await _accountRepository.GetSystemAccountAsync(SYSTEM_BANK_ACCOUNT),
                PaymentMethodEnum.Cash => await _accountRepository.GetSystemAccountAsync(SYSTEM_CASH_ACCOUNT),
                _ => await _accountRepository.GetSystemAccountAsync(SYSTEM_CASH_ACCOUNT)
            };

            var customerAccount = await GetOrCreateUserAccountAsync(booking.UserId, user.Name, AccountType.Assets);

            var transactionType = payment.Status == PaymentStatus.Pending 
                ? TransactionType.AdvancePayment 
                : TransactionType.FinalPayment;

            var transaction = new FinancialTransaction
            {
                TransactionNumber = await _transactionRepository.GenerateTransactionNumberAsync(),
                TransactionDate = payment.PaymentDate,
                EntryType = JournalEntryType.CashReceipts,
                TransactionType = transactionType,
                DebitAccountId = paymentMethodAccount.Id,
                CreditAccountId = customerAccount.Id,
                Amount = payment.Amount.Amount,
                Currency = payment.Amount.Currency,
                ExchangeRate = 1,
                BaseAmount = payment.Amount.Amount,
                Description = $"دفعة من العميل {user.Name} للحجز {booking.Id}",
                Narration = $"استلام دفعة بواسطة {payment.PaymentMethod} - معرف المعاملة: {payment.TransactionId}",
                ReferenceNumber = payment.TransactionId,
                DocumentType = "Payment",
                BookingId = booking.Id,
                PaymentId = paymentId,
                FirstPartyUserId = booking.UserId,
                PropertyId = property.Id,
                UnitId = unit.Id,
                Status = TransactionStatus.Approved,
                FiscalYear = payment.PaymentDate.Year,
                FiscalPeriod = payment.PaymentDate.Month,
                CreatedBy = userId,
                CreatedAt = DateTime.UtcNow,
                IsAutomatic = true,
                AutomaticSource = "PaymentSystem"
            };

            await _transactionRepository.AddAsync(transaction);

            // ترحيل القيد مباشرة إذا كانت الدفعة مؤكدة
            if (payment.Status == Core.Enums.PaymentStatus.Successful)
            {
                await _transactionRepository.PostTransactionAsync(transaction.Id);
            }

            _logger.LogInformation($"Payment transaction recorded for payment {paymentId}");
            return transaction;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error recording payment transaction for payment {paymentId}");
            throw;
        }
    }

    /// <summary>
    /// تسجيل إلغاء الحجز (متوافق مع الاسم القديم)
    /// Record booking cancellation (compatible with old name)
    /// </summary>
    public async Task<FinancialTransaction> RecordBookingCancellationAsync(Guid bookingId, string reason, Guid userId)
    {
        try
        {
            var booking = await _bookingRepository.GetByIdAsync(bookingId);
            if (booking == null)
                throw new ArgumentException($"BookingDto {bookingId} not found");

            // الحصول على القيود الأصلية للحجز
            var originalTransactions = await _transactionRepository.GetByBookingIdAsync(bookingId);
            
            var user = await _userRepository.GetByIdAsync(booking.UserId);
            var unit = await _unitRepository.GetByIdAsync(booking.UnitId);
            var property = await _propertyRepository.GetByIdAsync(unit.PropertyId);

            var customerAccount = await GetOrCreateUserAccountAsync(booking.UserId, user.Name, AccountType.Assets);
            var revenueAccount = await _accountRepository.GetSystemAccountAsync(SYSTEM_REVENUE_ACCOUNT);

            // عكس قيد الحجز الأصلي
            var cancellationTransaction = new FinancialTransaction
            {
                TransactionNumber = await _transactionRepository.GenerateTransactionNumberAsync(),
                TransactionDate = DateTime.UtcNow,
                EntryType = JournalEntryType.Reversal,
                TransactionType = TransactionType.BookingCancellation,
                DebitAccountId = revenueAccount.Id, // عكس القيد الأصلي
                CreditAccountId = customerAccount.Id,
                Amount = booking.TotalPrice.Amount,
                Currency = booking.TotalPrice.Currency,
                ExchangeRate = 1,
                BaseAmount = booking.TotalPrice.Amount,
                Description = $"إلغاء الحجز رقم {booking.Id}",
                Narration = $"سبب الإلغاء: {reason}",
                ReferenceNumber = booking.Id.ToString(),
                DocumentType = "Cancellation",
                BookingId = bookingId,
                FirstPartyUserId = booking.UserId,
                SecondPartyUserId = property.OwnerId,
                PropertyId = property.Id,
                UnitId = unit.Id,
                Status = TransactionStatus.Approved,
                FiscalYear = DateTime.UtcNow.Year,
                FiscalPeriod = DateTime.UtcNow.Month,
                CancellationReason = reason,
                CancelledAt = DateTime.UtcNow,
                CancelledBy = userId,
                CreatedBy = userId,
                CreatedAt = DateTime.UtcNow,
                IsAutomatic = true,
                AutomaticSource = "CancellationSystem"
            };

            await _transactionRepository.AddAsync(cancellationTransaction);

            // عكس جميع القيود المرتبطة بالحجز
            foreach (var originalTx in originalTransactions.Where(t => !t.IsReversed))
            {
                await _transactionRepository.ReverseTransactionAsync(originalTx.Id, reason, userId);
            }

            _logger.LogInformation($"BookingDto cancellation recorded for booking {bookingId}");
            return cancellationTransaction;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error recording booking cancellation for booking {bookingId}");
            throw;
        }
    }

    /// <summary>
    /// تسجيل استرداد مبلغ
    /// Record refund transaction
    /// </summary>
    public async Task<FinancialTransaction> RecordRefundTransactionAsync(
        Guid bookingId, 
        decimal amount, 
        string reason, 
        Guid userId)
    {
        try
        {
            var booking = await _bookingRepository.GetByIdAsync(bookingId);
            if (booking == null)
                throw new ArgumentException($"BookingDto {bookingId} not found");

            var user = await _userRepository.GetByIdAsync(booking.UserId);
            var unit = await _unitRepository.GetByIdAsync(booking.UnitId);
            var property = await _propertyRepository.GetByIdAsync(unit.PropertyId);

            var salesReturnsAccount = await _accountRepository.GetSystemAccountAsync(SALES_RETURNS_ACCOUNT);
            var cashOrBankAccount = await _accountRepository.GetSystemAccountAsync(SYSTEM_BANK_ACCOUNT)
                ?? await _accountRepository.GetSystemAccountAsync(SYSTEM_CASH_ACCOUNT);

            var refundTransaction = new FinancialTransaction
            {
                TransactionNumber = await _transactionRepository.GenerateTransactionNumberAsync(),
                TransactionDate = DateTime.UtcNow,
                EntryType = JournalEntryType.CashPayments,
                TransactionType = TransactionType.Refund,
                DebitAccountId = salesReturnsAccount.Id,
                CreditAccountId = cashOrBankAccount.Id,
                Amount = amount,
                Currency = booking.TotalPrice.Currency,
                ExchangeRate = 1,
                BaseAmount = amount,
                Description = $"استرداد مبلغ للعميل {user.Name}",
                Narration = $"سبب الاسترداد: {reason}",
                ReferenceNumber = booking.Id.ToString(),
                DocumentType = "Refund",
                BookingId = bookingId,
                FirstPartyUserId = booking.UserId,
                PropertyId = property.Id,
                UnitId = unit.Id,
                Status = TransactionStatus.Approved,
                FiscalYear = DateTime.UtcNow.Year,
                FiscalPeriod = DateTime.UtcNow.Month,
                CreatedBy = userId,
                CreatedAt = DateTime.UtcNow,
                IsAutomatic = false
            };

            await _transactionRepository.AddAsync(refundTransaction);

            _logger.LogInformation($"Refund transaction recorded for booking {bookingId}, amount: {amount}");
            return refundTransaction;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error recording refund for booking {bookingId}");
            throw;
        }
    }

    /// <summary>
    /// تسجيل دفعة للمالك
    /// Record owner payout
    /// </summary>
    public async Task<FinancialTransaction> RecordOwnerPayoutAsync(
        Guid propertyId,
        Guid ownerId,
        decimal amount,
        string description,
        Guid userId)
    {
        try
        {
            var property = await _propertyRepository.GetByIdAsync(propertyId);
            if (property == null)
                throw new ArgumentException($"Property {propertyId} not found");

            var owner = await _userRepository.GetByIdAsync(ownerId);

            var ownerAccount = await GetOrCreateUserAccountAsync(ownerId, owner.Name, AccountType.Liabilities);
            var bankAccount = await _accountRepository.GetSystemAccountAsync(SYSTEM_BANK_ACCOUNT);

            var payoutTransaction = new FinancialTransaction
            {
                TransactionNumber = await _transactionRepository.GenerateTransactionNumberAsync(),
                TransactionDate = DateTime.UtcNow,
                EntryType = JournalEntryType.CashPayments,
                TransactionType = TransactionType.OwnerPayout,
                DebitAccountId = ownerAccount.Id,
                CreditAccountId = bankAccount.Id,
                Amount = amount,
                Currency = "YER",
                ExchangeRate = 1,
                BaseAmount = amount,
                Description = $"دفعة للمالك {owner.Name}",
                Narration = description,
                ReferenceNumber = Guid.NewGuid().ToString(),
                DocumentType = "OwnerPayout",
                SecondPartyUserId = ownerId,
                PropertyId = propertyId,
                Status = TransactionStatus.Approved,
                FiscalYear = DateTime.UtcNow.Year,
                FiscalPeriod = DateTime.UtcNow.Month,
                CreatedBy = userId,
                CreatedAt = DateTime.UtcNow,
                IsAutomatic = false
            };

            await _transactionRepository.AddAsync(payoutTransaction);

            _logger.LogInformation($"Owner payout recorded for property {propertyId}, amount: {amount}");
            return payoutTransaction;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error recording owner payout for property {propertyId}");
            throw;
        }
    }

    /// <summary>
    /// تسجيل إكمال الحجز
    /// Record booking completion
    /// </summary>
    public async Task<FinancialTransaction> RecordBookingCompletionAsync(
        Guid bookingId,
        decimal finalAmount,
        Guid userId)
    {
        try
        {
            var booking = await _bookingRepository.GetByIdAsync(bookingId);
            if (booking == null)
                throw new ArgumentException($"BookingDto {bookingId} not found");

            var user = await _userRepository.GetByIdAsync(booking.UserId);
            var unit = await _unitRepository.GetByIdAsync(booking.UnitId);
            var property = await _propertyRepository.GetByIdAsync(unit.PropertyId);

            var customerAccount = await GetOrCreateUserAccountAsync(booking.UserId, user.Name, AccountType.Assets);
            var ownerAccount = await GetOrCreateUserAccountAsync(property.OwnerId, property.Owner?.Name ?? "Owner", AccountType.Liabilities);
            var platformAccount = await _accountRepository.GetSystemAccountAsync(PLATFORM_ACCOUNT);

            // حساب العمولة النهائية
            var commissionRate = 0.10m;
            var commissionAmount = finalAmount * commissionRate;
            var ownerAmount = finalAmount - commissionAmount;

            // تحويل المبلغ من حساب العميل إلى حساب المالك
            var transferTransaction = new FinancialTransaction
            {
                TransactionNumber = await _transactionRepository.GenerateTransactionNumberAsync(),
                TransactionDate = DateTime.UtcNow,
                EntryType = JournalEntryType.GeneralJournal,
                TransactionType = TransactionType.FinalPayment,
                DebitAccountId = ownerAccount.Id,
                CreditAccountId = customerAccount.Id,
                Amount = ownerAmount,
                Currency = booking.TotalPrice.Currency,
                ExchangeRate = 1,
                BaseAmount = ownerAmount,
                Description = $"إكمال الحجز رقم {booking.Id}",
                Narration = $"تحويل المبلغ النهائي للمالك بعد خصم العمولة",
                ReferenceNumber = booking.Id.ToString(),
                DocumentType = "BookingCompletion",
                BookingId = bookingId,
                FirstPartyUserId = booking.UserId,
                SecondPartyUserId = property.OwnerId,
                PropertyId = property.Id,
                UnitId = unit.Id,
                Status = TransactionStatus.Posted,
                IsPosted = true,
                PostingDate = DateTime.UtcNow,
                FiscalYear = DateTime.UtcNow.Year,
                FiscalPeriod = DateTime.UtcNow.Month,
                Commission = commissionAmount,
                CommissionPercentage = commissionRate * 100,
                NetAmount = ownerAmount,
                CreatedBy = userId,
                CreatedAt = DateTime.UtcNow,
                IsAutomatic = true,
                AutomaticSource = "BookingCompletionSystem"
            };

            await _transactionRepository.AddAsync(transferTransaction);

            // تحديث أرصدة الحسابات
            await _accountRepository.UpdateAccountBalanceAsync(ownerAccount.Id, ownerAmount, true);
            await _accountRepository.UpdateAccountBalanceAsync(customerAccount.Id, finalAmount, false);
            await _accountRepository.UpdateAccountBalanceAsync(platformAccount.Id, commissionAmount, false);

            _logger.LogInformation($"BookingDto completion recorded for booking {bookingId}");
            return transferTransaction;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error recording booking completion for booking {bookingId}");
            throw;
        }
    }

    // Helper Methods

    /// <summary>
    /// الحصول على أو إنشاء حساب العميل (ذمم مدينة فقط)
    /// </summary>
    private async Task<ChartOfAccount> GetOrCreateCustomerAccountAsync(Guid customerId, string customerName)
    {

        var accountName = $"ذمم مدينة - عميل #{customerId}";
        var account = await _accountRepository.GetUserAccountAsync(customerId, AccountType.Assets);
        if (account == null)
        {
            var accountNumber = await _accountRepository.GenerateAccountNumberAsync(AccountType.Assets, true);
            account = new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = accountNumber,
                NameAr = accountName,
                NameEn = $"Accounts Receivable - Customer #{accountName}",
                AccountType = AccountType.Assets,
                Category = AccountCategory.Sub,
                NormalBalance = AccountNature.Debit,
                IsActive = true,
                CanPost = true,
                CreatedAt = DateTime.UtcNow,
                Description = $"حساب ذمم مدينة للعميل {customerName}"
            };
            await _accountRepository.CreateAsync(account);
        }
        return account;
    }

    /// <summary>
    /// الحصول على أو إنشاء حساب ذمم دائنة للمالك
    /// </summary>
    private async Task<ChartOfAccount> GetOrCreateOwnerPayableAccountAsync(Guid ownerId, string ownerName)
    {
        var accountName = $"ذمم دائنة - مالك #{ownerId}";
        var account = await _accountRepository.GetUserAccountAsync(ownerId, AccountType.Liabilities);
        if (account == null)
        {
            var accountNumber = await _accountRepository.GenerateAccountNumberAsync(AccountType.Liabilities, true);

            account = new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = accountNumber,
                NameAr = accountName,
                NameEn = $"Accounts Payable - Owner #{ownerName}",
                AccountType = AccountType.Liabilities,
                Category = AccountCategory.Sub,
                NormalBalance = AccountNature.Credit,
                IsActive = true,
                CanPost = true,
                CreatedAt = DateTime.UtcNow,
                Description = $"حساب ذمم دائنة للمالك {ownerName}"
            };
            await _accountRepository.CreateAsync(account);
        }
        return account;
    }

    /// <summary>
    /// الحصول على أو إنشاء حساب عمولات مستحقة للمالك
    /// </summary>
    private async Task<ChartOfAccount> GetOrCreateOwnerCommissionAccountAsync(Guid ownerId, string ownerName)
    {
        var accountName = $"عمولات مستحقة - مالك #{ownerId}";
        // البحث عن حساب العمولات المستحقة للمالك
        var accounts = await _accountRepository.GetAccountListAsync();
        var account = accounts.FirstOrDefault(a => 
            a.NameAr == accountName || 
            (a.Description != null && a.Description.Contains($"عمولات مستحقة للمالك {ownerId}")));
        
        if (account == null)
        {
            account = new ChartOfAccount
            {
                Id = Guid.NewGuid(),
                AccountNumber = $"2202-{ownerId.ToString().Substring(0, 8)}",
                NameAr = accountName,
                NameEn = $"Commission Payable - Owner #{ownerId}",
                AccountType = AccountType.Liabilities,
                Category = AccountCategory.Sub,
                NormalBalance = AccountNature.Credit,
                IsActive = true,
                CanPost = true,
                CreatedAt = DateTime.UtcNow,
                Description = $"حساب عمولات مستحقة للمالك {ownerName}",
                UserId = ownerId
            };
            await _accountRepository.CreateAsync(account);
        }
        return account;
    }

    /// <summary>
    /// DEPRECATED - للتوافق القديم فقط
    /// </summary>
    [Obsolete("استخدم GetOrCreateCustomerAccountAsync أو GetOrCreateOwnerPayableAccountAsync")]
    private async Task<ChartOfAccount> GetOrCreateUserAccountAsync(Guid userId, string userName, AccountType accountType)
    {
        if (accountType == AccountType.Assets)
        {
            return await GetOrCreateCustomerAccountAsync(userId, userName);
        }
        else if (accountType == AccountType.Liabilities)
        {
            return await GetOrCreateOwnerPayableAccountAsync(userId, userName);
        }
        throw new InvalidOperationException($"نوع الحساب غير مدعوم: {accountType}");
    }

    private async Task<ChartOfAccount> GetOrCreatePropertyAccountAsync(Guid propertyId, string propertyName, AccountType accountType)
    {
        var account = await _accountRepository.GetPropertyAccountAsync(propertyId, accountType);
        if (account == null)
        {
            account = await _accountRepository.CreatePropertyAccountAsync(propertyId, propertyName, accountType);
        }
        return account;
    }



    /// <summary>
    /// الحصول على تقرير مالي لفترة معينة
    /// Get financial report for a period
    /// </summary>
    public async Task<FinancialReportDto> GetFinancialReportAsync(DateTime startDate, DateTime endDate)
    {
        // لا حاجة لجلب جميع القيود إلى الذاكرة، نستخدم العدّ فقط للأداء
        var transactionCount = await _transactionRepository.CountByPeriodAsync(startDate, endDate, null, null);
        var summary = await _transactionRepository.GetTransactionSummaryByTypeAsync(startDate, endDate);

        var report = new FinancialReportDto
        {
            StartDate = startDate,
            EndDate = endDate,
            TotalRevenue = summary.Where(s => IsRevenueType(s.Key)).Sum(s => s.Value),
            TotalExpenses = summary.Where(s => IsExpenseType(s.Key)).Sum(s => s.Value),
            TotalCommissions = summary.GetValueOrDefault(TransactionType.PlatformCommission, 0),
            TotalRefunds = summary.GetValueOrDefault(TransactionType.Refund, 0),
            TransactionCount = transactionCount,
            TransactionsByType = summary,
            NetProfit = 0 // سيتم حسابه
        };

        report.NetProfit = report.TotalRevenue - report.TotalExpenses - report.TotalRefunds;

        return report;
    }

    private bool IsRevenueType(TransactionType type)
    {
        return type == TransactionType.NewBooking || 
               type == TransactionType.FinalPayment || 
               type == TransactionType.PlatformCommission ||
               type == TransactionType.ServiceFee ||
               type == TransactionType.LateFee ||
               type == TransactionType.OtherIncome;
    }

    private bool IsExpenseType(TransactionType type)
    {
        return type == TransactionType.OwnerPayout || 
               type == TransactionType.OperationalExpense ||
               type == TransactionType.AgentCommission;
    }


    /// <summary>
    /// إنشاء الحساب المالي للعميل
    /// Create customer financial account
    /// </summary>
    public async Task<bool> CreateCustomerFinancialAccountAsync(Guid customerId, string customerName, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء إنشاء الحساب المالي للعميل {CustomerId} - {CustomerName}", customerId, customerName);

            // إنشاء حساب واحد فقط: ذمم مدينة - عميل #{CustomerId}
            var receivableAccount = await GetOrCreateCustomerAccountAsync(customerId, customerName);
            if (receivableAccount == null)
            {
                _logger.LogError("فشل إنشاء حساب الذمم المدينة للعميل {CustomerId}", customerId);
                return false;
            }

            _logger.LogInformation("تم إنشاء الحساب المالي بنجاح للعميل {CustomerId}", customerId);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في إنشاء الحساب المالي للعميل {CustomerId}", customerId);
            throw;
        }
    }

    /// <summary>
    /// إنشاء الحسابات المالية للمالك
    /// Create owner financial accounts
    /// </summary>
    public async Task<bool> CreateOwnerFinancialAccountsAsync(Guid ownerId, string ownerName, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء إنشاء الحسابات المالية للمالك {OwnerId} - {OwnerName}", ownerId, ownerName);

            // إنشاء حسابين للمالك:
            // 1. ذمم دائنة - مالك #{OwnerId}
            var payableAccount = await GetOrCreateOwnerPayableAccountAsync(ownerId, ownerName);
            if (payableAccount == null)
            {
                _logger.LogError("فشل إنشاء حساب الذمم الدائنة للمالك {OwnerId}", ownerId);
                return false;
            }

            // 2. عمولات مستحقة - مالك #{OwnerId}
            var commissionAccount = await GetOrCreateOwnerCommissionAccountAsync(ownerId, ownerName);
            if (commissionAccount == null)
            {
                _logger.LogError("فشل إنشاء حساب العمولات المستحقة للمالك {OwnerId}", ownerId);
                return false;
            }

            _logger.LogInformation("تم إنشاء الحسابات المالية بنجاح للمالك {OwnerId}", ownerId);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في إنشاء الحسابات المالية للمالك {OwnerId}", ownerId);
            throw;
        }
    }

    /// <summary>
    /// DEPRECATED - للتوافق فقط، استخدم CreateCustomerFinancialAccountAsync أو CreateOwnerFinancialAccountsAsync
    /// </summary>
    [Obsolete("استخدم CreateCustomerFinancialAccountAsync للعملاء أو CreateOwnerFinancialAccountsAsync للملاك")]
    public async Task<bool> CreateUserFinancialAccountsAsync(Guid userId, string userName, CancellationToken cancellationToken)
    {
        _logger.LogWarning("استخدام دالة قديمة CreateUserFinancialAccountsAsync - يجب التحديث");
        // للتوافق المؤقت، ننشئ حساب عميل فقط
        return await CreateCustomerFinancialAccountAsync(userId, userName, cancellationToken);
    }

    /// <summary>
    /// التحقق من وجود عمليات مالية للمستخدم
    /// Check if user has financial transactions
    /// </summary>
    public async Task<bool> HasFinancialTransactionsAsync(Guid userId)
    {
        try
        {
            var transactions = await _transactionRepository.GetByUserIdAsync(userId);
            return transactions.Any();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في التحقق من العمليات المالية للمستخدم {UserId}", userId);
            return false;
        }
    }

    /// <summary>
    /// تسجيل إلغاء الحجز
    /// Record cancellation transaction
    /// </summary>
    public async Task<FinancialTransaction> RecordCancellationTransactionAsync(Guid bookingId, Guid userId)
    {
        try
        {
            var booking = await _bookingRepository.GetByIdAsync(bookingId);
            if (booking == null)
                throw new ArgumentException($"BookingDto {bookingId} not found");

            var transaction = new FinancialTransaction
            {
                TransactionNumber = await _transactionRepository.GenerateTransactionNumberAsync(),
                TransactionDate = DateTime.UtcNow,
                EntryType = JournalEntryType.GeneralJournal,
                TransactionType = TransactionType.BookingCancellation,
                Amount = booking.TotalPrice.Amount,
                Currency = booking.TotalPrice.Currency,
                Description = $"إلغاء الحجز رقم {booking.Id}",
                ReferenceNumber = booking.Id.ToString(),
                BookingId = bookingId,
                Status = TransactionStatus.Draft,
                CreatedBy = userId,
                CreatedAt = DateTime.UtcNow
            };

            await _transactionRepository.AddAsync(transaction);
            return transaction;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error recording cancellation for booking {bookingId}");
            throw;
        }
    }

    /// <summary>
    /// تسجيل استرداد مبلغ
    /// Record refund transaction
    /// </summary>
    public async Task<FinancialTransaction> RecordRefundTransactionAsync(Guid bookingId, decimal refundAmount, Guid userId)
    {
        return await RecordRefundTransactionAsync(bookingId, refundAmount, "استرداد", userId);
    }

    /// <summary>
    /// تسجيل دفعة للمالك
    /// Record owner payout
    /// </summary>
    public async Task<FinancialTransaction> RecordOwnerPayoutAsync(Guid propertyId, decimal amount, Guid userId)
    {
        try
        {
            var property = await _propertyRepository.GetByIdAsync(propertyId);
            if (property == null)
                throw new ArgumentException($"Property {propertyId} not found");

            var transaction = new FinancialTransaction
            {
                TransactionNumber = await _transactionRepository.GenerateTransactionNumberAsync(),
                TransactionDate = DateTime.UtcNow,
                EntryType = JournalEntryType.CashPayments,
                TransactionType = TransactionType.OwnerPayout,
                Amount = amount,
                Currency = "YER",
                Description = $"دفعة للمالك - العقار {property.Name}",
                PropertyId = propertyId,
                Status = TransactionStatus.Draft,
                CreatedBy = userId,
                CreatedAt = DateTime.UtcNow
            };

            await _transactionRepository.AddAsync(transaction);
            return transaction;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error recording owner payout for property {propertyId}");
            throw;
        }
    }

    /// <summary>
    /// تسجيل مصروف
    /// Record expense
    /// </summary>
    public async Task<FinancialTransaction> RecordExpenseAsync(string description, decimal amount, AccountType accountType, Guid userId)
    {
        try
        {
            var transaction = new FinancialTransaction
            {
                TransactionNumber = await _transactionRepository.GenerateTransactionNumberAsync(),
                TransactionDate = DateTime.UtcNow,
                EntryType = JournalEntryType.GeneralJournal,
                TransactionType = TransactionType.OperationalExpense,
                Amount = amount,
                Currency = "YER",
                Description = description,
                Status = TransactionStatus.Draft,
                CreatedBy = userId,
                CreatedAt = DateTime.UtcNow
            };

            await _transactionRepository.AddAsync(transaction);
            return transaction;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error recording expense: {description}");
            throw;
        }
    }

    /// <summary>
    /// الحصول على بيانات مخطط الإيرادات
    /// Get revenue chart data
    /// </summary>
    public async Task<List<FinancialChartDto>> GetRevenueChartDataAsync(DateTime startDate, DateTime endDate)
    {
        try
        {
            // استخدام ملخص مجمّع من قاعدة البيانات بدلاً من تحميل كل القيود
            var summary = await _transactionRepository.GetTransactionSummaryByTypeAsync(startDate, endDate);

            var revenueTypes = new[]
            {
                TransactionType.NewBooking,
                TransactionType.AdvancePayment,
                TransactionType.FinalPayment,
                TransactionType.PlatformCommission,
                TransactionType.ServiceFee,
                TransactionType.LateFee,
                TransactionType.OtherIncome
            };

            var revenueByType = revenueTypes
                .Select(t => new { Type = t, Value = summary.GetValueOrDefault(t, 0m) })
                .Where(x => x.Value > 0)
                .Select(x => new FinancialChartDto
                {
                    Label = GetTransactionTypeLabel(x.Type),
                    Value = x.Value,
                    Color = GetRevenueColor(x.Type),
                    Category = "Revenue"
                })
                .OrderByDescending(x => x.Value)
                .ToList();

            return revenueByType;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في الحصول على بيانات مخطط الإيرادات");
            throw;
        }
    }

    /// <summary>
    /// الحصول على بيانات مخطط المصروفات
    /// Get expense chart data
    /// </summary>
    public async Task<List<FinancialChartDto>> GetExpenseChartDataAsync(DateTime startDate, DateTime endDate)
    {
        try
        {
            // استخدام ملخص مجمّع من قاعدة البيانات بدلاً من تحميل كل القيود
            var summary = await _transactionRepository.GetTransactionSummaryByTypeAsync(startDate, endDate);

            var expenseTypes = new[]
            {
                TransactionType.OwnerPayout,
                TransactionType.Refund,
                TransactionType.OperationalExpense,
                TransactionType.Tax,
                TransactionType.AgentCommission,
                TransactionType.SecurityDepositRefund,
                TransactionType.Compensation
            };

            var expenseByType = expenseTypes
                .Select(t => new { Type = t, Value = summary.GetValueOrDefault(t, 0m) })
                .Where(x => x.Value > 0)
                .Select(x => new FinancialChartDto
                {
                    Label = GetTransactionTypeLabel(x.Type),
                    Value = x.Value,
                    Color = GetExpenseColor(x.Type),
                    Category = "Expense"
                })
                .OrderByDescending(x => x.Value)
                .ToList();

            return expenseByType;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في الحصول على بيانات مخطط المصروفات");
            throw;
        }
    }

    /// <summary>
    /// الحصول على بيانات التدفق النقدي
    /// Get cash flow chart data
    /// </summary>
    public async Task<List<FinancialChartDto>> GetCashFlowChartDataAsync(DateTime startDate, DateTime endDate)
    {
        try
        {
            // تقليل البيانات المسترجعة بدفع فلترة الحالة إلى قاعدة البيانات
            var transactions = await _transactionRepository.GetByPeriodAsync(
                startDate,
                endDate,
                TransactionStatus.Posted,
                null,
                null);
            
            // تجميع حسب الشهر
            var cashFlowByMonth = transactions
                .GroupBy(t => new { t.TransactionDate.Year, t.TransactionDate.Month })
                .Select(g =>
                {
                    var monthDate = new DateTime(g.Key.Year, g.Key.Month, 1, 0, 0, 0, DateTimeKind.Utc);
                    var revenues = g.Where(t => IsRevenueTransaction(t.TransactionType)).Sum(t => t.Amount);
                    var expenses = g.Where(t => IsExpenseTransaction(t.TransactionType)).Sum(t => t.Amount);
                    
                    return new FinancialChartDto
                    {
                        Label = GetMonthNameInArabic(g.Key.Month) + " " + g.Key.Year,
                        Value = revenues - expenses,
                        Date = monthDate,
                        Color = (revenues - expenses) >= 0 ? "#00FF88" : "#FF3366",
                        Category = "CashFlow"
                    };
                })
                .OrderBy(x => x.Date)
                .ToList();

            return cashFlowByMonth;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في الحصول على بيانات التدفق النقدي");
            throw;
        }
    }

    /// <summary>
    /// الحصول على الملخص المالي الشامل
    /// Get comprehensive financial summary
    /// </summary>
    public async Task<FinancialSummaryDto> GetFinancialSummaryAsync()
    {
        try
        {
            var now = DateTime.UtcNow;
            var startOfMonth = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);
            var endOfMonth = startOfMonth.AddMonths(1).AddDays(-1);

            // جلب جميع البيانات المطلوبة
            var allAccounts = await _accountRepository.GetAccountsTreeAsync();
            var monthTransactions = await _transactionRepository.GetByPeriodAsync(startOfMonth, endOfMonth);
            var allTransactions = await _transactionRepository.GetByPeriodAsync(
                DateTime.UtcNow.AddYears(-1), DateTime.UtcNow);
            var allBookings = await _bookingRepository.GetAllAsync();
            var bookings = allBookings.Where(b => 
                b.CreatedAt >= startOfMonth && b.CreatedAt <= endOfMonth).ToList();
            var properties = await _propertyRepository.GetAllAsync();
            var units = await _unitRepository.GetAllAsync();

            // حساب الأصول والخصوم
            var totalAssets = await CalculateTotalByAccountTypeAsync(AccountType.Assets);
            var totalLiabilities = await CalculateTotalByAccountTypeAsync(AccountType.Liabilities);
            var totalEquity = await CalculateTotalByAccountTypeAsync(AccountType.Equity);
            
            // حساب الأصول والخصوم المتداولة
            var currentAssets = await CalculateCurrentAssetsAsync();
            var currentLiabilities = await CalculateCurrentLiabilitiesAsync();
            var workingCapital = currentAssets - currentLiabilities;

            // حساب نسب السيولة
            var currentRatio = currentLiabilities > 0 ? currentAssets / currentLiabilities : 0;
            var quickRatio = currentLiabilities > 0 ? (currentAssets - 0) / currentLiabilities : 0; // نحتاج لطرح المخزون
            var cashRatio = currentLiabilities > 0 ? await GetCashBalanceAsync() / currentLiabilities : 0;

            // حساب نسب الديون
            var debtToEquityRatio = totalEquity > 0 ? totalLiabilities / totalEquity : 0;
            var debtToAssetsRatio = totalAssets > 0 ? totalLiabilities / totalAssets : 0;

            // حساب الإيرادات والمصروفات للشهر
            var monthRevenue = monthTransactions.Where(t => IsRevenueTransaction(t.TransactionType)).Sum(t => t.Amount);
            var monthExpenses = monthTransactions.Where(t => IsExpenseTransaction(t.TransactionType)).Sum(t => t.Amount);
            var monthProfit = monthRevenue - monthExpenses;

            // حساب نسب الربحية
            var returnOnAssets = totalAssets > 0 ? (monthProfit * 12) / totalAssets * 100 : 0; // سنوياً
            var returnOnEquity = totalEquity > 0 ? (monthProfit * 12) / totalEquity * 100 : 0; // سنوياً
            var grossProfitMargin = monthRevenue > 0 ? monthProfit / monthRevenue * 100 : 0;
            var netProfitMargin = monthRevenue > 0 ? monthProfit / monthRevenue * 100 : 0;
            var operatingProfitMargin = monthRevenue > 0 ? (monthProfit + 0) / monthRevenue * 100 : 0; // نحتاج للمصاريف التشغيلية

            // حساب التدفقات النقدية
            var cashFromOperations = monthTransactions.Where(t => 
                t.TransactionType != TransactionType.InterAccountTransfer).Sum(t =>
                IsRevenueTransaction(t.TransactionType) ? t.Amount : -t.Amount);
            
            // حساب معدل الإشغال
            var occupiedUnits = bookings.Select(b => b.UnitId).Distinct().Count();
            var totalUnitsCount = units.Count();
            var occupancyRate = totalUnitsCount > 0 ? (decimal)occupiedUnits / totalUnitsCount * 100 : 0;

            // حساب متوسط قيمة الحجز
            var averageBookingValue = bookings.Any() ? bookings.Average(b => b.TotalPrice.Amount) : 0;

            return new FinancialSummaryDto
            {
                // الأصول والخصوم
                TotalAssets = totalAssets,
                TotalLiabilities = totalLiabilities,
                TotalEquity = totalEquity,
                CurrentAssets = currentAssets,
                CurrentLiabilities = currentLiabilities,
                WorkingCapital = workingCapital,
                
                // نسب السيولة
                CurrentRatio = currentRatio,
                QuickRatio = quickRatio,
                CashRatio = cashRatio,
                
                // نسب الديون
                DebtToEquityRatio = debtToEquityRatio,
                DebtToAssetsRatio = debtToAssetsRatio,
                
                // نسب الربحية
                ReturnOnAssets = returnOnAssets,
                ReturnOnEquity = returnOnEquity,
                GrossProfitMargin = grossProfitMargin,
                NetProfitMargin = netProfitMargin,
                OperatingProfitMargin = operatingProfitMargin,
                
                // التدفق النقدي
                CashFromOperations = cashFromOperations,
                CashFromInvesting = 0, // يمكن حسابها لاحقاً
                CashFromFinancing = 0, // يمكن حسابها لاحقاً
                NetCashFlow = cashFromOperations,
                
                // مؤشرات إضافية
                ActiveBookings = bookings.Count(),
                TotalProperties = properties.Count(),
                TotalUnits = totalUnitsCount,
                OccupancyRate = occupancyRate,
                AverageBookingValue = averageBookingValue,
                CustomerAcquisitionCost = 0, // يمكن حسابها لاحقاً
                CustomerLifetimeValue = 0, // يمكن حسابها لاحقاً
                
                // التاريخ
                CalculatedAt = DateTime.UtcNow,
                PeriodStart = startOfMonth,
                PeriodEnd = endOfMonth
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في الحصول على الملخص المالي");
            throw;
        }
    }

    // دوال مساعدة
    private bool IsRevenueTransaction(TransactionType type)
    {
        return type == TransactionType.NewBooking ||
               type == TransactionType.AdvancePayment ||
               type == TransactionType.FinalPayment ||
               type == TransactionType.PlatformCommission ||
               type == TransactionType.ServiceFee ||
               type == TransactionType.LateFee ||
               type == TransactionType.OtherIncome;
    }

    private bool IsExpenseTransaction(TransactionType type)
    {
        return type == TransactionType.OwnerPayout ||
               type == TransactionType.Refund ||
               type == TransactionType.OperationalExpense ||
               type == TransactionType.Tax ||
               type == TransactionType.AgentCommission ||
               type == TransactionType.SecurityDepositRefund ||
               type == TransactionType.Compensation;
    }

    private string GetTransactionTypeLabel(TransactionType type)
    {
        return type switch
        {
            TransactionType.NewBooking => "حجوزات جديدة",
            TransactionType.AdvancePayment => "دفعات مقدمة",
            TransactionType.FinalPayment => "دفعات نهائية",
            TransactionType.PlatformCommission => "عمولات المنصة",
            TransactionType.ServiceFee => "رسوم خدمات",
            TransactionType.LateFee => "غرامات تأخير",
            TransactionType.OtherIncome => "إيرادات أخرى",
            TransactionType.OwnerPayout => "دفعات للملاك",
            TransactionType.Refund => "مستردات",
            TransactionType.OperationalExpense => "مصاريف تشغيلية",
            TransactionType.Tax => "ضرائب",
            TransactionType.AgentCommission => "عمولات وكلاء",
            TransactionType.SecurityDepositRefund => "استرداد تأمينات",
            TransactionType.Compensation => "تعويضات",
            _ => type.ToString()
        };
    }

    private string GetRevenueColor(TransactionType type)
    {
        return type switch
        {
            TransactionType.NewBooking => "#00FF88",
            TransactionType.AdvancePayment => "#4FACFE",
            TransactionType.FinalPayment => "#00D9FF",
            TransactionType.PlatformCommission => "#9D50FF",
            TransactionType.ServiceFee => "#FFB800",
            TransactionType.LateFee => "#FF9500",
            TransactionType.OtherIncome => "#8B95B7",
            _ => "#00FF88"
        };
    }

    private string GetExpenseColor(TransactionType type)
    {
        return type switch
        {
            TransactionType.OwnerPayout => "#FF3366",
            TransactionType.Refund => "#FF6B6B",
            TransactionType.OperationalExpense => "#FFB800",
            TransactionType.Tax => "#8B95B7",
            TransactionType.AgentCommission => "#A855F7",
            TransactionType.SecurityDepositRefund => "#F97316",
            TransactionType.Compensation => "#EF4444",
            _ => "#FF3366"
        };
    }

    private string GetMonthNameInArabic(int month)
    {
        return month switch
        {
            1 => "يناير",
            2 => "فبراير",
            3 => "مارس",
            4 => "أبريل",
            5 => "مايو",
            6 => "يونيو",
            7 => "يوليو",
            8 => "أغسطس",
            9 => "سبتمبر",
            10 => "أكتوبر",
            11 => "نوفمبر",
            12 => "ديسمبر",
            _ => ""
        };
    }

    private async Task<decimal> CalculateTotalByAccountTypeAsync(AccountType accountType)
    {
        var accounts = await _accountRepository.GetByAccountTypeAsync(accountType);
        decimal total = 0;
        
        foreach (var account in accounts)
        {
            var balance = await _transactionRepository.GetAccountBalanceAtDateAsync(account.Id, DateTime.UtcNow);
            total += balance;
        }
        
        return total;
    }

    private async Task<decimal> CalculateCurrentAssetsAsync()
    {
        // حساب الأصول المتداولة (النقد + الذمم المدينة + ...)
        var cashAccounts = await _accountRepository.GetSystemAccountAsync(SYSTEM_CASH_ACCOUNT);
        var bankAccounts = await _accountRepository.GetSystemAccountAsync(SYSTEM_BANK_ACCOUNT);
        var receivableAccounts = await _accountRepository.GetSystemAccountAsync(SYSTEM_RECEIVABLE_ACCOUNT);
        
        decimal total = 0;
        if (cashAccounts != null)
            total += await _transactionRepository.GetAccountBalanceAtDateAsync(cashAccounts.Id, DateTime.UtcNow);
        if (bankAccounts != null)
            total += await _transactionRepository.GetAccountBalanceAtDateAsync(bankAccounts.Id, DateTime.UtcNow);
        if (receivableAccounts != null)
            total += await _transactionRepository.GetAccountBalanceAtDateAsync(receivableAccounts.Id, DateTime.UtcNow);
            
        return total;
    }

    private async Task<decimal> CalculateCurrentLiabilitiesAsync()
    {
        // حساب الخصوم المتداولة
        var payableAccounts = await _accountRepository.GetSystemAccountAsync(SYSTEM_PAYABLE_ACCOUNT);
        var taxAccounts = await _accountRepository.GetSystemAccountAsync(SYSTEM_TAX_ACCOUNT);
        
        decimal total = 0;
        if (payableAccounts != null)
            total += await _transactionRepository.GetAccountBalanceAtDateAsync(payableAccounts.Id, DateTime.UtcNow);
        if (taxAccounts != null)
            total += await _transactionRepository.GetAccountBalanceAtDateAsync(taxAccounts.Id, DateTime.UtcNow);
            
        return total;
    }

    private async Task<decimal> GetCashBalanceAsync()
    {
        var cashAccounts = await _accountRepository.GetSystemAccountAsync(SYSTEM_CASH_ACCOUNT);
        var bankAccounts = await _accountRepository.GetSystemAccountAsync(SYSTEM_BANK_ACCOUNT);
        
        decimal total = 0;
        if (cashAccounts != null)
            total += await _transactionRepository.GetAccountBalanceAtDateAsync(cashAccounts.Id, DateTime.UtcNow);
        if (bankAccounts != null)
            total += await _transactionRepository.GetAccountBalanceAtDateAsync(bankAccounts.Id, DateTime.UtcNow);
            
        return total;
    }

    /// <summary>
    /// تسجيل قيد تأكيد الحجز - تحقق إيراد العمولة
    /// Record booking confirmation transaction - Commission revenue realization
    /// </summary>
    public async Task<FinancialTransaction> RecordBookingConfirmationTransactionAsync(Guid bookingId, Guid userId)
    {
        try
        {
            var booking = await _bookingRepository.GetByIdAsync(bookingId);
            if (booking == null)
                throw new ArgumentException($"BookingDto {bookingId} not found");

            // حساب العمولة
            var commissionRate = 0.05m; // 5% عمولة حسب المواصفات
            var totalAmount = booking.TotalPrice.Amount;
            var commissionAmount = totalAmount * commissionRate;

            // الحسابات المطلوبة
            var commissionPendingAccount = await _accountRepository.GetSystemAccountAsync(PLATFORM_COMMISSION_PENDING_ACCOUNT);
            var commissionRevenueAccount = await _accountRepository.GetSystemAccountAsync(SYSTEM_COMMISSION_ACCOUNT);

            // القيد المحاسبي: تحقق إيراد العمولة
            // من حـ/ عمولات المنصة المستحقة
            //     إلى حـ/ إيرادات عمولات المنصة
            var confirmationTransaction = new FinancialTransaction
            {
                TransactionNumber = await _transactionRepository.GenerateTransactionNumberAsync(),
                TransactionDate = DateTime.UtcNow,
                EntryType = JournalEntryType.GeneralJournal,
                TransactionType = TransactionType.PlatformCommission,
                DebitAccountId = commissionPendingAccount.Id,
                CreditAccountId = commissionRevenueAccount.Id,
                Amount = commissionAmount,
                Currency = booking.TotalPrice.Currency,
                ExchangeRate = 1,
                BaseAmount = commissionAmount,
                Description = $"تحقق إيراد عمولة الحجز {booking.Id}",
                Narration = $"تحقق إيراد العمولة عند تأكيد الحجز",
                ReferenceNumber = booking.Id.ToString(),
                DocumentType = "BookingConfirmation",
                BookingId = bookingId,
                Status = TransactionStatus.Posted,
                IsPosted = true,
                PostingDate = DateTime.UtcNow,
                FiscalYear = DateTime.UtcNow.Year,
                FiscalPeriod = DateTime.UtcNow.Month,
                Commission = commissionAmount,
                CommissionPercentage = commissionRate * 100,
                CreatedBy = userId,
                CreatedAt = DateTime.UtcNow,
                IsAutomatic = true,
                AutomaticSource = "BookingConfirmationSystem"
            };

            await _transactionRepository.AddAsync(confirmationTransaction);
            
            _logger.LogInformation($"BookingDto confirmation commission transaction recorded for booking {bookingId}");
            return confirmationTransaction;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error recording booking confirmation transaction for booking {bookingId}");
            throw;
        }
    }

    /// <summary>
    /// تسجيل قيد تسجيل الخروج - تحرير أموال المالك
    /// Record checkout transaction - Release owner funds
    /// </summary>
    public async Task<FinancialTransaction> RecordCheckoutTransactionAsync(Guid bookingId, Guid userId)
    {
        try
        {
            var booking = await _bookingRepository.GetByIdAsync(bookingId);
            if (booking == null)
                throw new ArgumentException($"BookingDto {bookingId} not found");

            var unit = await _unitRepository.GetByIdAsync(booking.UnitId);
            var property = await _propertyRepository.GetByIdAsync(unit.PropertyId);

            // حساب مبلغ المالك (بعد خصم العمولة)
            var commissionRate = 0.05m;
            var totalAmount = booking.TotalPrice.Amount;
            var commissionAmount = totalAmount * commissionRate;
            var ownerAmount = totalAmount - commissionAmount;

            // الحسابات المطلوبة
            var ownersPendingAccount = await _accountRepository.GetSystemAccountAsync(OWNERS_FUNDS_PENDING_ACCOUNT);
            var ownersPayableAccount = await GetOrCreateOwnerPayableAccountAsync(property.OwnerId, property.Owner?.Name ?? "Owner");

            // القيد المحاسبي: تحرير أموال المالك للدفع
            // من حـ/ أموال الملاك المعلقة
            //     إلى حـ/ ذمم دائنة - ملاك
            var checkoutTransaction = new FinancialTransaction
            {
                TransactionNumber = await _transactionRepository.GenerateTransactionNumberAsync(),
                TransactionDate = DateTime.UtcNow,
                EntryType = JournalEntryType.GeneralJournal,
                TransactionType = TransactionType.FinalPayment,
                DebitAccountId = ownersPendingAccount.Id,
                CreditAccountId = ownersPayableAccount.Id,
                Amount = ownerAmount,
                Currency = booking.TotalPrice.Currency,
                ExchangeRate = 1,
                BaseAmount = ownerAmount,
                Description = $"تحرير أموال المالك للحجز {booking.Id}",
                Narration = $"نقل المبلغ من معلق إلى مستحق الدفع للمالك عند تسجيل الخروج",
                ReferenceNumber = booking.Id.ToString(),
                DocumentType = "CheckOut",
                BookingId = bookingId,
                SecondPartyUserId = property.OwnerId,
                PropertyId = property.Id,
                Status = TransactionStatus.Posted,
                IsPosted = true,
                PostingDate = DateTime.UtcNow,
                FiscalYear = DateTime.UtcNow.Year,
                FiscalPeriod = DateTime.UtcNow.Month,
                NetAmount = ownerAmount,
                CreatedBy = userId,
                CreatedAt = DateTime.UtcNow,
                IsAutomatic = true,
                AutomaticSource = "CheckOutSystem"
            };

            await _transactionRepository.AddAsync(checkoutTransaction);
            
            _logger.LogInformation($"Checkout transaction recorded for booking {bookingId}");
            return checkoutTransaction;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error recording checkout transaction for booking {bookingId}");
            throw;
        }
    }

    /// <summary>
    /// تسجيل قيد إلغاء الحجز مع رسوم إلغاء
    /// Record cancellation with cancellation fees
    /// </summary>
    public async Task<FinancialTransaction> RecordCancellationWithFeesAsync(
        Guid bookingId, 
        decimal cancellationFeePercentage, 
        Guid userId)
    {
        try
        {
            var booking = await _bookingRepository.GetByIdAsync(bookingId);
            if (booking == null)
                throw new ArgumentException($"BookingDto {bookingId} not found");

            var unit = await _unitRepository.GetByIdAsync(booking.UnitId);
            var property = await _propertyRepository.GetByIdAsync(unit.PropertyId);
            var user = await _userRepository.GetByIdAsync(booking.UserId);

            var totalAmount = booking.TotalPrice.Amount;
            var cancellationFee = totalAmount * (cancellationFeePercentage / 100);
            var refundAmount = totalAmount - cancellationFee;

            // حساب توزيع رسوم الإلغاء
            var commissionRate = 0.10m;
            var ownerShareFromTotal = totalAmount * (1 - commissionRate);
            var platformShareFromTotal = totalAmount * commissionRate;

            // الحسابات المطلوبة
            var ownersPendingAccount = await _accountRepository.GetSystemAccountAsync(OWNERS_FUNDS_PENDING_ACCOUNT);
            var platformPendingAccount = await _accountRepository.GetSystemAccountAsync(PLATFORM_COMMISSION_PENDING_ACCOUNT);
            var customerAccount = await GetOrCreateUserAccountAsync(booking.UserId, user.Name, AccountType.Assets);
            var cancellationFeesAccount = await _accountRepository.GetSystemAccountAsync(CANCELLATION_FEES_ACCOUNT);

            // القيد الأول: إلغاء مع احتفاظ برسوم
            var cancellationTransaction = new FinancialTransaction
            {
                TransactionNumber = await _transactionRepository.GenerateTransactionNumberAsync(),
                TransactionDate = DateTime.UtcNow,
                EntryType = JournalEntryType.Reversal,
                TransactionType = TransactionType.BookingCancellation,
                DebitAccountId = ownersPendingAccount.Id,
                CreditAccountId = customerAccount.Id,
                Amount = totalAmount,
                Currency = booking.TotalPrice.Currency,
                ExchangeRate = 1,
                BaseAmount = totalAmount,
                Description = $"إلغاء الحجز {booking.Id} مع رسوم إلغاء {cancellationFeePercentage}%",
                Narration = $"إلغاء مع احتفاظ برسوم إلغاء {cancellationFee} {booking.TotalPrice.Currency}",
                ReferenceNumber = booking.Id.ToString(),
                DocumentType = "CancellationWithFees",
                BookingId = bookingId,
                FirstPartyUserId = booking.UserId,
                SecondPartyUserId = property.OwnerId,
                PropertyId = property.Id,
                Status = TransactionStatus.Posted,
                IsPosted = true,
                PostingDate = DateTime.UtcNow,
                FiscalYear = DateTime.UtcNow.Year,
                FiscalPeriod = DateTime.UtcNow.Month,
                CancellationReason = booking.CancellationReason,
                CancelledAt = DateTime.UtcNow,
                CancelledBy = userId,
                CreatedBy = userId,
                CreatedAt = DateTime.UtcNow,
                IsAutomatic = true,
                AutomaticSource = "CancellationSystem"
            };

            await _transactionRepository.AddAsync(cancellationTransaction);

            // القيد الثاني: تسجيل رسوم الإلغاء كإيراد
            if (cancellationFee > 0)
            {
                var feeTransaction = new FinancialTransaction
                {
                    TransactionNumber = await _transactionRepository.GenerateTransactionNumberAsync(),
                    TransactionDate = DateTime.UtcNow,
                    EntryType = JournalEntryType.GeneralJournal,
                    TransactionType = TransactionType.ServiceFee,
                    DebitAccountId = customerAccount.Id,
                    CreditAccountId = cancellationFeesAccount.Id,
                    Amount = cancellationFee,
                    Currency = booking.TotalPrice.Currency,
                    ExchangeRate = 1,
                    BaseAmount = cancellationFee,
                    Description = $"رسوم إلغاء الحجز {booking.Id}",
                    Narration = $"رسوم إلغاء بنسبة {cancellationFeePercentage}%",
                    ReferenceNumber = booking.Id.ToString(),
                    DocumentType = "CancellationFee",
                    BookingId = bookingId,
                    Status = TransactionStatus.Posted,
                    IsPosted = true,
                    PostingDate = DateTime.UtcNow,
                    FiscalYear = DateTime.UtcNow.Year,
                    FiscalPeriod = DateTime.UtcNow.Month,
                    CreatedBy = userId,
                    CreatedAt = DateTime.UtcNow,
                    IsAutomatic = true,
                    AutomaticSource = "CancellationFeeSystem"
                };

                await _transactionRepository.AddAsync(feeTransaction);
            }

            _logger.LogInformation($"Cancellation with fees transaction recorded for booking {bookingId}");
            return cancellationTransaction;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error recording cancellation with fees for booking {bookingId}");
            throw;
        }
    }

    /// <summary>
    /// تسجيل قيد خدمة إضافية
    /// Record additional service transaction
    /// </summary>
    public async Task<FinancialTransaction> RecordAdditionalServiceTransactionAsync(
        Guid bookingId,
        Guid serviceId,
        decimal serviceAmount,
        string serviceName,
        Guid userId)
    {
        try
        {
            var booking = await _bookingRepository.GetByIdAsync(bookingId);
            if (booking == null)
                throw new ArgumentException($"BookingDto {bookingId} not found");

            var unit = await _unitRepository.GetByIdAsync(booking.UnitId);
            var property = await _propertyRepository.GetByIdAsync(unit.PropertyId);
            var user = await _userRepository.GetByIdAsync(booking.UserId);

            // حساب العمولة على الخدمة الإضافية
            var commissionRate = 0.05m; // 5% عمولة على الخدمات الإضافية
            var commissionAmount = Math.Round(serviceAmount * commissionRate, 2);
            var ownerAmount = serviceAmount - commissionAmount;

            // الحسابات المطلوبة
            var customerAccount = await GetOrCreateUserAccountAsync(booking.UserId, user.Name, AccountType.Assets);
            var ownersPendingAccount = await _accountRepository.GetSystemAccountAsync(OWNERS_FUNDS_PENDING_ACCOUNT);
            var platformPendingAccount = await _accountRepository.GetSystemAccountAsync(PLATFORM_COMMISSION_PENDING_ACCOUNT);

            // القيد المحاسبي: خدمة إضافية
            // من حـ/ ذمم مدينة - عملاء
            //     إلى حـ/ أموال الملاك المعلقة (95%)
            //     إلى حـ/ عمولات المنصة المستحقة (5%)
            var serviceTransaction = new FinancialTransaction
            {
                TransactionNumber = await _transactionRepository.GenerateTransactionNumberAsync(),
                TransactionDate = DateTime.UtcNow,
                EntryType = JournalEntryType.Sales,
                TransactionType = TransactionType.ServiceFee,
                DebitAccountId = customerAccount.Id,
                CreditAccountId = ownersPendingAccount.Id,
                Amount = ownerAmount,
                Currency = booking.TotalPrice.Currency,
                ExchangeRate = 1,
                BaseAmount = ownerAmount,
                Description = $"خدمة إضافية: {serviceName} للحجز {booking.Id}",
                Narration = $"إضافة خدمة {serviceName} بقيمة {serviceAmount}",
                ReferenceNumber = serviceId.ToString(),
                DocumentType = "AdditionalService",
                BookingId = bookingId,
                FirstPartyUserId = booking.UserId,
                SecondPartyUserId = property.OwnerId,
                PropertyId = property.Id,
                Status = TransactionStatus.Posted,
                IsPosted = true,
                PostingDate = DateTime.UtcNow,
                FiscalYear = DateTime.UtcNow.Year,
                FiscalPeriod = DateTime.UtcNow.Month,
                Commission = commissionAmount,
                CommissionPercentage = commissionRate * 100,
                NetAmount = ownerAmount,
                CreatedBy = userId,
                CreatedAt = DateTime.UtcNow,
                IsAutomatic = true,
                AutomaticSource = "ServiceSystem"
            };

            await _transactionRepository.AddAsync(serviceTransaction);

            // قيد عمولة الخدمة الإضافية: من ح/ ذمم مدينة - عملاء إلى ح/ عمولات المنصة المستحقة (5%)
            if (commissionAmount > 0)
            {
                var commissionPendingAccount = await _accountRepository.GetSystemAccountAsync(PLATFORM_COMMISSION_PENDING_ACCOUNT);
                var serviceCommissionTx = new FinancialTransaction
                {
                    TransactionNumber = await _transactionRepository.GenerateTransactionNumberAsync(),
                    TransactionDate = DateTime.UtcNow,
                    EntryType = JournalEntryType.Sales,
                    TransactionType = TransactionType.PlatformCommission,
                    DebitAccountId = customerAccount.Id,
                    CreditAccountId = commissionPendingAccount.Id,
                    Amount = commissionAmount,
                    Currency = booking.TotalPrice.Currency,
                    ExchangeRate = 1,
                    BaseAmount = commissionAmount,
                    Description = $"عمولة خدمة إضافية: {serviceName} للحجز {booking.Id}",
                    Narration = $"عمولة {commissionRate * 100}% على الخدمة الإضافية",
                    ReferenceNumber = serviceId.ToString(),
                    DocumentType = "AdditionalServiceCommission",
                    BookingId = bookingId,
                    FirstPartyUserId = booking.UserId,
                    SecondPartyUserId = property.OwnerId,
                    PropertyId = property.Id,
                    Status = TransactionStatus.Posted,
                    IsPosted = true,
                    PostingDate = DateTime.UtcNow,
                    FiscalYear = DateTime.UtcNow.Year,
                    FiscalPeriod = DateTime.UtcNow.Month,
                    Commission = commissionAmount,
                    CommissionPercentage = commissionRate * 100,
                    NetAmount = 0,
                    CreatedBy = userId,
                    CreatedAt = DateTime.UtcNow,
                    IsAutomatic = true,
                    AutomaticSource = "ServiceSystem"
                };

                await _transactionRepository.AddAsync(serviceCommissionTx);
            }
            
            _logger.LogInformation($"Additional service transaction recorded for booking {bookingId}, service {serviceId}");
            return serviceTransaction;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error recording additional service transaction for booking {bookingId}");
            throw;
        }
    }

    /// <summary>
    /// إقفال الفترة المحاسبية
    /// Close accounting period
    /// </summary>
    public async Task<bool> CloseAccountingPeriodAsync(int year, int month, Guid userId)
    {
        try
        {
            _logger.LogInformation($"Starting accounting period closure for {month}/{year}");

            var startDate = new DateTime(year, month, 1, 0, 0, 0, DateTimeKind.Utc);
            var endDate = startDate.AddMonths(1).AddSeconds(-1);

            // الحصول على جميع المعاملات للفترة
            var periodTransactions = await _transactionRepository.GetByPeriodAsync(startDate, endDate);

            // التحقق من أن جميع المعاملات مرحلة
            var unpostedTransactions = periodTransactions.Where(t => !t.IsPosted).ToList();
            if (unpostedTransactions.Any())
            {
                _logger.LogWarning($"Cannot close period {month}/{year} - {unpostedTransactions.Count} unposted transactions found");
                return false;
            }

            // حساب مجاميع الإيرادات والمصروفات
            var totalRevenue = periodTransactions
                .Where(t => IsRevenueTransaction(t.TransactionType))
                .Sum(t => t.Amount);

            var totalExpenses = periodTransactions
                .Where(t => IsExpenseTransaction(t.TransactionType))
                .Sum(t => t.Amount);

            var netProfit = totalRevenue - totalExpenses;

            // الحسابات المطلوبة
            var revenueAccounts = await _accountRepository.GetByAccountTypeAsync(AccountType.Revenue);
            var expenseAccounts = await _accountRepository.GetByAccountTypeAsync(AccountType.Expenses);
            var retainedEarningsAccount = await _accountRepository.GetSystemAccountAsync("الأرباح المحتجزة");
            var incomeSummaryAccount = await _accountRepository.GetSystemAccountAsync("ملخص الدخل") 
                ?? await CreateIncomeSummaryAccountAsync();

            // قيد إقفال الإيرادات
            if (totalRevenue > 0)
            {
                foreach (var revenueAccount in revenueAccounts)
                {
                    var accountRevenue = periodTransactions
                        .Where(t => t.CreditAccountId == revenueAccount.Id)
                        .Sum(t => t.Amount);

                    if (accountRevenue > 0)
                    {
                        var closingEntry = new FinancialTransaction
                        {
                            TransactionNumber = await _transactionRepository.GenerateTransactionNumberAsync(),
                            TransactionDate = endDate,
                            EntryType = JournalEntryType.Closing,
                            TransactionType = TransactionType.Adjustment,
                            DebitAccountId = revenueAccount.Id,
                            CreditAccountId = incomeSummaryAccount.Id,
                            Amount = accountRevenue,
                            Currency = "YER",
                            ExchangeRate = 1,
                            BaseAmount = accountRevenue,
                            Description = $"إقفال حساب {revenueAccount.NameAr} للفترة {month}/{year}",
                            Narration = $"قيد إقفال الإيرادات",
                            ReferenceNumber = $"CLOSE-{year}{month:D2}",
                            DocumentType = "PeriodClosing",
                            Status = TransactionStatus.Posted,
                            IsPosted = true,
                            PostingDate = DateTime.UtcNow,
                            FiscalYear = year,
                            FiscalPeriod = month,
                            CreatedBy = userId,
                            CreatedAt = DateTime.UtcNow,
                            IsAutomatic = true,
                            AutomaticSource = "PeriodClosingSystem"
                        };

                        await _transactionRepository.AddAsync(closingEntry);
                    }
                }
            }

            // قيد إقفال المصروفات
            if (totalExpenses > 0)
            {
                foreach (var expenseAccount in expenseAccounts)
                {
                    var accountExpense = periodTransactions
                        .Where(t => t.DebitAccountId == expenseAccount.Id)
                        .Sum(t => t.Amount);

                    if (accountExpense > 0)
                    {
                        var closingEntry = new FinancialTransaction
                        {
                            TransactionNumber = await _transactionRepository.GenerateTransactionNumberAsync(),
                            TransactionDate = endDate,
                            EntryType = JournalEntryType.Closing,
                            TransactionType = TransactionType.Adjustment,
                            DebitAccountId = incomeSummaryAccount.Id,
                            CreditAccountId = expenseAccount.Id,
                            Amount = accountExpense,
                            Currency = "YER",
                            ExchangeRate = 1,
                            BaseAmount = accountExpense,
                            Description = $"إقفال حساب {expenseAccount.NameAr} للفترة {month}/{year}",
                            Narration = $"قيد إقفال المصروفات",
                            ReferenceNumber = $"CLOSE-{year}{month:D2}",
                            DocumentType = "PeriodClosing",
                            Status = TransactionStatus.Posted,
                            IsPosted = true,
                            PostingDate = DateTime.UtcNow,
                            FiscalYear = year,
                            FiscalPeriod = month,
                            CreatedBy = userId,
                            CreatedAt = DateTime.UtcNow,
                            IsAutomatic = true,
                            AutomaticSource = "PeriodClosingSystem"
                        };

                        await _transactionRepository.AddAsync(closingEntry);
                    }
                }
            }

            // قيد نقل صافي الربح/الخسارة إلى الأرباح المحتجزة
            if (netProfit != 0)
            {
                var profitTransferEntry = new FinancialTransaction
                {
                    TransactionNumber = await _transactionRepository.GenerateTransactionNumberAsync(),
                    TransactionDate = endDate,
                    EntryType = JournalEntryType.Closing,
                    TransactionType = TransactionType.Adjustment,
                    DebitAccountId = netProfit > 0 ? incomeSummaryAccount.Id : retainedEarningsAccount.Id,
                    CreditAccountId = netProfit > 0 ? retainedEarningsAccount.Id : incomeSummaryAccount.Id,
                    Amount = Math.Abs(netProfit),
                    Currency = "YER",
                    ExchangeRate = 1,
                    BaseAmount = Math.Abs(netProfit),
                    Description = netProfit > 0 
                        ? $"نقل صافي الربح للفترة {month}/{year}" 
                        : $"نقل صافي الخسارة للفترة {month}/{year}",
                    Narration = $"صافي {(netProfit > 0 ? "الربح" : "الخسارة")}: {Math.Abs(netProfit)} YER",
                    ReferenceNumber = $"PROFIT-{year}{month:D2}",
                    DocumentType = "ProfitTransfer",
                    Status = TransactionStatus.Posted,
                    IsPosted = true,
                    PostingDate = DateTime.UtcNow,
                    FiscalYear = year,
                    FiscalPeriod = month,
                    NetAmount = netProfit,
                    CreatedBy = userId,
                    CreatedAt = DateTime.UtcNow,
                    IsAutomatic = true,
                    AutomaticSource = "PeriodClosingSystem"
                };

                await _transactionRepository.AddAsync(profitTransferEntry);
            }

            _logger.LogInformation($"Accounting period {month}/{year} closed successfully. Net profit: {netProfit}");
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error closing accounting period {month}/{year}");
            throw;
        }
    }

    /// <summary>
    /// إنشاء حساب ملخص الدخل
    /// Create income summary account
    /// </summary>
    private async Task<ChartOfAccount> CreateIncomeSummaryAccountAsync()
    {
        var incomeSummaryAccount = new ChartOfAccount
        {
            Id = Guid.NewGuid(),
            AccountNumber = "3900",
            NameAr = "ملخص الدخل",
            NameEn = "Income Summary",
            AccountType = AccountType.Equity,
            Category = AccountCategory.Sub,
            NormalBalance = AccountNature.Credit,
            Level = 2,
            Description = "حساب مؤقت لإقفال الإيرادات والمصروفات",
            IsActive = true,
            IsSystemAccount = true,
            CanPost = true,
            CreatedAt = DateTime.UtcNow
        };

        await _accountRepository.AddAsync(incomeSummaryAccount);
        return incomeSummaryAccount;
    }

    /// <summary>
    /// تحويل مستحقات الملاك
    /// Transfer owner payouts
    /// </summary>
    public async Task<int> ProcessOwnerPayoutsAsync(Guid userId)
    {
        try
        {
            _logger.LogInformation("Starting owner payouts processing");

            // الحصول على جميع المبالغ المستحقة للملاك
            var payableAccount = await _accountRepository.GetSystemAccountAsync(SYSTEM_PAYABLE_ACCOUNT);
            var bankAccount = await _accountRepository.GetSystemAccountAsync(SYSTEM_BANK_ACCOUNT);

            // الحصول على قائمة الملاك مع أرصدتهم المستحقة
            var allUsers = await _userRepository.GetAllAsync();
            var allProperties = await _propertyRepository.GetAllAsync();
            var ownerIds = allProperties.Select(p => p.OwnerId).Distinct();
            var owners = allUsers.Where(u => ownerIds.Contains(u.Id)).ToList();
            int payoutsProcessed = 0;

            foreach (var owner in owners)
            {
                var ownerPayableAccount = await GetOrCreateOwnerPayableAccountAsync(owner.Id, owner.Name);
                var balance = await _transactionRepository.GetAccountBalanceAtDateAsync(ownerPayableAccount.Id, DateTime.UtcNow);

                if (balance > 0)
                {
                    // القيد المحاسبي: تسديد مستحقات الملاك
                    // من حـ/ ذمم دائنة - ملاك
                    //     إلى حـ/ البنك - تحويلات
                    var payoutTransaction = new FinancialTransaction
                    {
                        TransactionNumber = await _transactionRepository.GenerateTransactionNumberAsync(),
                        TransactionDate = DateTime.UtcNow,
                        EntryType = JournalEntryType.CashPayments,
                        TransactionType = TransactionType.OwnerPayout,
                        DebitAccountId = ownerPayableAccount.Id,
                        CreditAccountId = bankAccount.Id,
                        Amount = balance,
                        Currency = "YER",
                        ExchangeRate = 1,
                        BaseAmount = balance,
                        Description = $"تحويل مستحقات المالك {owner.Name}",
                        Narration = $"تحويل مستحقات مجمعة بقيمة {balance} YER",
                        ReferenceNumber = $"PAYOUT-{DateTime.UtcNow:yyyyMMdd}-{owner.Id}",
                        DocumentType = "OwnerPayout",
                        SecondPartyUserId = owner.Id,
                        Status = TransactionStatus.Posted,
                        IsPosted = true,
                        PostingDate = DateTime.UtcNow,
                        FiscalYear = DateTime.UtcNow.Year,
                        FiscalPeriod = DateTime.UtcNow.Month,
                        NetAmount = balance,
                        CreatedBy = userId,
                        CreatedAt = DateTime.UtcNow,
                        IsAutomatic = true,
                        AutomaticSource = "PayoutSystem"
                    };

                    await _transactionRepository.AddAsync(payoutTransaction);
                    payoutsProcessed++;
                    
                    _logger.LogInformation($"Processed payout for owner {owner.Name}: {balance} YER");
                }
            }

            _logger.LogInformation($"Owner payouts processing completed. {payoutsProcessed} payouts processed");
            return payoutsProcessed;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing owner payouts");
            throw;
        }
    }
}
