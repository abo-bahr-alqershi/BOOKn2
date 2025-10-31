using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Infrastructure.Persistence.Repositories;

/// <summary>
/// واجهة مستودع القيود المحاسبية
/// Financial Transactions Repository Interface
/// </summary>
public interface IFinancialTransactionRepository
{
    /// <summary>
    /// إضافة معاملة جديدة
    /// Add new transaction
    /// </summary>
    Task<FinancialTransaction> AddAsync(FinancialTransaction transaction);
    
    /// <summary>
    /// إنشاء رقم قيد جديد تلقائي
    /// Generate new transaction number
    /// </summary>
    Task<string> GenerateTransactionNumberAsync();

    /// <summary>
    /// الحصول على القيود حسب الحجز
    /// Get transactions by booking
    /// </summary>
    Task<List<FinancialTransaction>> GetByBookingIdAsync(Guid bookingId);

    /// <summary>
    /// الحصول على القيود حسب الدفعة
    /// Get transactions by payment
    /// </summary>
    Task<List<FinancialTransaction>> GetByPaymentIdAsync(Guid paymentId);

    /// <summary>
    /// الحصول على القيود حسب المستخدم
    /// Get transactions by user
    /// </summary>
    Task<List<FinancialTransaction>> GetByUserIdAsync(Guid userId);

    /// <summary>
    /// الحصول على القيود حسب العقار
    /// Get transactions by property
    /// </summary>
    Task<List<FinancialTransaction>> GetByPropertyIdAsync(Guid propertyId);

    /// <summary>
    /// الحصول على القيود حسب الحساب
    /// Get transactions by account
    /// </summary>
    Task<List<FinancialTransaction>> GetByAccountIdAsync(Guid accountId);

    /// <summary>
    /// الحصول على القيود حسب الفترة
    /// Get transactions by period
    /// </summary>
    Task<List<FinancialTransaction>> GetByPeriodAsync(DateTime startDate, DateTime endDate);

    /// <summary>
    /// الحصول على القيود حسب الفترة مع فلاتر اختيارية وحد أعلى للنتائج
    /// Get transactions by period with optional filters and limit
    /// </summary>
    Task<List<FinancialTransaction>> GetByPeriodAsync(DateTime startDate, DateTime endDate, TransactionStatus? status, TransactionType? type, int? limit);

    /// <summary>
    /// الحصول على القيود حسب الحالة
    /// Get transactions by status
    /// </summary>
    Task<List<FinancialTransaction>> GetByStatusAsync(TransactionStatus status);

    /// <summary>
    /// الحصول على القيود المعلقة للترحيل
    /// Get pending transactions for posting
    /// </summary>
    Task<List<FinancialTransaction>> GetPendingForPostingAsync();

    /// <summary>
    /// ترحيل القيد
    /// Post transaction
    /// </summary>
    Task<bool> PostTransactionAsync(Guid transactionId);

    /// <summary>
    /// عكس القيد
    /// Reverse transaction
    /// </summary>
    Task<FinancialTransaction?> ReverseTransactionAsync(Guid transactionId, string reason, Guid userId);

    /// <summary>
    /// الحصول على ملخص القيود حسب النوع
    /// Get transaction summary by type
    /// </summary>
    Task<Dictionary<TransactionType, decimal>> GetTransactionSummaryByTypeAsync(DateTime startDate, DateTime endDate);

    /// <summary>
    /// عدّ القيود ضمن فترة معينة مع فلاتر اختيارية
    /// Count transactions in a period with optional filters
    /// </summary>
    Task<int> CountByPeriodAsync(DateTime startDate, DateTime endDate, TransactionStatus? status, TransactionType? type);

    /// <summary>
    /// الحصول على رصيد الحساب في تاريخ معين
    /// Get account balance at specific date
    /// </summary>
    Task<decimal> GetAccountBalanceAtDateAsync(Guid accountId, DateTime asOfDate);
    
    /// <summary>
    /// الحصول على أرصدة متعددة للحسابات في استعلام واحد
    /// Get multiple account balances in a single query
    /// </summary>
    Task<Dictionary<Guid, decimal>> GetAccountsBalancesAsync(List<Guid> accountIds, DateTime asOfDate);

    /// <summary>
    /// الحصول على كشف حساب
    /// Get account statement
    /// </summary>
    Task<List<FinancialTransaction>> GetAccountStatementAsync(Guid accountId, DateTime startDate, DateTime endDate);

    /// <summary>
    /// البحث في القيود
    /// Search transactions
    /// </summary>
    Task<List<FinancialTransaction>> SearchTransactionsAsync(
        string searchTerm,
        TransactionType? transactionType = null,
        TransactionStatus? status = null,
        DateTime? startDate = null,
        DateTime? endDate = null);
}
