using System;
using System.Collections.Generic;
using System.Linq;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Analytics.DTOs;

/// <summary>
/// DTO لدليل الحسابات - يمنع المراجع الدائرية
/// Chart of Accounts DTO - Prevents circular references
/// </summary>
public class ChartOfAccountDto
{
    public Guid Id { get; set; }
    public string AccountNumber { get; set; }
    public string NameAr { get; set; }
    public string NameEn { get; set; }
    public AccountType AccountType { get; set; }
    public AccountCategory Category { get; set; }
    public AccountNature NormalBalance { get; set; }
    public int Level { get; set; }
    public string Description { get; set; }
    public decimal Balance { get; set; }
    public string Currency { get; set; }
    public bool IsActive { get; set; }
    public bool IsSystemAccount { get; set; }
    public bool CanPost { get; set; }
    public Guid? ParentAccountId { get; set; }
    public Guid? UserId { get; set; }
    public Guid? PropertyId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    
    /// <summary>
    /// الحسابات الفرعية (بدون parentAccount لمنع المراجع الدائرية)
    /// Sub-accounts (without parentAccount to prevent circular references)
    /// </summary>
    public List<ChartOfAccountDto> SubAccounts { get; set; } = new List<ChartOfAccountDto>();

    /// <summary>
    /// تحويل من Entity إلى DTO
    /// Convert from Entity to DTO
    /// </summary>
    public static ChartOfAccountDto FromEntity(ChartOfAccount account, bool includeSubAccounts = true)
    {
        if (account == null)
            return null;

        var dto = new ChartOfAccountDto
        {
            Id = account.Id,
            AccountNumber = account.AccountNumber,
            NameAr = account.NameAr,
            NameEn = account.NameEn,
            AccountType = account.AccountType,
            Category = account.Category,
            NormalBalance = account.NormalBalance,
            Level = account.Level,
            Description = account.Description,
            Balance = account.Balance,
            Currency = account.Currency,
            IsActive = account.IsActive,
            IsSystemAccount = account.IsSystemAccount,
            CanPost = account.CanPost,
            ParentAccountId = account.ParentAccountId,
            UserId = account.UserId,
            PropertyId = account.PropertyId,
            CreatedAt = account.CreatedAt,
            UpdatedAt = account.UpdatedAt
        };

        // تضمين الحسابات الفرعية بشكل تكراري بدون المراجع العكسية
        // Include sub-accounts recursively without reverse references
        if (includeSubAccounts && account.SubAccounts != null && account.SubAccounts.Count > 0)
        {
            dto.SubAccounts = account.SubAccounts
                .Select(sub => FromEntity(sub, true))
                .OrderBy(s => s.AccountNumber)
                .ToList();
        }

        return dto;
    }

    /// <summary>
    /// تحويل قائمة من Entities إلى DTOs
    /// Convert list of Entities to DTOs
    /// </summary>
    public static List<ChartOfAccountDto> FromEntities(IEnumerable<ChartOfAccount> accounts, bool includeSubAccounts = true)
    {
        if (accounts == null)
            return new List<ChartOfAccountDto>();

        return accounts
            .Select(a => FromEntity(a, includeSubAccounts))
            .OrderBy(a => a.AccountNumber)
            .ToList();
    }
}
