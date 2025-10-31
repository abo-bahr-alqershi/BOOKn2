using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Infrastructure.Persistence.Repositories;

/// <summary>
/// واجهة مستودع دليل الحسابات
/// Chart of Accounts Repository Interface
/// </summary>
public interface IChartOfAccountRepository
{
    /// <summary>
    /// الحصول على جميع الحسابات كقائمة مسطحة
    /// Get a flat list of all accounts
    /// </summary>
    Task<List<ChartOfAccount>> GetAccountListAsync();

    /// <summary>
    /// الحصول على حساب بالمعرف
    /// Get account by id
    /// </summary>
    Task<ChartOfAccount> GetByIdAsync(Guid id);

    /// <summary>
    /// الحصول على حساب بالرقم
    /// Get account by number
    /// </summary>
    Task<ChartOfAccount> GetByAccountNumberAsync(string accountNumber);

    /// <summary>
    /// الحصول على الحسابات حسب النوع
    /// Get accounts by type
    /// </summary>
    Task<List<ChartOfAccount>> GetByAccountTypeAsync(AccountType accountType);

    /// <summary>
    /// الحصول على الحسابات الرئيسية
    /// Get main accounts
    /// </summary>
    Task<List<ChartOfAccount>> GetMainAccountsAsync();

    /// <summary>
    /// الحصول على الحسابات الفرعية
    /// Get sub-accounts
    /// </summary>
    Task<List<ChartOfAccount>> GetSubAccountsAsync(Guid parentAccountId);

    /// <summary>
    /// الحصول على الحسابات التي يمكن الترحيل إليها
    /// Get postable accounts
    /// </summary>
    Task<List<ChartOfAccount>> GetPostableAccountsAsync();

    /// <summary>
    /// الحصول على حساب المستخدم
    /// Get user account
    /// </summary>
    Task<ChartOfAccount> GetUserAccountAsync(Guid userId, AccountType accountType);

    /// <summary>
    /// الحصول على حساب العقار
    /// Get property account
    /// </summary>
    Task<ChartOfAccount> GetPropertyAccountAsync(Guid propertyId, AccountType accountType);

    /// <summary>
    /// إنشاء حساب للمستخدم
    /// Create account for user
    /// </summary>
    Task<ChartOfAccount> CreateUserAccountAsync(Guid userId, string userName, AccountType accountType);

    /// <summary>
    /// إنشاء حساب للعقار
    /// Create account for property
    /// </summary>
    Task<ChartOfAccount> CreatePropertyAccountAsync(Guid propertyId, string propertyName, AccountType accountType);

    /// <summary>
    /// تحديث رصيد الحساب
    /// Update account balance
    /// </summary>
    Task<bool> UpdateAccountBalanceAsync(Guid accountId, decimal amount, bool isDebit);

    /// <summary>
    /// البحث في دليل الحسابات
    /// Search chart of accounts
    /// </summary>
    Task<List<ChartOfAccount>> SearchAccountsAsync(string searchTerm);

    /// <summary>
    /// الحصول على شجرة الحسابات
    /// Get accounts tree
    /// </summary>
    Task<List<ChartOfAccount>> GetAccountsTreeAsync();

    /// <summary>
    /// التحقق من وجود حساب برقم معين
    /// Check if account number exists
    /// </summary>
    Task<bool> AccountNumberExistsAsync(string accountNumber);

    /// <summary>
    /// توليد رقم حساب جديد
    /// Generate new account number
    /// </summary>
    /// <param name="accountType"></param>
    /// <param name="isUserAccount"></param>
    /// <returns></returns>
    Task<string> GenerateAccountNumberAsync(AccountType accountType, bool isUserAccount);
    
    /// <summary>
    /// الحصول على حساب النظام
    /// Get system account
    /// </summary>
    Task<ChartOfAccount> GetSystemAccountAsync(string accountName);

    /// <summary>
    /// إنشاء حساب عام وإرجاعه
    /// Create a generic account and persist it
    /// </summary>
    Task<ChartOfAccount> CreateAsync(ChartOfAccount account, System.Threading.CancellationToken cancellationToken = default);

    /// <summary>
    /// إضافة حساب إلى قاعدة البيانات (يحفظ التغييرات)
    /// Add an account to the database (persists changes)
    /// </summary>
    Task<ChartOfAccount> AddAsync(ChartOfAccount account, System.Threading.CancellationToken cancellationToken = default);
}
