using System;
using System.Collections.Generic;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;

namespace YemenBooking.Application.Features.Accounting.Commands.Setup
{
    /// <summary>
    /// أمر التحقق من صحة الإعدادات المحاسبية
    /// Validate financial setup command
    /// </summary>
    public class ValidateFinancialSetupCommand : IRequest<ResultDto<FinancialSetupValidationResult>>
    {
        /// <summary>
        /// التحقق من حسابات العملاء
        /// Check customer accounts
        /// </summary>
        public bool CheckCustomerAccounts { get; set; } = true;

        /// <summary>
        /// التحقق من حسابات الملاك
        /// Check owner accounts
        /// </summary>
        public bool CheckOwnerAccounts { get; set; } = true;

        /// <summary>
        /// التحقق من حسابات النظام
        /// Check system accounts
        /// </summary>
        public bool CheckSystemAccounts { get; set; } = true;

        /// <summary>
        /// إصلاح المشاكل تلقائياً
        /// Auto-fix issues
        /// </summary>
        public bool AutoFix { get; set; } = false;
    }

    /// <summary>
    /// نتيجة التحقق من الإعدادات المحاسبية
    /// Financial setup validation result
    /// </summary>
    public class FinancialSetupValidationResult
    {
        /// <summary>
        /// هل الإعدادات صحيحة
        /// Is setup valid
        /// </summary>
        public bool IsValid { get; set; }

        /// <summary>
        /// عدد المشاكل المكتشفة
        /// Issues found count
        /// </summary>
        public int IssuesFound { get; set; }

        /// <summary>
        /// عدد المشاكل المصححة
        /// Issues fixed count
        /// </summary>
        public int IssuesFixed { get; set; }

        /// <summary>
        /// تفاصيل المشاكل
        /// Issue details
        /// </summary>
        public List<ValidationIssue> Issues { get; set; } = new List<ValidationIssue>();

        /// <summary>
        /// ملخص الحسابات
        /// Accounts summary
        /// </summary>
        public AccountsSummary Summary { get; set; } = new AccountsSummary();
    }

    /// <summary>
    /// مشكلة في التحقق
    /// Validation issue
    /// </summary>
    public class ValidationIssue
    {
        /// <summary>
        /// نوع المشكلة
        /// Issue type
        /// </summary>
        public string Type { get; set; }

        /// <summary>
        /// وصف المشكلة
        /// Issue description
        /// </summary>
        public string Description { get; set; }

        /// <summary>
        /// الكيان المتأثر
        /// Affected entity
        /// </summary>
        public string AffectedEntity { get; set; }

        /// <summary>
        /// معرف الكيان
        /// Entity ID
        /// </summary>
        public Guid? EntityId { get; set; }

        /// <summary>
        /// هل تم الإصلاح
        /// Is fixed
        /// </summary>
        public bool IsFixed { get; set; }

        /// <summary>
        /// رسالة الإصلاح
        /// Fix message
        /// </summary>
        public string FixMessage { get; set; }
    }

    /// <summary>
    /// ملخص الحسابات
    /// Accounts summary
    /// </summary>
    public class AccountsSummary
    {
        /// <summary>
        /// عدد حسابات العملاء
        /// Customer accounts count
        /// </summary>
        public int CustomerAccountsCount { get; set; }

        /// <summary>
        /// عدد حسابات الملاك
        /// Owner accounts count
        /// </summary>
        public int OwnerAccountsCount { get; set; }

        /// <summary>
        /// عدد حسابات النظام
        /// System accounts count
        /// </summary>
        public int SystemAccountsCount { get; set; }

        /// <summary>
        /// عدد العملاء بدون حسابات
        /// Customers without accounts count
        /// </summary>
        public int CustomersWithoutAccounts { get; set; }

        /// <summary>
        /// عدد الملاك بدون حسابات
        /// Owners without accounts count
        /// </summary>
        public int OwnersWithoutAccounts { get; set; }

        /// <summary>
        /// عدد الملاك بحساب واحد فقط
        /// Owners with single account count
        /// </summary>
        public int OwnersWithSingleAccount { get; set; }
    }
}
