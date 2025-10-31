using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Accounting;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Core.Interfaces;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Persistence.Repositories;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Accounting.Services;

namespace YemenBooking.Application.Features.Accounting.Commands.Setup
{
    /// <summary>
    /// معالج أمر التحقق من صحة الإعدادات المحاسبية
    /// Validate financial setup command handler
    /// </summary>
    public class ValidateFinancialSetupCommandHandler : IRequestHandler<ValidateFinancialSetupCommand, ResultDto<FinancialSetupValidationResult>>
    {
        private readonly IUserRepository _userRepository;
        private readonly IPropertyRepository _propertyRepository;
        private readonly IChartOfAccountRepository _accountRepository;
        private readonly IFinancialAccountingService _financialAccountingService;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<ValidateFinancialSetupCommandHandler> _logger;

        public ValidateFinancialSetupCommandHandler(
            IUserRepository userRepository,
            IPropertyRepository propertyRepository,
            IChartOfAccountRepository accountRepository,
            IFinancialAccountingService financialAccountingService,
            ICurrentUserService currentUserService,
            ILogger<ValidateFinancialSetupCommandHandler> logger)
        {
            _userRepository = userRepository;
            _propertyRepository = propertyRepository;
            _accountRepository = accountRepository;
            _financialAccountingService = financialAccountingService;
            _currentUserService = currentUserService;
            _logger = logger;
        }

        public async Task<ResultDto<FinancialSetupValidationResult>> Handle(
            ValidateFinancialSetupCommand request, 
            CancellationToken cancellationToken)
        {
            try
            {
                _logger.LogInformation("بدء التحقق من صحة الإعدادات المحاسبية");

                // التحقق من الصلاحيات
                if (_currentUserService.Role != "Admin" && _currentUserService.Role != "Accountant")
                {
                    return ResultDto<FinancialSetupValidationResult>.Failed(
                        "ليس لديك الصلاحية للتحقق من الإعدادات المحاسبية");
                }

                var result = new FinancialSetupValidationResult
                {
                    IsValid = true,
                    Issues = new List<ValidationIssue>(),
                    Summary = new AccountsSummary()
                };

                // جلب جميع البيانات المطلوبة
                var allUsers = await _userRepository.GetAllAsync(cancellationToken);
                var allAccounts = await _accountRepository.GetAccountListAsync();
                var properties = await _propertyRepository.GetAllAsync(cancellationToken);

                // التحقق من حسابات العملاء
                if (request.CheckCustomerAccounts)
                {
                    await ValidateCustomerAccountsAsync(allUsers, allAccounts, result, request.AutoFix, cancellationToken);
                }

                // التحقق من حسابات الملاك
                if (request.CheckOwnerAccounts)
                {
                    await ValidateOwnerAccountsAsync(allUsers, properties, allAccounts, result, request.AutoFix, cancellationToken);
                }

                // التحقق من حسابات النظام
                if (request.CheckSystemAccounts)
                {
                    await ValidateSystemAccountsAsync(allAccounts, result, cancellationToken);
                }

                // تحديث الملخص
                result.IssuesFound = result.Issues.Count;
                result.IssuesFixed = result.Issues.Count(i => i.IsFixed);
                result.IsValid = result.IssuesFound == 0 || result.IssuesFound == result.IssuesFixed;

                _logger.LogInformation(
                    "انتهى التحقق من الإعدادات المحاسبية. المشاكل المكتشفة: {IssuesFound}, المصححة: {IssuesFixed}",
                    result.IssuesFound, result.IssuesFixed);

                return ResultDto<FinancialSetupValidationResult>.Succeeded(result, 
                    result.IsValid 
                        ? "الإعدادات المحاسبية صحيحة" 
                        : $"تم اكتشاف {result.IssuesFound} مشكلة");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في التحقق من الإعدادات المحاسبية");
                return ResultDto<FinancialSetupValidationResult>.Failed(
                    "حدث خطأ أثناء التحقق من الإعدادات المحاسبية");
            }
        }

        private async Task ValidateCustomerAccountsAsync(
            IEnumerable<User> users, 
            IEnumerable<ChartOfAccount> accounts,
            FinancialSetupValidationResult result,
            bool autoFix,
            CancellationToken cancellationToken)
        {
            _logger.LogInformation("التحقق من حسابات العملاء");

            var customers = users.Where(u => u.UserRoles == null ||
                !u.UserRoles.Any(r => r.Role != null && (r.Role.Name == "Owner" || r.Role.Name == "Admin")));

            foreach (var customer in customers)
            {
                // التحقق من وجود حساب ذمم مدينة للعميل
                var customerAccount = accounts.FirstOrDefault(a =>
                    (a.NameAr != null && a.NameAr.Contains($"عميل #{customer.Id}")) ||
                    (a.NameEn != null && a.NameEn.Contains($"Customer #{customer.Id}")) ||
                    (a.Description != null && a.Description.Contains(customer.Id.ToString())));

                if (customerAccount == null)
                {
                    var issue = new ValidationIssue
                    {
                        Type = "MISSING_CUSTOMER_ACCOUNT",
                        Description = $"العميل {customer.Name} ({customer.Id}) لا يملك حساب ذمم مدينة",
                        AffectedEntity = "Customer",
                        EntityId = customer.Id,
                        IsFixed = false
                    };

                    if (autoFix)
                    {
                        try
                        {
                            var created = await _financialAccountingService.CreateCustomerFinancialAccountAsync(
                                customer.Id, customer.Name, cancellationToken);
                            
                            if (created)
                            {
                                issue.IsFixed = true;
                                issue.FixMessage = "تم إنشاء حساب ذمم مدينة للعميل";
                                _logger.LogInformation("تم إصلاح: إنشاء حساب للعميل {CustomerId}", customer.Id);
                            }
                        }
                        catch (Exception ex)
                        {
                            _logger.LogError(ex, "فشل إنشاء حساب للعميل {CustomerId}", customer.Id);
                            issue.FixMessage = $"فشل الإصلاح: {ex.Message}";
                        }
                    }

                    result.Issues.Add(issue);
                    result.Summary.CustomersWithoutAccounts++;
                }
                else
                {
                    result.Summary.CustomerAccountsCount++;
                }
            }
        }

        private async Task ValidateOwnerAccountsAsync(
            IEnumerable<User> users,
            IEnumerable<Property> properties,
            IEnumerable<ChartOfAccount> accounts,
            FinancialSetupValidationResult result,
            bool autoFix,
            CancellationToken cancellationToken)
        {
            _logger.LogInformation("التحقق من حسابات الملاك");

            var ownerIds = properties.Select(p => p.OwnerId).Distinct();
            var owners = users.Where(u => ownerIds.Contains(u.Id));

            foreach (var owner in owners)
            {
                // التحقق من حساب ذمم دائنة
                var payableAccount = accounts.FirstOrDefault(a =>
                    a.AccountType == AccountType.Liabilities &&
                    ((a.NameAr != null && a.NameAr.Contains($"مالك #{owner.Id}")) ||
                     (a.NameEn != null && a.NameEn.Contains($"Owner #{owner.Id}")) ||
                     (a.Description != null && a.Description.Contains($"ذمم دائنة") && a.Description.Contains(owner.Id.ToString()))));

                // التحقق من حساب عمولات مستحقة
                var commissionAccount = accounts.FirstOrDefault(a =>
                    a.AccountType == AccountType.Liabilities &&
                    ((a.NameAr != null && a.NameAr.Contains($"عمولات مستحقة") && a.NameAr.Contains($"#{owner.Id}")) ||
                     (a.NameEn != null && a.NameEn.Contains($"Commission") && a.NameEn.Contains($"#{owner.Id}")) ||
                     (a.Description != null && a.Description.Contains($"عمولات مستحقة") && a.Description.Contains(owner.Id.ToString()))));

                var hasPayable = payableAccount != null;
                var hasCommission = commissionAccount != null;

                if (!hasPayable || !hasCommission)
                {
                    var missingAccounts = new List<string>();
                    if (!hasPayable) missingAccounts.Add("ذمم دائنة");
                    if (!hasCommission) missingAccounts.Add("عمولات مستحقة");

                    var issue = new ValidationIssue
                    {
                        Type = "MISSING_OWNER_ACCOUNTS",
                        Description = $"المالك {owner.Name} ({owner.Id}) يفتقد حسابات: {string.Join(", ", missingAccounts)}",
                        AffectedEntity = "Owner",
                        EntityId = owner.Id,
                        IsFixed = false
                    };

                    if (autoFix)
                    {
                        try
                        {
                            var created = await _financialAccountingService.CreateOwnerFinancialAccountsAsync(
                                owner.Id, owner.Name, cancellationToken);
                            
                            if (created)
                            {
                                issue.IsFixed = true;
                                issue.FixMessage = "تم إنشاء الحسابات الناقصة للمالك";
                                _logger.LogInformation("تم إصلاح: إنشاء حسابات للمالك {OwnerId}", owner.Id);
                            }
                        }
                        catch (Exception ex)
                        {
                            _logger.LogError(ex, "فشل إنشاء حسابات للمالك {OwnerId}", owner.Id);
                            issue.FixMessage = $"فشل الإصلاح: {ex.Message}";
                        }
                    }

                    result.Issues.Add(issue);
                    
                    if (!hasPayable && !hasCommission)
                    {
                        result.Summary.OwnersWithoutAccounts++;
                    }
                    else
                    {
                        result.Summary.OwnersWithSingleAccount++;
                    }
                }
                else
                {
                    result.Summary.OwnerAccountsCount++;
                }
            }
        }

        private async Task ValidateSystemAccountsAsync(
            IEnumerable<ChartOfAccount> accounts,
            FinancialSetupValidationResult result,
            CancellationToken cancellationToken)
        {
            _logger.LogInformation("التحقق من حسابات النظام");

            var requiredSystemAccounts = new[]
            {
                "النقدية",
                "البنك",
                "إيرادات الحجوزات",
                "عمولات المنصة",
                "الضرائب المستحقة",
                "ذمم مدينة - عملاء",
                "ذمم دائنة - ملاك",
                "حساب المنصة",
                "أموال الملاك المعلقة",
                "عمولات المنصة المستحقة",
                "رسوم الإلغاء",
                "مردودات المبيعات"
            };

            foreach (var accountName in requiredSystemAccounts)
            {
                var systemAccount = accounts.FirstOrDefault(a =>
                    a.NameAr == accountName || 
                    a.NameEn == accountName ||
                    (a.IsSystemAccount && a.Description != null && a.Description.Contains(accountName)));

                if (systemAccount == null)
                {
                    result.Issues.Add(new ValidationIssue
                    {
                        Type = "MISSING_SYSTEM_ACCOUNT",
                        Description = $"حساب النظام '{accountName}' غير موجود",
                        AffectedEntity = "SystemAccount",
                        IsFixed = false,
                        FixMessage = "يتطلب تشغيل ChartOfAccountSeeder"
                    });
                }
                else
                {
                    result.Summary.SystemAccountsCount++;
                }
            }

            await Task.CompletedTask;
        }
    }
}
