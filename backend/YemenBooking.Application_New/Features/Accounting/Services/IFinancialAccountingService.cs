using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Analytics.DTOs;
using YemenBooking.Application.Features.Reports.DTOs;

namespace YemenBooking.Application.Features.Accounting.Services;

/// <summary>
/// واجهة خدمة المحاسبة المالية
/// Financial Accounting Service Interface
/// </summary>
public interface IFinancialAccountingService
{
    /// <summary>
    /// تسجيل عملية حجز جديدة
    /// Record new booking transaction
    /// </summary>
    Task<FinancialTransaction> RecordBookingTransactionAsync(Guid bookingId, Guid userId);

    /// <summary>
    /// تسجيل عملية دفع
    /// Record payment transaction
    /// </summary>
    Task<FinancialTransaction> RecordPaymentTransactionAsync(Guid paymentId, Guid userId);

    /// <summary>
    /// تسجيل إلغاء الحجز
    /// Record cancellation transaction
    /// </summary>
    Task<FinancialTransaction> RecordCancellationTransactionAsync(Guid bookingId, Guid userId);
    
    /// <summary>
    /// تسجيل إلغاء الحجز مع السبب (متوافق مع الاسم القديم)
    /// Record booking cancellation with reason (compatible with old name)
    /// </summary>
    Task<FinancialTransaction> RecordBookingCancellationAsync(Guid bookingId, string reason, Guid userId);

    /// <summary>
    /// تسجيل استرداد مبلغ
    /// Record refund transaction
    /// </summary>
    Task<FinancialTransaction> RecordRefundTransactionAsync(Guid bookingId, decimal refundAmount, Guid userId);

    /// <summary>
    /// تسجيل دفعة للمالك
    /// Record owner payout
    /// </summary>
    Task<FinancialTransaction> RecordOwnerPayoutAsync(Guid propertyId, decimal amount, Guid userId);
    
    /// <summary>
    /// تسجيل مصروف
    /// Record expense
    /// </summary>
    Task<FinancialTransaction> RecordExpenseAsync(string description, decimal amount, AccountType accountType, Guid userId);

    /// <summary>
    /// تسجيل إكمال الحجز
    /// Record booking completion
    /// </summary>
    Task<FinancialTransaction> RecordBookingCompletionAsync(Guid bookingId, decimal finalAmount, Guid userId);

    /// <summary>
    /// الحصول على بيانات مخطط الإيرادات
    /// Get revenue chart data
    /// </summary>
    Task<List<FinancialChartDto>> GetRevenueChartDataAsync(DateTime startDate, DateTime endDate);
    
    /// <summary>
    /// الحصول على بيانات مخطط المصروفات
    /// Get expense chart data
    /// </summary>
    Task<List<FinancialChartDto>> GetExpenseChartDataAsync(DateTime startDate, DateTime endDate);
    
    /// <summary>
    /// الحصول على بيانات التدفق النقدي
    /// Get cash flow chart data
    /// </summary>
    Task<List<FinancialChartDto>> GetCashFlowChartDataAsync(DateTime startDate, DateTime endDate);
    
    /// <summary>
    /// الحصول على الملخص المالي الشامل
    /// Get comprehensive financial summary
    /// </summary>
    Task<FinancialSummaryDto> GetFinancialSummaryAsync();

    /// <summary>
    /// الحصول على تقرير مالي لفترة معينة
    /// Get financial report for a period
    /// </summary>
    Task<FinancialReportDto> GetFinancialReportAsync(DateTime startDate, DateTime endDate);

    /// <summary>
    /// إنشاء الحساب المالي للعميل (ذمم مدينة فقط)
    /// Create customer financial account (accounts receivable only)
    /// </summary>
    Task<bool> CreateCustomerFinancialAccountAsync(Guid customerId, string customerName, CancellationToken cancellationToken);

    /// <summary>
    /// إنشاء الحسابات المالية للمالك (ذمم دائنة + عمولات مستحقة)
    /// Create owner financial accounts (accounts payable + commission payable)
    /// </summary>
    Task<bool> CreateOwnerFinancialAccountsAsync(Guid ownerId, string ownerName, CancellationToken cancellationToken);

    /// <summary>
    /// [DEPRECATED] استخدم CreateCustomerFinancialAccountAsync أو CreateOwnerFinancialAccountsAsync
    /// [DEPRECATED] Use CreateCustomerFinancialAccountAsync or CreateOwnerFinancialAccountsAsync
    /// </summary>
    [System.Obsolete("استخدم CreateCustomerFinancialAccountAsync للعملاء أو CreateOwnerFinancialAccountsAsync للملاك")]
    Task<bool> CreateUserFinancialAccountsAsync(Guid userId, string userName, CancellationToken cancellationToken);

    /// <summary>
    /// التحقق من وجود عمليات مالية للمستخدم
    /// Check if user has financial transactions
    /// </summary>
    Task<bool> HasFinancialTransactionsAsync(Guid userId);

    /// <summary>
    /// تسجيل قيد تأكيد الحجز - تحقق إيراد العمولة
    /// Record booking confirmation transaction - Commission revenue realization
    /// </summary>
    Task<FinancialTransaction> RecordBookingConfirmationTransactionAsync(Guid bookingId, Guid userId);

    /// <summary>
    /// تسجيل قيد تسجيل الخروج - تحرير أموال المالك
    /// Record checkout transaction - Release owner funds
    /// </summary>
    Task<FinancialTransaction> RecordCheckoutTransactionAsync(Guid bookingId, Guid userId);

    /// <summary>
    /// تسجيل قيد إلغاء الحجز مع رسوم إلغاء
    /// Record cancellation with cancellation fees
    /// </summary>
    Task<FinancialTransaction> RecordCancellationWithFeesAsync(Guid bookingId, decimal cancellationFeePercentage, Guid userId);

    /// <summary>
    /// تسجيل قيد خدمة إضافية
    /// Record additional service transaction
    /// </summary>
    Task<FinancialTransaction> RecordAdditionalServiceTransactionAsync(
        Guid bookingId,
        Guid serviceId,
        decimal serviceAmount,
        string serviceName,
        Guid userId);

    /// <summary>
    /// إقفال الفترة المحاسبية
    /// Close accounting period
    /// </summary>
    Task<bool> CloseAccountingPeriodAsync(int year, int month, Guid userId);

    /// <summary>
    /// تحويل مستحقات الملاك
    /// Transfer owner payouts
    /// </summary>
    Task<int> ProcessOwnerPayoutsAsync(Guid userId);

    /// <summary>
    /// تسجيل استرداد مبلغ مع السبب
    /// Record refund transaction with reason
    /// </summary>
    Task<FinancialTransaction> RecordRefundTransactionAsync(
        Guid bookingId, 
        decimal amount, 
        string reason, 
        Guid userId);

    /// <summary>
    /// تسجيل دفعة للمالك مع الوصف
    /// Record owner payout with description
    /// </summary>
    Task<FinancialTransaction> RecordOwnerPayoutAsync(
        Guid propertyId,
        Guid ownerId,
        decimal amount,
        string description,
        Guid userId);
}
