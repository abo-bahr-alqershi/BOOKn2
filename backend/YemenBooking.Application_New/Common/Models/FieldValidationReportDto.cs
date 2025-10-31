using System;
using System.Collections.Generic;
using YemenBooking.Application.Features.Reports.DTOs;
using YemenBooking.Application.Infrastructure.Services;

namespace YemenBooking.Application.Common.Models
{
    /// <summary>
    /// تقرير التحقق من صحة الحقول
    /// Field validation report
    /// </summary>
    public class FieldValidationReportDto
    {
        /// <summary>
        /// معرف التقرير
        /// Report ID
        /// </summary>
        public Guid ReportId { get; set; }

        /// <summary>
        /// وقت إنشاء التقرير
        /// Report generation time
        /// </summary>
        public DateTime GeneratedAt { get; set; }

        /// <summary>
        /// مدة التحقق بالثواني
        /// Validation duration in seconds
        /// </summary>
        public double ValidationDurationSeconds { get; set; }

        /// <summary>
        /// نطاق التحقق المطبق
        /// Applied validation scope
        /// </summary>
        public ValidationScope AppliedScope { get; set; }

        /// <summary>
        /// العدد الإجمالي للعناصر المفحوصة
        /// Total items validated
        /// </summary>
        public int TotalItemsValidated { get; set; }

        /// <summary>
        /// عدد العناصر الصحيحة
        /// Valid items count
        /// </summary>
        public int ValidItemsCount { get; set; }

        /// <summary>
        /// عدد العناصر التي بها أخطاء
        /// Invalid items count
        /// </summary>
        public int InvalidItemsCount { get; set; }

        /// <summary>
        /// عدد العناصر التي تم إصلاحها تلقائياً
        /// Auto-fixed items count
        /// </summary>
        public int AutoFixedItemsCount { get; set; }

        /// <summary>
        /// عدد العناصر المتجاهلة
        /// Skipped items count
        /// </summary>
        public int SkippedItemsCount { get; set; }

        /// <summary>
        /// النتيجة الإجمالية للتحقق
        /// Overall validation result
        /// </summary>
        public ValidationResult OverallResult { get; set; }

        /// <summary>
        /// نسبة النجاح
        /// Success percentage
        /// </summary>
        public decimal SuccessPercentage { get; set; }

        /// <summary>
        /// ملخص الأخطاء حسب النوع
        /// Error summary by type
        /// </summary>
        public Dictionary<string, int> ErrorsByType { get; set; } = new Dictionary<string, int>();

        /// <summary>
        /// ملخص الحقول المفحوصة
        /// Validated fields summary
        /// </summary>
        public List<FieldValidationSummaryDto> FieldsSummary { get; set; } = new List<FieldValidationSummaryDto>();

        /// <summary>
        /// الأخطاء المكتشفة
        /// Detected errors
        /// </summary>
        public List<ValidationErrorDto> ValidationErrors { get; set; } = new List<ValidationErrorDto>();

        /// <summary>
        /// التحذيرات
        /// Warnings
        /// </summary>
        public List<ValidationWarningDto> ValidationWarnings { get; set; } = new List<ValidationWarningDto>();

        /// <summary>
        /// توصيات للتحسين
        /// Improvement recommendations
        /// </summary>
        public List<ValidationRecommendationDto> Recommendations { get; set; } = new List<ValidationRecommendationDto>();

        /// <summary>
        /// إحصائيات مفصلة
        /// Detailed statistics
        /// </summary>
        public ValidationStatisticsDto? DetailedStatistics { get; set; }

        /// <summary>
        /// رابط التقرير القابل للتصدير
        /// Exportable report URL
        /// </summary>
        public string? ExportableReportUrl { get; set; }

        /// <summary>
        /// رابط تقرير الأخطاء المفصل
        /// Detailed error report URL
        /// </summary>
        public string? DetailedErrorReportUrl { get; set; }

        /// <summary>
        /// معرفات العناصر التي تم إصلاحها
        /// Fixed item IDs
        /// </summary>
        public List<Guid> FixedItemIds { get; set; } = new List<Guid>();

        /// <summary>
        /// رسالة ملخص التقرير
        /// Report summary message
        /// </summary>
        public string SummaryMessage { get; set; }
    }
} 