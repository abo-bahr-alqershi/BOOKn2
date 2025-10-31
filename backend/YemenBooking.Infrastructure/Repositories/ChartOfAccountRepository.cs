using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Threading;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Core.Entities;
using YemenBooking.Infrastructure.Data.Context;
using YemenBooking.Application.Infrastructure.Persistence.Repositories;

namespace YemenBooking.Infrastructure.Repositories;

/// <summary>
/// مستودع دليل الحسابات
/// Chart of Accounts Repository
/// </summary>
public class ChartOfAccountRepository : BaseRepository<ChartOfAccount>, IChartOfAccountRepository
{
    private readonly YemenBookingDbContext _context;

    public ChartOfAccountRepository(YemenBookingDbContext context) : base(context)
    {
        _context = context;
    }

    /// <summary>
    /// الحصول على جميع الحسابات كقائمة مسطحة
    /// Get a flat list of all accounts
    /// </summary>
    public async Task<List<ChartOfAccount>> GetAccountListAsync()
    {
        return await _context.ChartOfAccounts
            .AsNoTracking()
            .OrderBy(a => a.AccountNumber)
            .ToListAsync();
    }

    /// <summary>
    /// الحصول على حساب بالمعرف
    /// Get account by id
    /// </summary>
    public async Task<ChartOfAccount> GetByIdAsync(Guid id)
    {
        return await _context.ChartOfAccounts
            .FirstOrDefaultAsync(a => a.Id == id);
    }

    /// <summary>
    /// الحصول على حساب بالرقم
    /// Get account by number
    /// </summary>
    public async Task<ChartOfAccount> GetByAccountNumberAsync(string accountNumber)
    {
        return await _context.ChartOfAccounts
            .Include(a => a.ParentAccount)
            .Include(a => a.SubAccounts)
            .FirstOrDefaultAsync(a => a.AccountNumber == accountNumber);
    }

    /// <summary>
    /// الحصول على الحسابات حسب النوع
    /// Get accounts by type
    /// </summary>
    public async Task<List<ChartOfAccount>> GetByAccountTypeAsync(AccountType accountType)
    {
        return await _context.ChartOfAccounts
            .Include(a => a.ParentAccount)
            .Where(a => a.AccountType == accountType && a.IsActive)
            .OrderBy(a => a.AccountNumber)
            .ToListAsync();
    }

    /// <summary>
    /// الحصول على الحسابات الرئيسية
    /// Get main accounts
    /// </summary>
    public async Task<List<ChartOfAccount>> GetMainAccountsAsync()
    {
        return await _context.ChartOfAccounts
            .Include(a => a.SubAccounts)
            .Where(a => a.Category == AccountCategory.Main && a.IsActive)
            .OrderBy(a => a.AccountNumber)
            .ToListAsync();
    }

    /// <summary>
    /// الحصول على الحسابات الفرعية لحساب رئيسي
    /// Get sub-accounts of a main account
    /// </summary>
    public async Task<List<ChartOfAccount>> GetSubAccountsAsync(Guid parentAccountId)
    {
        return await _context.ChartOfAccounts
            .Where(a => a.ParentAccountId == parentAccountId && a.IsActive)
            .OrderBy(a => a.AccountNumber)
            .ToListAsync();
    }

    /// <summary>
    /// الحصول على الحسابات التي يمكن الترحيل إليها
    /// Get postable accounts
    /// </summary>
    public async Task<List<ChartOfAccount>> GetPostableAccountsAsync()
    {
        return await _context.ChartOfAccounts
            .Where(a => a.CanPost && a.IsActive)
            .OrderBy(a => a.AccountNumber)
            .ToListAsync();
    }

    /// <summary>
    /// الحصول على حساب المستخدم
    /// Get user account
    /// </summary>
    public async Task<ChartOfAccount> GetUserAccountAsync(Guid userId, AccountType accountType)
    {
        return await _context.ChartOfAccounts
            .FirstOrDefaultAsync(a => a.UserId == userId && a.AccountType == accountType && a.IsActive);
    }

    /// <summary>
    /// الحصول على حساب العقار
    /// Get property account
    /// </summary>
    public async Task<ChartOfAccount> GetPropertyAccountAsync(Guid propertyId, AccountType accountType)
    {
        return await _context.ChartOfAccounts
            .FirstOrDefaultAsync(a => a.PropertyId == propertyId && a.AccountType == accountType && a.IsActive);
    }

    /// <summary>
    /// إنشاء حساب للمستخدم
    /// Create account for user
    /// </summary>
    public async Task<ChartOfAccount> CreateUserAccountAsync(Guid userId, string userName, AccountType accountType)
    {
        var accountNumber = await GenerateAccountNumberAsync(accountType, true);
        
        var account = new ChartOfAccount
        {
            AccountNumber = accountNumber,
            NameAr = $"حساب {GetAccountTypeNameAr(accountType)} - {userName}",
            NameEn = $"{GetAccountTypeNameEn(accountType)} Account - {userName}",
            AccountType = accountType,
            Category = AccountCategory.Sub,
            NormalBalance = GetAccountNormalBalance(accountType),
            Level = 3,
            Description = $"حساب شخصي للمستخدم {userName}",
            Balance = 0,
            Currency = "YER",
            IsActive = true,
            IsSystemAccount = false,
            CanPost = true,
            UserId = userId,
            CreatedAt = DateTime.UtcNow,
            ParentAccountId = await GetParentAccountIdForType(accountType)
        };

        await _context.ChartOfAccounts.AddAsync(account);
        await _context.SaveChangesAsync();

        return account;
    }

    /// <summary>
    /// إنشاء حساب للعقار
    /// Create account for property
    /// </summary>
    public async Task<ChartOfAccount> CreatePropertyAccountAsync(Guid propertyId, string propertyName, AccountType accountType)
    {
        var accountNumber = await GenerateAccountNumberAsync(accountType, false);
        
        var account = new ChartOfAccount
        {
            AccountNumber = accountNumber,
            NameAr = $"حساب {GetAccountTypeNameAr(accountType)} - {propertyName}",
            NameEn = $"{GetAccountTypeNameEn(accountType)} Account - {propertyName}",
            AccountType = accountType,
            Category = AccountCategory.Sub,
            NormalBalance = GetAccountNormalBalance(accountType),
            Level = 3,
            Description = $"حساب العقار {propertyName}",
            Balance = 0,
            Currency = "YER",
            IsActive = true,
            IsSystemAccount = false,
            CanPost = true,
            PropertyId = propertyId,
            CreatedAt = DateTime.UtcNow,
            ParentAccountId = await GetParentAccountIdForType(accountType)
        };

        await _context.ChartOfAccounts.AddAsync(account);
        await _context.SaveChangesAsync();

        return account;
    }

    /// <summary>
    /// إنشاء حساب عام وإرجاعه (يحفظ التغييرات)
    /// Create a generic account and persist it
    /// </summary>
    public async Task<ChartOfAccount> CreateAsync(ChartOfAccount account, CancellationToken cancellationToken = default)
    {
        await _context.ChartOfAccounts.AddAsync(account, cancellationToken);
        await _context.SaveChangesAsync(cancellationToken);
        return account;
    }

    /// <summary>
    /// إضافة حساب إلى قاعدة البيانات (يحفظ التغييرات)
    /// Add an account to the database (persists changes)
    /// </summary>
    public async Task<ChartOfAccount> AddAsync(ChartOfAccount account, CancellationToken cancellationToken = default)
    {
        await _context.ChartOfAccounts.AddAsync(account, cancellationToken);
        await _context.SaveChangesAsync(cancellationToken);
        return account;
    }

    /// <summary>
    /// تحديث رصيد الحساب
    /// Update account balance
    /// </summary>
    public async Task<bool> UpdateAccountBalanceAsync(Guid accountId, decimal amount, bool isDebit)
    {
        var account = await _context.ChartOfAccounts.FindAsync(accountId);
        if (account == null)
            return false;

        if ((account.NormalBalance == AccountNature.Debit && isDebit) ||
            (account.NormalBalance == AccountNature.Credit && !isDebit))
        {
            account.Balance += amount;
        }
        else
        {
            account.Balance -= amount;
        }

        account.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        return true;
    }

    /// <summary>
    /// البحث في دليل الحسابات
    /// Search chart of accounts
    /// </summary>
    public async Task<List<ChartOfAccount>> SearchAccountsAsync(string searchTerm)
    {
        return await _context.ChartOfAccounts
            .Include(a => a.ParentAccount)
            .Where(a => a.IsActive && (
                a.AccountNumber.Contains(searchTerm) ||
                a.NameAr.Contains(searchTerm) ||
                a.NameEn.Contains(searchTerm) ||
                a.Description.Contains(searchTerm)))
            .OrderBy(a => a.AccountNumber)
            .Take(50)
            .ToListAsync();
    }

    /// <summary>
    /// الحصول على شجرة الحسابات
    /// Get accounts tree
    /// </summary>
    public async Task<List<ChartOfAccount>> GetAccountsTreeAsync()
    {
        // استخدام AsNoTracking لتحسين الأداء ومنع تتبع EF للكيانات
        // Use AsNoTracking to improve performance and prevent EF entity tracking
        return await _context.ChartOfAccounts
            .AsNoTracking()
            .Include(a => a.SubAccounts)
                .ThenInclude(s => s.SubAccounts)
                    .ThenInclude(s => s.SubAccounts)
            .Where(a => a.ParentAccountId == null && a.IsActive)
            .OrderBy(a => a.AccountNumber)
            .ToListAsync();
    }

    /// <summary>
    /// التحقق من وجود حساب برقم معين
    /// Check if account number exists
    /// </summary>
    public async Task<bool> AccountNumberExistsAsync(string accountNumber)
    {
        return await _context.ChartOfAccounts
            .AnyAsync(a => a.AccountNumber == accountNumber);
    }

    /// <summary>
    /// الحصول على حساب النظام بالاسم
    /// Get system account by name
    /// </summary>
    public async Task<ChartOfAccount> GetSystemAccountAsync(string accountName)
    {
        return await _context.ChartOfAccounts
            .FirstOrDefaultAsync(a => a.IsSystemAccount && 
                (a.NameEn == accountName || a.NameAr == accountName));
    }

    // Helper methods

    public async Task<string> GenerateAccountNumberAsync(AccountType accountType, bool isUserAccount)
    {
        var prefix = accountType switch
        {
            AccountType.Assets => "1",
            AccountType.Liabilities => "2",
            AccountType.Equity => "3",
            AccountType.Revenue => "4",
            AccountType.Expenses => "5",
            _ => "9"
        };

        var subPrefix = isUserAccount ? "1" : "2"; // 1 للمستخدمين، 2 للعقارات

        var lastAccount = await _context.ChartOfAccounts
            .Where(a => a.AccountNumber.StartsWith($"{prefix}{subPrefix}"))
            .OrderByDescending(a => a.AccountNumber)
            .FirstOrDefaultAsync();

        if (lastAccount == null)
        {
            return $"{prefix}{subPrefix}001";
        }

        var lastNumber = int.Parse(lastAccount.AccountNumber.Substring(2));
        return $"{prefix}{subPrefix}{(lastNumber + 1):D3}";
    }

    private async Task<Guid?> GetParentAccountIdForType(AccountType accountType)
    {
        var parentAccountName = accountType switch
        {
            AccountType.Assets => "الأصول المتداولة",
            AccountType.Liabilities => "الالتزامات المتداولة",
            AccountType.Equity => "حقوق الملكية",
            AccountType.Revenue => "الإيرادات التشغيلية",
            AccountType.Expenses => "المصروفات التشغيلية",
            _ => null
        };

        if (parentAccountName == null)
            return null;

        var parentAccount = await _context.ChartOfAccounts
            .FirstOrDefaultAsync(a => a.NameAr == parentAccountName);

        return parentAccount?.Id;
    }

    private string GetAccountTypeNameAr(AccountType accountType) => accountType switch
    {
        AccountType.Assets => "أصول",
        AccountType.Liabilities => "التزامات",
        AccountType.Equity => "حقوق ملكية",
        AccountType.Revenue => "إيرادات",
        AccountType.Expenses => "مصروفات",
        _ => "عام"
    };

    private string GetAccountTypeNameEn(AccountType accountType) => accountType switch
    {
        AccountType.Assets => "Assets",
        AccountType.Liabilities => "Liabilities",
        AccountType.Equity => "Equity",
        AccountType.Revenue => "Revenue",
        AccountType.Expenses => "Expenses",
        _ => "General"
    };

    private AccountNature GetAccountNormalBalance(AccountType accountType) => accountType switch
    {
        AccountType.Assets => AccountNature.Debit,
        AccountType.Expenses => AccountNature.Debit,
        AccountType.Liabilities => AccountNature.Credit,
        AccountType.Equity => AccountNature.Credit,
        AccountType.Revenue => AccountNature.Credit,
        _ => AccountNature.Debit
    };
}
