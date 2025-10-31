using System;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Reviews.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Reviews.Queries.GetAllReviews
{
    /// <summary>
    /// استعلام لجلب جميع التقييمات مع دعم التصفية
    /// Query to get all reviews with filtering options
    /// </summary>
    public class GetAllReviewsQuery : IRequest<PaginatedResult<ReviewDto>>
    {
        /// <summary>
        /// حالة التقييم (pending, approved, rejected, all)
        /// Review status filter
        /// </summary>
        public string? Status { get; set; }

        /// <summary>
        /// الحد الأدنى للتقييم (متوسط)
        /// Minimum average rating
        /// </summary>
        public double? MinRating { get; set; }

        /// <summary>
        /// الحد الأقصى للتقييم (متوسط)
        /// Maximum average rating
        /// </summary>
        public double? MaxRating { get; set; }

        /// <summary>
        /// يحتوي على صور
        /// Has images filter
        /// </summary>
        public bool? HasImages { get; set; }

        /// <summary>
        /// تصفية حسب معرف الكيان
        /// Filter by property Id
        /// </summary>
        public Guid? PropertyId { get; set; }

        /// <summary>
        /// تصفية حسب معرف المستخدم
        /// Filter by user Id
        /// </summary>
        public Guid? UserId { get; set; }

        /// <summary>
        /// تصفية حسب معرف الوحدة
        /// Filter by unit Id
        /// </summary>
        public Guid? UnitId { get; set; }
        
        /// <summary>
        /// جلب التقييمات بعد تاريخ معين
        /// Reviewed after date filter
        /// </summary>
        public DateTime? ReviewedAfter { get; set; }

        /// <summary>
        /// جلب التقييمات قبل تاريخ معين
        /// Reviewed before date filter
        /// </summary>
        public DateTime? ReviewedBefore { get; set; }

        /// <summary>
        /// رقم الصفحة (اختياري) - Pagination page number
        /// </summary>
        public int? PageNumber { get; set; }

        /// <summary>
        /// حجم الصفحة (اختياري) - Pagination page size
        /// </summary>
        public int? PageSize { get; set; }

        /// <summary>
        /// Include aggregate statistics in result.Metadata regardless of page number
        /// Defaults to null -> include only on first page for performance
        /// </summary>
        public bool? IncludeStats { get; set; }
    }
} 