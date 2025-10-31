using System;
using System.Linq;
using System.Collections.Generic;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Common.Models;

/// <summary>
/// DTO للعمليات المالية - يمنع المراجع الدائرية
/// Financial Transaction DTO - Prevents circular references
/// </summary>
public class FinancialTransactionDto
{
    public Guid Id { get; set; }
    public string TransactionNumber { get; set; }
    public DateTime TransactionDate { get; set; }
    public JournalEntryType EntryType { get; set; }
    public TransactionType TransactionType { get; set; }
    public Guid DebitAccountId { get; set; }
    public Guid CreditAccountId { get; set; }
    public decimal Amount { get; set; }
    public string Currency { get; set; }
    public decimal ExchangeRate { get; set; }
    public decimal BaseAmount { get; set; }
    public string Description { get; set; }
    public string Narration { get; set; }
    public string ReferenceNumber { get; set; }
    public string DocumentType { get; set; }
    public Guid? BookingId { get; set; }
    public Guid? PaymentId { get; set; }
    public Guid? FirstPartyUserId { get; set; }
    public Guid? SecondPartyUserId { get; set; }
    public Guid? PropertyId { get; set; }
    public Guid? UnitId { get; set; }
    public TransactionStatus Status { get; set; }
    public DateTime? PostingDate { get; set; }
    public bool IsPosted { get; set; }
    public bool IsReversed { get; set; }
    public Guid? ReverseTransactionId { get; set; }
    public int FiscalYear { get; set; }
    public int FiscalPeriod { get; set; }
    public Guid? JournalId { get; set; }
    public string BatchNumber { get; set; }
    public string Notes { get; set; }
    public decimal? Commission { get; set; }
    public decimal? CommissionPercentage { get; set; }
    public decimal? Tax { get; set; }
    public decimal? TaxPercentage { get; set; }
    public decimal? Discount { get; set; }
    public decimal? DiscountPercentage { get; set; }
    public decimal NetAmount { get; set; }
    public DateTime CreatedAt { get; set; }
    public Guid? CreatedBy { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public Guid? UpdatedBy { get; set; }
    public bool IsAutomatic { get; set; }
    public string AutomaticSource { get; set; }
    
    // معلومات الحسابات بدون العلاقات الدائرية
    // Account information without circular relationships
    public SimpleAccountDto DebitAccount { get; set; }
    public SimpleAccountDto CreditAccount { get; set; }

    /// <summary>
    /// تحويل من Entity إلى DTO
    /// Convert from Entity to DTO
    /// </summary>
    public static FinancialTransactionDto FromEntity(FinancialTransaction transaction)
    {
        if (transaction == null)
            return null;

        return new FinancialTransactionDto
        {
            Id = transaction.Id,
            TransactionNumber = transaction.TransactionNumber,
            TransactionDate = transaction.TransactionDate,
            EntryType = transaction.EntryType,
            TransactionType = transaction.TransactionType,
            DebitAccountId = transaction.DebitAccountId,
            CreditAccountId = transaction.CreditAccountId,
            Amount = transaction.Amount,
            Currency = transaction.Currency,
            ExchangeRate = transaction.ExchangeRate,
            BaseAmount = transaction.BaseAmount,
            Description = transaction.Description,
            Narration = transaction.Narration,
            ReferenceNumber = transaction.ReferenceNumber,
            DocumentType = transaction.DocumentType,
            BookingId = transaction.BookingId,
            PaymentId = transaction.PaymentId,
            FirstPartyUserId = transaction.FirstPartyUserId,
            SecondPartyUserId = transaction.SecondPartyUserId,
            PropertyId = transaction.PropertyId,
            UnitId = transaction.UnitId,
            Status = transaction.Status,
            PostingDate = transaction.PostingDate,
            IsPosted = transaction.IsPosted,
            IsReversed = transaction.IsReversed,
            ReverseTransactionId = transaction.ReverseTransactionId,
            FiscalYear = transaction.FiscalYear,
            FiscalPeriod = transaction.FiscalPeriod,
            JournalId = transaction.JournalId,
            BatchNumber = transaction.BatchNumber,
            Notes = transaction.Notes,
            Commission = transaction.Commission,
            CommissionPercentage = transaction.CommissionPercentage,
            Tax = transaction.Tax,
            TaxPercentage = transaction.TaxPercentage,
            Discount = transaction.Discount,
            DiscountPercentage = transaction.DiscountPercentage,
            NetAmount = transaction.NetAmount,
            CreatedAt = transaction.CreatedAt,
            CreatedBy = transaction.CreatedBy,
            UpdatedAt = transaction.UpdatedAt,
            UpdatedBy = transaction.UpdatedBy,
            IsAutomatic = transaction.IsAutomatic,
            AutomaticSource = transaction.AutomaticSource,
            DebitAccount = transaction.DebitAccount != null 
                ? SimpleAccountDto.FromEntity(transaction.DebitAccount) 
                : null,
            CreditAccount = transaction.CreditAccount != null 
                ? SimpleAccountDto.FromEntity(transaction.CreditAccount) 
                : null
        };
    }

    /// <summary>
    /// تحويل قائمة من Entities إلى DTOs
    /// Convert list of Entities to DTOs
    /// </summary>
    public static List<FinancialTransactionDto> FromEntities(IEnumerable<FinancialTransaction> transactions)
    {
        if (transactions == null)
            return new List<FinancialTransactionDto>();

        return transactions
            .Select(t => FromEntity(t))
            .OrderByDescending(t => t.TransactionDate)
            .ToList();
    }
}

/// <summary>
/// DTO مبسط للحساب بدون علاقات
/// Simple Account DTO without relationships
/// </summary>
public class SimpleAccountDto
{
    public Guid Id { get; set; }
    public string AccountNumber { get; set; }
    public string NameAr { get; set; }
    public string NameEn { get; set; }
    public AccountType AccountType { get; set; }
    public AccountNature NormalBalance { get; set; }

    public static SimpleAccountDto FromEntity(ChartOfAccount account)
    {
        if (account == null)
            return null;

        return new SimpleAccountDto
        {
            Id = account.Id,
            AccountNumber = account.AccountNumber,
            NameAr = account.NameAr,
            NameEn = account.NameEn,
            AccountType = account.AccountType,
            NormalBalance = account.NormalBalance
        };
    }
}
