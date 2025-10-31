using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Features.Analytics;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Analytics.DTOs;
using YemenBooking.Application.Features.Properties.DTOs;

namespace YemenBooking.Application.Features.Analytics.Services {
    /// <summary>
    /// واجهة خدمة لوحات التحكم
    /// Interface for dashboard service
    /// </summary>
    public interface IDashboardService
    {
        /// <summary>
        /// الحصول على بيانات لوحة تحكم المسؤول ضمن نطاق زمني
        /// Get admin dashboard data within a date range
        /// </summary>
        Task<AdminDashboardDto> GetAdminDashboardAsync(DateRangeDto range);

        /// <summary>
        /// الحصول على بيانات لوحة تحكم المالك ضمن نطاق زمني
        /// Get owner dashboard data within a date range
        /// </summary>
        Task<OwnerDashboardDto> GetOwnerDashboardAsync(Guid ownerId, DateRangeDto range);

        /// <summary>
        /// الحصول على بيانات لوحة تحكم العميل
        /// Get customer dashboard data
        /// </summary>
        Task<CustomerDashboardDto> GetCustomerDashboardAsync(Guid customerId);

        /// <summary>
        /// الحصول على نسبة الإشغال لكيان ضمن نطاق زمني
        /// Get occupancy rate for a property within a date range
        /// </summary>
        Task<decimal> GetOccupancyRateAsync(Guid propertyId, DateRangeDto range);

        /// <summary>
        /// الحصول على اتجاهات الحجوزات كسلسلة زمنية
        /// Get booking trends as a time series
        /// </summary>
        Task<IEnumerable<TimeSeriesDataDto>> GetBookingTrendsAsync(Guid? propertyId, DateRangeDto range);

        /// <summary>
        /// الحصول على أفضل الكيانات أداءً بناءً على عدد الحجوزات
        /// Get top performing properties based on booking count
        /// </summary>
        Task<IEnumerable<YemenBooking.Application.Features.Properties.DTOs.PropertyDto>> GetTopPerformingPropertiesAsync(int count);

        /// <summary>
        /// الرد على مراجعة
        /// Respond to a review
        /// </summary>
        Task RespondToReviewAsync(Guid reviewId, string responseText, Guid ownerId);

        /// <summary>
        /// الموافقة على مراجعة
        /// Approve a review
        /// </summary>
        Task ApproveReviewAsync(Guid reviewId, Guid adminId);

        /// <summary>
        /// تحديث توفر وحدات متعددة ضمن نطاق زمني
        /// Bulk update unit availability within a date range
        /// </summary>
        Task BulkUpdateUnitAvailabilityAsync(IEnumerable<Guid> unitIds, DateRangeDto range, bool isAvailable);

        /// <summary>
        /// تصدير تقرير لوحة التحكم بالتنسيق المحدد
        /// Export dashboard report in the specified format
        /// </summary>
        Task<byte[]> ExportDashboardReportAsync(DashboardType dashboardType, Guid targetId, ReportFormat format);

        /// <summary>
        /// الحصول على بيانات قمع اكتساب العملاء ضمن نطاق زمني
        /// Get user acquisition funnel data within a date range
        /// </summary>
        Task<UserFunnelDto> GetUserAcquisitionFunnelAsync(DateRangeDto range,CancellationToken cancellationToken = default);

        /// <summary>
        /// الحصول على تحليل أفواج العملاء ضمن نطاق زمني
        /// Get customer cohort analysis within a date range
        /// </summary>
        Task<IEnumerable<CohortDto>> GetCustomerCohortAnalysisAsync(DateRangeDto range);

        /// <summary>
        /// الحصول على تفصيل الإيرادات الكلي لمنصة ضمن نطاق زمني
        /// Get total platform revenue breakdown within a date range
        /// </summary>
        Task<RevenueBreakdownDto> GetPlatformRevenueBreakdownAsync(DateRangeDto range);

        /// <summary>
        /// الحصول على تحليل أسباب إلغاء الحجوزات ضمن نطاق زمني
        /// Get cancellation reasons analysis within a date range
        /// </summary>
        Task<IEnumerable<CancellationReasonDto>> GetPlatformCancellationAnalysisAsync(DateRangeDto range);

        /// <summary>
        /// الحصول على مقارنة أداء الكيان بين فترتين زمنيتين
        /// Get property performance comparison between two date ranges
        /// </summary>
        Task<PerformanceComparisonDto> GetPropertyPerformanceComparisonAsync(Guid propertyId, DateRangeDto currentRange, DateRangeDto previousRange);

        /// <summary>
        /// الحصول على تحليل نافذة الحجز لكيان محدد
        /// Get booking window analysis for a specific property
        /// </summary>
        Task<BookingWindowDto> GetBookingWindowAnalysisAsync(Guid propertyId);

        /// <summary>
        /// الحصول على تحليل مشاعر التقييمات لكيان محدد
        /// Get review sentiment analysis for a specific property
        /// </summary>
        Task<ReviewSentimentDto> GetReviewSentimentAnalysisAsync(Guid propertyId);

        /// <summary>
        /// الحصول على إحصائيات المستخدم مدى الحياة
        /// Get user lifetime statistics
        /// </summary>
        Task<UserLifetimeStatsDto> GetUserLifetimeStatsAsync(Guid userId);

        /// <summary>
        /// الحصول على تقدم ولاء المستخدم
        /// Get user loyalty progress
        /// </summary>
        Task<LoyaltyProgressDto> GetUserLoyaltyProgressAsync(Guid userId);
    }
} 