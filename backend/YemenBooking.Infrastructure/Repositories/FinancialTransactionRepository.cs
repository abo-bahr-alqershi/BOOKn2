using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Infrastructure.Persistence.Repositories;
using YemenBooking.Core.Entities;
using InfrastructureDbContext = YemenBooking.Infrastructure.Data.Context.YemenBookingDbContext;

namespace YemenBooking.Infrastructure.Repositories;

/// <summary>
/// مستودع القيود المحاسبية
/// Financial Transactions Repository
/// </summary>
public class FinancialTransactionRepository : BaseRepository<FinancialTransaction>, IFinancialTransactionRepository
{
    public FinancialTransactionRepository(InfrastructureDbContext context) : base(context)
    {
    }

    /// <summary>
    /// إضافة معاملة جديدة
    /// Add new transaction
    /// </summary>
    public async Task<FinancialTransaction> AddAsync(FinancialTransaction transaction)
    {
        await _context.FinancialTransactions.AddAsync(transaction);
        await _context.SaveChangesAsync();
        return transaction;
    }

    /// <summary>
    /// إنشاء رقم قيد جديد تلقائي
    /// Generate new transaction number
    /// </summary>
    public async Task<string> GenerateTransactionNumberAsync()
    {
        var year = DateTime.UtcNow.Year;
        var month = DateTime.UtcNow.Month.ToString("D2");
        
        var lastTransaction = await _context.FinancialTransactions
            .AsNoTracking()
            .Where(t => t.TransactionNumber.StartsWith($"JV-{year}{month}"))
            .OrderByDescending(t => t.TransactionNumber)
            .FirstOrDefaultAsync();

        if (lastTransaction == null)
        {
            return $"JV-{year}{month}0001";
        }

        var lastNumber = lastTransaction.TransactionNumber.Substring(10);
        var nextNumber = (int.Parse(lastNumber) + 1).ToString("D4");
        return $"JV-{year}{month}{nextNumber}";
    }

    /// <summary>
    /// الحصول على القيود حسب الحجز
    /// Get transactions by booking
    /// </summary>
    public async Task<List<FinancialTransaction>> GetByBookingIdAsync(Guid bookingId)
    {
        return await _context.FinancialTransactions
            .AsNoTracking()
            .Include(t => t.DebitAccount)
            .Include(t => t.CreditAccount)
            .Include(t => t.FirstPartyUser)
            .Include(t => t.SecondPartyUser)
            .Where(t => t.BookingId == bookingId)
            .OrderBy(t => t.TransactionDate)
            .ToListAsync();
    }

    /// <summary>
    /// الحصول على القيود حسب الدفعة
    /// Get transactions by payment
    /// </summary>
    public async Task<List<FinancialTransaction>> GetByPaymentIdAsync(Guid paymentId)
    {
        return await _context.FinancialTransactions
            .AsNoTracking()
            .Include(t => t.DebitAccount)
            .Include(t => t.CreditAccount)
            .Include(t => t.FirstPartyUser)
            .Include(t => t.SecondPartyUser)
            .Where(t => t.PaymentId == paymentId)
            .OrderBy(t => t.TransactionDate)
            .ToListAsync();
    }

    /// <summary>
    /// الحصول على القيود حسب المستخدم (كطرف أول أو ثاني)
    /// Get transactions by user (as first or second party)
    /// </summary>
    public async Task<List<FinancialTransaction>> GetByUserIdAsync(Guid userId)
    {
        return await _context.FinancialTransactions
            .AsNoTracking()
            .Include(t => t.DebitAccount)
            .Include(t => t.CreditAccount)
            .Include(t => t.Property)
            .Include(t => t.Unit)
            .Where(t => t.FirstPartyUserId == userId || t.SecondPartyUserId == userId)
            .OrderByDescending(t => t.TransactionDate)
            .ToListAsync();
    }

    /// <summary>
    /// الحصول على القيود حسب العقار
    /// Get transactions by property
    /// </summary>
    public async Task<List<FinancialTransaction>> GetByPropertyIdAsync(Guid propertyId)
    {
        return await _context.FinancialTransactions
            .AsNoTracking()
            .Include(t => t.DebitAccount)
            .Include(t => t.CreditAccount)
            .Include(t => t.FirstPartyUser)
            .Include(t => t.SecondPartyUser)
            .Where(t => t.PropertyId == propertyId)
            .OrderByDescending(t => t.TransactionDate)
            .ToListAsync();
    }

    /// <summary>
    /// الحصول على القيود حسب الحساب
    /// Get transactions by account
    /// </summary>
    public async Task<List<FinancialTransaction>> GetByAccountIdAsync(Guid accountId)
    {
        return await _context.FinancialTransactions
            .AsNoTracking()
            .Include(t => t.DebitAccount)
            .Include(t => t.CreditAccount)
            .Where(t => t.DebitAccountId == accountId || t.CreditAccountId == accountId)
            .OrderByDescending(t => t.TransactionDate)
            .ToListAsync();
    }

    /// <summary>
    /// الحصول على القيود حسب الفترة
    /// Get transactions by period
    /// </summary>
    public async Task<List<FinancialTransaction>> GetByPeriodAsync(DateTime startDate, DateTime endDate)
    {
        return await _context.FinancialTransactions
            .AsNoTracking()
            .Include(t => t.DebitAccount)
            .Include(t => t.CreditAccount)
            .Where(t => t.TransactionDate >= startDate && t.TransactionDate <= endDate)
            .OrderBy(t => t.TransactionDate)
            .ToListAsync();

    }

    /// <summary>
    /// الحصول على القيود حسب الفترة مع فلاتر اختيارية وحد أعلى للنتائج
    /// Get transactions by period with optional filters and limit
    /// </summary>
    public async Task<List<FinancialTransaction>> GetByPeriodAsync(
        DateTime startDate,
        DateTime endDate,
        TransactionStatus? status,
        TransactionType? type,
        int? limit)
    {
        var query = _context.FinancialTransactions
            .AsNoTracking()
            .Include(t => t.DebitAccount)
            .Include(t => t.CreditAccount)
            .Where(t => t.TransactionDate >= startDate && t.TransactionDate <= endDate);

        if (status.HasValue)
            query = query.Where(t => t.Status == status.Value);

        if (type.HasValue)
            query = query.Where(t => t.TransactionType == type.Value);

        query = query
            .OrderByDescending(t => t.TransactionDate)
            .ThenByDescending(t => t.TransactionNumber);

        if (limit.HasValue && limit.Value > 0)
            query = query.Take(limit.Value);

        return await query.ToListAsync();
    }

    /// <summary>
    /// الحصول على القيود حسب الحالة
    /// Get transactions by status
    /// </summary>
    public async Task<List<FinancialTransaction>> GetByStatusAsync(TransactionStatus status)
    {
        return await _context.FinancialTransactions
            .AsNoTracking()
            .Include(t => t.DebitAccount)
            .Include(t => t.CreditAccount)
            .Where(t => t.Status == status)
            .OrderByDescending(t => t.TransactionDate)
            .ToListAsync();
    }

    /// <summary>
    /// الحصول على القيود المعلقة للترحيل
    /// Get pending transactions for posting
    /// </summary>
    public async Task<List<FinancialTransaction>> GetPendingForPostingAsync()
    {
        return await _context.FinancialTransactions
            .Include(t => t.DebitAccount)
            .Include(t => t.CreditAccount)
            .Where(t => t.Status == TransactionStatus.Approved && !t.IsPosted)
            .OrderBy(t => t.TransactionDate)
            .ToListAsync();
    }

    /// <summary>
    /// ترحيل القيد
    /// Post transaction
    /// </summary>
    public async Task<bool> PostTransactionAsync(Guid transactionId)
    {
        var transaction = await _context.FinancialTransactions
            .Include(t => t.DebitAccount)
            .Include(t => t.CreditAccount)
            .FirstOrDefaultAsync(t => t.Id == transactionId);

        if (transaction == null || transaction.IsPosted)
            return false;

        transaction.IsPosted = true;
        transaction.PostingDate = DateTime.UtcNow;
        transaction.Status = TransactionStatus.Posted;

        // تحديث أرصدة الحسابات
        transaction.DebitAccount.Balance += transaction.Amount;
        transaction.CreditAccount.Balance -= transaction.Amount;

        await _context.SaveChangesAsync();
        return true;
    }

    /// <summary>
    /// عكس القيد
    /// Reverse transaction
    /// </summary>
    public async Task<FinancialTransaction?> ReverseTransactionAsync(Guid transactionId, string reason, Guid userId)
    {
        var originalTransaction = await _context.FinancialTransactions
            .Include(t => t.DebitAccount)
            .Include(t => t.CreditAccount)
            .FirstOrDefaultAsync(t => t.Id == transactionId);

        if (originalTransaction == null || originalTransaction.IsReversed)
            return null;

        // إنشاء قيد عكسي
        var reverseTransaction = new FinancialTransaction
        {
            TransactionNumber = await GenerateTransactionNumberAsync(),
            TransactionDate = DateTime.UtcNow,
            EntryType = JournalEntryType.Reversal,
            TransactionType = originalTransaction.TransactionType,
            DebitAccountId = originalTransaction.CreditAccountId, // عكس الحسابات
            CreditAccountId = originalTransaction.DebitAccountId,
            Amount = originalTransaction.Amount,
            Currency = originalTransaction.Currency,
            ExchangeRate = originalTransaction.ExchangeRate,
            BaseAmount = originalTransaction.BaseAmount,
            Description = $"عكس القيد: {originalTransaction.Description}",
            Narration = $"سبب العكس: {reason}",
            ReferenceNumber = originalTransaction.TransactionNumber,
            DocumentType = "Reversal",
            BookingId = originalTransaction.BookingId,
            PaymentId = originalTransaction.PaymentId,
            FirstPartyUserId = originalTransaction.SecondPartyUserId, // عكس الأطراف
            SecondPartyUserId = originalTransaction.FirstPartyUserId,
            PropertyId = originalTransaction.PropertyId,
            UnitId = originalTransaction.UnitId,
            Status = TransactionStatus.Approved,
            IsPosted = false,
            FiscalYear = DateTime.UtcNow.Year,
            FiscalPeriod = DateTime.UtcNow.Month,
            CreatedBy = userId,
            IsAutomatic = true,
            AutomaticSource = "Reversal"
        };

        // تحديث القيد الأصلي
        originalTransaction.IsReversed = true;
        originalTransaction.ReverseTransactionId = reverseTransaction.Id;

        await _context.FinancialTransactions.AddAsync(reverseTransaction);
        await _context.SaveChangesAsync();

        return reverseTransaction;
    }

    /// <summary>
    /// الحصول على ملخص القيود حسب النوع
    /// Get transaction summary by type
    /// </summary>
    public async Task<Dictionary<TransactionType, decimal>> GetTransactionSummaryByTypeAsync(DateTime startDate, DateTime endDate)
    {
        var summary = await _context.FinancialTransactions
            .Where(t => t.TransactionDate >= startDate 
                        && t.TransactionDate <= endDate 
                        && t.IsPosted 
                        && t.Status == TransactionStatus.Posted)
            .GroupBy(t => t.TransactionType)
            .Select(g => new { Type = g.Key, Total = g.Sum(t => t.Amount) })
            .ToDictionaryAsync(x => x.Type, x => x.Total);

        return summary;
    }

    /// <summary>
    /// الحصول على رصيد الحساب في تاريخ معين
    /// Get account balance at specific date
    /// </summary>
    public async Task<decimal> GetAccountBalanceAtDateAsync(Guid accountId, DateTime date)
    {
        var debits = await _context.FinancialTransactions
            .Where(t => t.DebitAccountId == accountId 
                        && t.TransactionDate <= date 
                        && t.IsPosted 
                        && t.Status == TransactionStatus.Posted)
            .SumAsync(t => t.Amount);

        var credits = await _context.FinancialTransactions
            .Where(t => t.CreditAccountId == accountId 
                        && t.TransactionDate <= date 
                        && t.IsPosted 
                        && t.Status == TransactionStatus.Posted)
            .SumAsync(t => t.Amount);

        return debits - credits;
    }

    /// <summary>
    /// الحصول على كشف حساب
    /// Get account statement
    /// </summary>
    public async Task<List<FinancialTransaction>> GetAccountStatementAsync(
        Guid accountId, 
        DateTime startDate, 
        DateTime endDate)
    {
        return await _context.FinancialTransactions
            .AsNoTracking()
            .Include(t => t.DebitAccount)
            .Include(t => t.CreditAccount)
            .Include(t => t.Booking)
            .Include(t => t.Payment)
            .Where(t => (t.DebitAccountId == accountId || t.CreditAccountId == accountId) 
                && t.TransactionDate >= startDate 
                && t.TransactionDate <= endDate 
                && t.IsPosted
                && t.Status == TransactionStatus.Posted)
            .OrderBy(t => t.TransactionDate)
            .ThenBy(t => t.TransactionNumber)
            .ToListAsync();
    }

    /// <summary>
    /// البحث في القيود
    /// Search transactions
    /// </summary>
    public async Task<List<FinancialTransaction>> SearchTransactionsAsync(
        string searchTerm,
        TransactionType? transactionType = null,
        TransactionStatus? status = null,
        DateTime? startDate = null,
        DateTime? endDate = null)
    {
        var query = _context.FinancialTransactions
            .AsNoTracking()
            .Include(t => t.DebitAccount)
            .Include(t => t.CreditAccount)
            .Include(t => t.FirstPartyUser)
            .Include(t => t.SecondPartyUser)
            .AsQueryable();

        if (!string.IsNullOrEmpty(searchTerm))
        {
            query = query.Where(t => 
                t.TransactionNumber.Contains(searchTerm) ||
                t.Description.Contains(searchTerm) ||
                t.ReferenceNumber.Contains(searchTerm) ||
                t.Narration.Contains(searchTerm));
        }

        if (transactionType.HasValue)
            query = query.Where(t => t.TransactionType == transactionType.Value);

        if (status.HasValue)
            query = query.Where(t => t.Status == status.Value);

        if (startDate.HasValue)
            query = query.Where(t => t.TransactionDate >= startDate.Value);

        if (endDate.HasValue)
            query = query.Where(t => t.TransactionDate <= endDate.Value);

        return await query
            .OrderByDescending(t => t.TransactionDate)
            .Take(100)
            .ToListAsync();
    }

    /// <summary>
    /// عدّ القيود ضمن فترة معينة مع فلاتر اختيارية
    /// Count transactions in a period with optional filters
    /// </summary>
    public async Task<int> CountByPeriodAsync(
        DateTime startDate,
        DateTime endDate,
        TransactionStatus? status,
        TransactionType? type)
    {
        var query = _context.FinancialTransactions
            .AsNoTracking()
            .Where(t => t.TransactionDate >= startDate && t.TransactionDate <= endDate);

        if (status.HasValue)
            query = query.Where(t => t.Status == status.Value);

        if (type.HasValue)
            query = query.Where(t => t.TransactionType == type.Value);

        return await query.CountAsync();
    }

    /// <summary>
    /// الحصول على أرصدة متعددة للحسابات في استعلام واحد
    /// Get multiple account balances in a single query
    /// </summary>
    public async Task<Dictionary<Guid, decimal>> GetAccountsBalancesAsync(List<Guid> accountIds, DateTime asOfDate)
    {
        if (accountIds == null || !accountIds.Any())
            return new Dictionary<Guid, decimal>();

        // استخدام SQL خام محسن للأداء الأمثل
        // ملاحظة: PostgreSQL يحول الأسماء بدون علامات اقتباس إلى lowercase
        var sql = @"
            WITH accountbalances AS (
                SELECT 
                    acc.""Id"" AS accountid,
                    acc.""AccountType"" AS accounttype,
                    COALESCE(SUM(CASE WHEN t.""DebitAccountId"" = acc.""Id"" THEN t.""Amount"" ELSE 0 END), 0) AS totaldebit,
                    COALESCE(SUM(CASE WHEN t.""CreditAccountId"" = acc.""Id"" THEN t.""Amount"" ELSE 0 END), 0) AS totalcredit
                FROM ""ChartOfAccounts"" acc
                LEFT JOIN ""FinancialTransactions"" t ON 
                    (t.""DebitAccountId"" = acc.""Id"" OR t.""CreditAccountId"" = acc.""Id"")
                    AND t.""Status"" = @status
                    AND t.""TransactionDate"" <= @asOfDate
                WHERE acc.""Id"" IN ({0})
                GROUP BY acc.""Id"", acc.""AccountType""
            )
            SELECT 
                accountid,
                CASE 
                    WHEN accounttype IN (1, 5) -- Assets, Expenses (AccountType enum)
                        THEN totaldebit - totalcredit
                    ELSE -- Liabilities, Equity, Revenue  
                        totalcredit - totaldebit
                END AS balance
            FROM accountbalances";

        // بناء قائمة المعاملات مع أسماء واضحة للمعاملات
        var parameterDefinitions = new List<(string Name, object Value)>
        {
            ("@status", (int)TransactionStatus.Posted),
            ("@asOfDate", asOfDate)
        };

        var accountIdParams = string.Join(",", accountIds.Select((id, index) =>
        {
            var parameterName = $"@accountId{index}";
            parameterDefinitions.Add((parameterName, id));
            return parameterName;
        }));

        sql = string.Format(sql, accountIdParams);

        // تنفيذ الاستعلام باستخدام DbCommand مع المعاملات المسماة
        using var command = _context.Database.GetDbConnection().CreateCommand();
        command.CommandText = sql;
        foreach (var (name, value) in parameterDefinitions)
        {
            var parameter = command.CreateParameter();
            parameter.ParameterName = name;
            parameter.Value = value ?? DBNull.Value;
            command.Parameters.Add(parameter);
        }
        
        await _context.Database.OpenConnectionAsync();
        
        var result = new Dictionary<Guid, decimal>();
        using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            var accountId = reader.GetGuid(0);
            var balance = reader.GetDecimal(1);
            result[accountId] = balance;
        }
        
        return result;
    }
    
    // Helper class for query results
    private class AccountBalanceResult
    {
        public Guid AccountId { get; set; }
        public decimal Balance { get; set; }
    }
}
