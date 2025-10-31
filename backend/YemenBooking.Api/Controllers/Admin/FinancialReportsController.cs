using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Caching.Memory;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Accounting.Services;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Entities;
using YemenBooking.Application.Infrastructure.Persistence.Repositories;
using YemenBooking.Application.Features.Analytics.DTOs;

namespace YemenBooking.Api.Controllers.Admin;

/// <summary>
/// واجهة برمجة التطبيقات للتقارير المالية والمحاسبية
/// Financial Reports API Controller
/// </summary>
[ApiController]
[Route("api/admin/[controller]")]
[Authorize(Roles = "Admin")]
public class FinancialReportsController : ControllerBase
{
    private readonly ILogger<FinancialReportsController> _logger;
    private readonly IFinancialAccountingService _financialAccountingService;
    private readonly IFinancialTransactionRepository _transactionRepository;
    private readonly IChartOfAccountRepository _accountRepository;
    private readonly ICurrentUserService _currentUserService;
    private readonly IMemoryCache _cache;

    public FinancialReportsController(
        ILogger<FinancialReportsController> logger,
        IFinancialAccountingService financialAccountingService,
        IFinancialTransactionRepository transactionRepository,
        IChartOfAccountRepository accountRepository,
        ICurrentUserService currentUserService,
        IMemoryCache cache)
    {
        _logger = logger;
        _financialAccountingService = financialAccountingService;
        _transactionRepository = transactionRepository;
        _accountRepository = accountRepository;
        _currentUserService = currentUserService;
        _cache = cache;
    }

    /// <summary>
    /// الحصول على التقرير المالي لفترة معينة
    /// Get financial report for a specific period
    /// </summary>
    [HttpGet("report")]
    public async Task<IActionResult> GetFinancialReport(
        [FromQuery] DateTime startDate,
        [FromQuery] DateTime endDate)
    {
        try
        {
            // تحويل DateTime إلى UTC للتوافق مع PostgreSQL
            startDate = DateTime.SpecifyKind(startDate, DateTimeKind.Utc);
            endDate = DateTime.SpecifyKind(endDate, DateTimeKind.Utc);
            
            var report = await _financialAccountingService.GetFinancialReportAsync(startDate, endDate);
            return Ok(new
            {
                success = true,
                data = report
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting financial report");
            return StatusCode(500, new { success = false, message = "خطأ في الحصول على التقرير المالي" });
        }
    }

    /// <summary>
    /// الحصول على دليل الحسابات
    /// Get chart of accounts
    /// </summary>
    [HttpGet("chart-of-accounts")]
    public async Task<IActionResult> GetChartOfAccounts([FromQuery] AccountType? type = null)
    {
        try
        {
            // مفتاح الذاكرة المؤقتة
            string cacheKey = $"chart_of_accounts_{type?.ToString() ?? "all"}_{DateTime.UtcNow:yyyyMMddHH}";
            
            // محاولة الحصول على البيانات من الذاكرة المؤقتة
            if (_cache.TryGetValue<List<ChartOfAccountDto>>(cacheKey, out var cachedAccounts))
            {
                _logger.LogInformation("استرجاع دليل الحسابات من الذاكرة المؤقتة");
                return Ok(new
                {
                    success = true,
                    data = cachedAccounts,
                    cached = true
                });
            }

            List<ChartOfAccount> accounts;
            
            if (type.HasValue)
            {
                // فلترة حسب النوع
                accounts = await _accountRepository.GetByAccountTypeAsync(type.Value);
            }
            else
            {
                // الحصول على الشجرة الكاملة
                accounts = await _accountRepository.GetAccountsTreeAsync();
            }
            
            // جمع جميع معرفات الحسابات (الرئيسية والفرعية)
            var allAccountIds = new List<Guid>();
            foreach (var account in accounts)
            {
                allAccountIds.Add(account.Id);
                if (account.SubAccounts?.Any() == true)
                {
                    allAccountIds.AddRange(account.SubAccounts.Select(s => s.Id));
                }
            }

            // حساب جميع الأرصدة في استعلام واحد محسن
            var balances = await _transactionRepository.GetAccountsBalancesAsync(allAccountIds, DateTime.UtcNow);
            
            // تطبيق الأرصدة على الحسابات بشكل متوازي
            Parallel.ForEach(accounts, account =>
            {
                account.Balance = balances.ContainsKey(account.Id) ? balances[account.Id] : 0;
                
                if (account.SubAccounts?.Any() == true)
                {
                    Parallel.ForEach(account.SubAccounts, subAccount =>
                    {
                        subAccount.Balance = balances.ContainsKey(subAccount.Id) ? balances[subAccount.Id] : 0;
                    });
                }
            });
            
            // تحويل إلى DTO لمنع المراجع الدائرية
            // Convert to DTO to prevent circular references
            var accountDtos = ChartOfAccountDto.FromEntities(accounts, includeSubAccounts: !type.HasValue);
            
            // حفظ في الذاكرة المؤقتة لمدة 5 دقائق
            var cacheOptions = new MemoryCacheEntryOptions()
                .SetSlidingExpiration(TimeSpan.FromMinutes(5))
                .SetAbsoluteExpiration(TimeSpan.FromMinutes(10))
                .SetPriority(CacheItemPriority.High);
                
            _cache.Set(cacheKey, accountDtos, cacheOptions);
            _logger.LogInformation("تم حفظ دليل الحسابات في الذاكرة المؤقتة");
            
            return Ok(new
            {
                success = true,
                data = accountDtos,
                cached = false
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting chart of accounts");
            return StatusCode(500, new { success = false, message = "خطأ في الحصول على دليل الحسابات" });
        }
    }

    /// <summary>
    /// الحصول على الحسابات حسب النوع (مسار بديل للتوافق مع الواجهة الأمامية)
    /// Get accounts by type (alternative route for frontend compatibility)
    /// </summary>
    [HttpGet("accounts")]
    public async Task<IActionResult> GetAccountsByType([FromQuery] AccountType? type = null)
    {
        return await GetChartOfAccounts(type);
    }

    /// <summary>
    /// البحث في دليل الحسابات
    /// Search chart of accounts
    /// </summary>
    [HttpGet("accounts/search")]
    public async Task<IActionResult> SearchAccounts([FromQuery] string query)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(query))
            {
                return BadRequest(new { success = false, message = "يجب إدخال نص البحث" });
            }

            var accounts = await _accountRepository.SearchAccountsAsync(query);
            var accountDtos = ChartOfAccountDto.FromEntities(accounts, includeSubAccounts: false);
            
            return Ok(new
            {
                success = true,
                data = accountDtos
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error searching accounts");
            return StatusCode(500, new { success = false, message = "خطأ في البحث عن الحسابات" });
        }
    }

    /// <summary>
    /// الحصول على القيود المحاسبية لفترة معينة
    /// Get financial transactions for a specific period
    /// </summary>
    [HttpGet("transactions")]
    public async Task<IActionResult> GetTransactions(
        [FromQuery] DateTime startDate,
        [FromQuery] DateTime endDate,
        [FromQuery] TransactionStatus? status = null,
        [FromQuery] TransactionType? type = null,
        [FromQuery] int? limit = null)
    {
        try
        {
            // تحويل DateTime إلى UTC للتوافق مع PostgreSQL
            startDate = DateTime.SpecifyKind(startDate, DateTimeKind.Utc);
            endDate = DateTime.SpecifyKind(endDate, DateTimeKind.Utc);
            
            var transactions = await _transactionRepository.GetByPeriodAsync(
                startDate,
                endDate,
                status,
                type,
                limit);

            // تحويل إلى DTO لمنع المراجع الدائرية
            // Convert to DTO to prevent circular references
            var transactionDtos = FinancialTransactionDto.FromEntities(transactions);

            return Ok(new
            {
                success = true,
                data = transactionDtos,
                count = transactionDtos.Count
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting transactions");
            return StatusCode(500, new { success = false, message = "خطأ في الحصول على القيود المحاسبية" });
        }
    }

    /// <summary>
    /// الحصول على القيود المحاسبية للحجز
    /// Get financial transactions for a booking
    /// </summary>
    [HttpGet("transactions/booking/{bookingId}")]
    public async Task<IActionResult> GetBookingTransactions(Guid bookingId)
    {
        try
        {
            var transactions = await _transactionRepository.GetByBookingIdAsync(bookingId);
            var transactionDtos = FinancialTransactionDto.FromEntities(transactions);
            
            return Ok(new
            {
                success = true,
                data = transactionDtos,
                count = transactionDtos.Count
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting booking transactions");
            return StatusCode(500, new { success = false, message = "خطأ في الحصول على قيود الحجز" });
        }
    }

    /// <summary>
    /// الحصول على القيود المحاسبية للعقار
    /// Get financial transactions for a property
    /// </summary>
    [HttpGet("transactions/property/{propertyId}")]
    public async Task<IActionResult> GetPropertyTransactions(Guid propertyId)
    {
        try
        {
            var transactions = await _transactionRepository.GetByPropertyIdAsync(propertyId);
            var transactionDtos = FinancialTransactionDto.FromEntities(transactions);
            
            return Ok(new
            {
                success = true,
                data = transactionDtos,
                count = transactionDtos.Count
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting property transactions");
            return StatusCode(500, new { success = false, message = "خطأ في الحصول على قيود العقار" });
        }
    }

    /// <summary>
    /// الحصول على القيود المحاسبية للمستخدم
    /// Get financial transactions for a user
    /// </summary>
    [HttpGet("transactions/user/{userId}")]
    public async Task<IActionResult> GetUserTransactions(Guid userId)
    {
        try
        {
            var transactions = await _transactionRepository.GetByUserIdAsync(userId);
            var transactionDtos = FinancialTransactionDto.FromEntities(transactions);
            
            return Ok(new
            {
                success = true,
                data = transactionDtos,
                count = transactionDtos.Count
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting user transactions");
            return StatusCode(500, new { success = false, message = "خطأ في الحصول على قيود المستخدم" });
        }
    }

    /// <summary>
    /// إلغاء الذاكرة المؤقتة لدليل الحسابات
    /// Clear chart of accounts cache
    /// </summary>
    [HttpPost("chart-of-accounts/clear-cache")]
    public IActionResult ClearChartOfAccountsCache()
    {
        try
        {
            // حذف جميع مفاتيح دليل الحسابات من الذاكرة المؤقتة
            _cache.Remove("chart_of_accounts_all");
            foreach (AccountType accountType in Enum.GetValues(typeof(AccountType)))
            {
                _cache.Remove($"chart_of_accounts_{accountType}");
            }
            
            _logger.LogInformation("تم حذف الذاكرة المؤقتة لدليل الحسابات");
            
            return Ok(new
            {
                success = true,
                message = "تم حذف الذاكرة المؤقتة بنجاح"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error clearing cache");
            return StatusCode(500, new { success = false, message = "خطأ في حذف الذاكرة المؤقتة" });
        }
    }

    /// <summary>
    /// الحصول على كشف حساب
    /// Get account statement
    /// </summary>
    [HttpGet("account-statement/{accountId}")]
    public async Task<IActionResult> GetAccountStatement(
        Guid accountId,
        [FromQuery] DateTime startDate,
        [FromQuery] DateTime endDate)
    {
        try
        {
            var statement = await _transactionRepository.GetAccountStatementAsync(accountId, startDate, endDate);
            var balance = await _transactionRepository.GetAccountBalanceAtDateAsync(accountId, endDate);
            
            return Ok(new
            {
                success = true,
                data = new
                {
                    accountId,
                    startDate,
                    endDate,
                    transactions = statement,
                    closingBalance = balance,
                    transactionCount = statement.Count
                }
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting account statement");
            return StatusCode(500, new { success = false, message = "خطأ في الحصول على كشف الحساب" });
        }
    }

    /// <summary>
    /// البحث في القيود المحاسبية
    /// Search financial transactions
    /// </summary>
    [HttpGet("transactions/search")]
    public async Task<IActionResult> SearchTransactions(
        [FromQuery] string searchTerm,
        [FromQuery] TransactionType? type = null,
        [FromQuery] TransactionStatus? status = null,
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null)
    {
        try
        {
            var transactions = await _transactionRepository.SearchTransactionsAsync(
                searchTerm,
                type,
                status,
                startDate,
                endDate);

            var transactionDtos = FinancialTransactionDto.FromEntities(transactions);

            return Ok(new
            {
                success = true,
                data = transactionDtos,
                count = transactionDtos.Count
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error searching transactions");
            return StatusCode(500, new { success = false, message = "خطأ في البحث عن القيود" });
        }
    }

    /// <summary>
    /// ترحيل القيود المعلقة
    /// Post pending transactions
    /// </summary>
    [HttpPost("post-pending")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> PostPendingTransactions()
    {
        try
        {
            var pendingTransactions = await _transactionRepository.GetPendingForPostingAsync();
            var postedCount = 0;
            var failedCount = 0;

            foreach (var transaction in pendingTransactions)
            {
                try
                {
                    await _transactionRepository.PostTransactionAsync(transaction.Id);
                    postedCount++;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to post transaction {TransactionId}", transaction.Id);
                    failedCount++;
                }
            }

            return Ok(new
            {
                success = true,
                message = $"تم ترحيل {postedCount} قيد بنجاح، فشل {failedCount} قيد",
                data = new
                {
                    posted = postedCount,
                    failed = failedCount,
                    total = pendingTransactions.Count
                }
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error posting pending transactions");
            return StatusCode(500, new { success = false, message = "خطأ في ترحيل القيود المعلقة" });
        }
    }

    /// <summary>
    /// عكس قيد محاسبي
    /// Reverse a financial transaction
    /// </summary>
    [HttpPost("transactions/{transactionId}/reverse")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> ReverseTransaction(
        Guid transactionId,
        [FromBody] ReverseTransactionRequest request)
    {
        try
        {
            // Get current user ID from claims
            var userIdClaim = User.FindFirst("UserId")?.Value;
            if (string.IsNullOrEmpty(userIdClaim))
            {
                return Unauthorized(new { success = false, message = "معرف المستخدم غير موجود" });
            }

            var userId = Guid.Parse(userIdClaim);
            var reverseTransaction = await _transactionRepository.ReverseTransactionAsync(
                transactionId,
                request.Reason,
                userId);

            if (reverseTransaction == null)
            {
                return BadRequest(new { success = false, message = "لا يمكن عكس هذا القيد" });
            }

            return Ok(new
            {
                success = true,
                message = "تم عكس القيد بنجاح",
                data = reverseTransaction
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error reversing transaction");
            return StatusCode(500, new { success = false, message = "خطأ في عكس القيد" });
        }
    }

    /// <summary>
    /// الحصول على ملخص القيود حسب النوع
    /// Get transaction summary by type
    /// </summary>
    [HttpGet("summary-by-type")]
    public async Task<IActionResult> GetTransactionSummaryByType(
        [FromQuery] DateTime startDate,
        [FromQuery] DateTime endDate)
    {
        try
        {
            var summary = await _transactionRepository.GetTransactionSummaryByTypeAsync(startDate, endDate);
            
            return Ok(new
            {
                success = true,
                data = summary,
                period = new { startDate, endDate }
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting transaction summary");
            return StatusCode(500, new { success = false, message = "خطأ في الحصول على ملخص القيود" });
        }
    }

    /// <summary>
    /// الحصول على رصيد الحساب
    /// Get account balance
    /// </summary>
    [HttpGet("account-balance/{accountId}")]
    public async Task<IActionResult> GetAccountBalance(
        Guid accountId,
        [FromQuery] DateTime? atDate = null)
    {
        try
        {
            var date = atDate ?? DateTime.UtcNow;
            var balance = await _transactionRepository.GetAccountBalanceAtDateAsync(accountId, date);
            var account = await _accountRepository.GetByIdAsync(accountId);
            
            return Ok(new
            {
                success = true,
                data = new
                {
                    accountId,
                    accountNumber = account?.AccountNumber,
                    accountName = account?.NameAr,
                    balance,
                    currency = account?.Currency ?? "YER",
                    asOfDate = date
                }
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting account balance");
            return StatusCode(500, new { success = false, message = "خطأ في الحصول على رصيد الحساب" });
        }
    }

    /// <summary>
    /// الحصول على بيانات مخطط الإيرادات
    /// Get revenue chart data
    /// </summary>
    [HttpGet("charts/revenue")]
    public async Task<IActionResult> GetRevenueChart(
        [FromQuery] DateTime startDate,
        [FromQuery] DateTime endDate)
    {
        try
        {
            var chartData = await _financialAccountingService.GetRevenueChartDataAsync(startDate, endDate);
            return Ok(new
            {
                success = true,
                data = chartData
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting revenue chart data");
            return StatusCode(500, new { success = false, message = "خطأ في الحصول على بيانات مخطط الإيرادات" });
        }
    }

    /// <summary>
    /// الحصول على بيانات مخطط المصروفات
    /// Get expense chart data
    /// </summary>
    [HttpGet("charts/expenses")]
    public async Task<IActionResult> GetExpenseChart(
        [FromQuery] DateTime startDate,
        [FromQuery] DateTime endDate)
    {
        try
        {
            var chartData = await _financialAccountingService.GetExpenseChartDataAsync(startDate, endDate);
            return Ok(new
            {
                success = true,
                data = chartData
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting expense chart data");
            return StatusCode(500, new { success = false, message = "خطأ في الحصول على بيانات مخطط المصروفات" });
        }
    }

    /// <summary>
    /// الحصول على بيانات التدفق النقدي
    /// Get cash flow chart data
    /// </summary>
    [HttpGet("charts/cash-flow")]
    public async Task<IActionResult> GetCashFlowChart(
        [FromQuery] DateTime startDate,
        [FromQuery] DateTime endDate)
    {
        try
        {
            var chartData = await _financialAccountingService.GetCashFlowChartDataAsync(startDate, endDate);
            return Ok(new
            {
                success = true,
                data = chartData
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting cash flow chart data");
            return StatusCode(500, new { success = false, message = "خطأ في الحصول على بيانات التدفق النقدي" });
        }
    }

    /// <summary>
    /// الحصول على الملخص المالي الشامل
    /// Get comprehensive financial summary
    /// </summary>
    [HttpGet("financial-summary")]
    public async Task<IActionResult> GetFinancialSummary()
    {
        try
        {
            var cacheKey = $"financial_summary_{DateTime.UtcNow:yyyyMMddHHmm}"; // change per minute
            if (_cache.TryGetValue(cacheKey, out FinancialSummaryDto cachedSummary))
            {
                return Ok(new
                {
                    success = true,
                    data = cachedSummary,
                    cached = true
                });
            }

            var summary = await _financialAccountingService.GetFinancialSummaryAsync();

            var cacheOptions = new MemoryCacheEntryOptions()
                .SetSlidingExpiration(TimeSpan.FromMinutes(1))
                .SetAbsoluteExpiration(TimeSpan.FromMinutes(2))
                .SetPriority(CacheItemPriority.High);
            _cache.Set(cacheKey, summary, cacheOptions);

            return Ok(new
            {
                success = true,
                data = summary,
                cached = false
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting financial summary");
            return StatusCode(500, new { success = false, message = "خطأ في الحصول على الملخص المالي" });
        }
    }
}

/// <summary>
/// طلب عكس القيد
/// Reverse transaction request
/// </summary>
public class ReverseTransactionRequest
{
    /// <summary>
    /// سبب العكس
    /// Reversal reason
    /// </summary>
    public string Reason { get; set; }
}
