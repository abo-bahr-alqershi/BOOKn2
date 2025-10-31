using System;
using YemenBooking.Core.Enums;

namespace YemenBooking.Application.Features.Policies.DTOs {
    /// <summary>
    /// تفاصيل السياسة
    /// Policy details DTO
    /// </summary>
    public class PolicyDetailsDto
    {
        /// <summary>
        /// معرف السياسة
        /// Policy identifier
        /// </summary>
        public Guid Id { get; set; }

        /// <summary>
        /// معرف الكيان
        /// Property identifier
        /// </summary>
        public Guid PropertyId { get; set; }

        /// <summary>
        /// نوع السياسة
        /// Policy type
        /// </summary>
        public PolicyType PolicyType { get; set; }

        /// <summary>
        /// وصف السياسة
        /// Policy description
        /// </summary>
        public string Description { get; set; } = string.Empty;

        /// <summary>
        /// قواعد السياسة (JSON)
        /// Policy rules (JSON)
        /// </summary>
        public string Rules { get; set; } = string.Empty;

        /// <summary>
        /// عدد أيام نافذة الإلغاء قبل تاريخ الوصول
        /// Number of days before check-in to allow cancellation
        /// </summary>
        public int CancellationWindowDays { get; set; }

        /// <summary>
        /// يتطلب الدفع الكامل قبل التأكيد
        /// Requires full payment before confirmation
        /// </summary>
        public bool RequireFullPaymentBeforeConfirmation { get; set; }

        /// <summary>
        /// الحد الأدنى لنسبة الدفع المقدمة (كنسبة مئوية)
        /// Minimum deposit percentage (as percentage)
        /// </summary>
        public decimal MinimumDepositPercentage { get; set; }

        /// <summary>
        /// الحد الأدنى للساعات قبل تسجيل الوصول لتعديل الحجز
        /// Minimum hours before check-in to allow modification
        /// </summary>
        public int MinHoursBeforeCheckIn { get; set; }

        /// <summary>
        /// تاريخ الإنشاء
        /// Creation date
        /// </summary>
        public DateTime? CreatedAt { get; set; }

        /// <summary>
        /// تاريخ آخر تحديث
        /// Last update date
        /// </summary>
        public DateTime? UpdatedAt { get; set; }

        /// <summary>
        /// حالة السياسة
        /// Policy status
        /// </summary>
        public bool IsActive { get; set; } = true;
    }
} 