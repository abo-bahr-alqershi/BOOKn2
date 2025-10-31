using System;
using System.ComponentModel.DataAnnotations;
using YemenBooking.Core.Enums;

namespace YemenBooking.Core.Entities
{
    /// <summary>
    /// كيان العروض الخاصة
    /// Special offers entity
    /// </summary>
    public class SpecialOffer : BaseEntity<Guid>
    {
        /// <summary>
        /// عنوان العرض
        /// Offer title
        /// </summary>
        [Required]
        [MaxLength(200)]
        public string Title { get; set; } = string.Empty;

        /// <summary>
        /// وصف العرض
        /// Offer description
        /// </summary>
        [MaxLength(1000)]
        public string Description { get; set; } = string.Empty;

        /// <summary>
        /// نوع العرض
        /// Offer type
        /// </summary>
        public OfferType OfferType { get; set; }

        /// <summary>
        /// قيمة الخصم
        /// Discount value
        /// </summary>
        public decimal DiscountValue { get; set; }

        /// <summary>
        /// نوع الخصم (نسبة مئوية أم مبلغ ثابت)
        /// Discount type (percentage or fixed amount)
        /// </summary>
        public DiscountType DiscountType { get; set; }

        /// <summary>
        /// نسبة الخصم المئوية (اختياري)
        /// Discount percentage (optional)
        /// </summary>
        public decimal DiscountPercentage { get; set; }

        /// <summary>
        /// مبلغ الخصم الثابت (اختياري)
        /// Discount amount (optional)
        /// </summary>
        public decimal DiscountAmount { get; set; }

        /// <summary>
        /// تاريخ انتهاء العرض (اختياري)
        /// Offer expiry date (optional)
        /// </summary>
        public DateTime? ExpiryDate { get; set; }

        /// <summary>
        /// لون مميز لعرض شارة في الواجهة
        /// Highlight color for displaying badge
        /// </summary>
        public string? Color { get; set; } = "#FF6B6B";

        /// <summary>
        /// الحد الأدنى للمبلغ لتطبيق العرض
        /// Minimum amount to apply offer
        /// </summary>
        public decimal? MinimumAmount { get; set; }

        /// <summary>
        /// الحد الأقصى للخصم
        /// Maximum discount amount
        /// </summary>
        public decimal? MaxDiscountAmount { get; set; }

        /// <summary>
        /// تاريخ بداية العرض
        /// Offer start date
        /// </summary>
        public DateTime StartDate { get; set; }

        /// <summary>
        /// تاريخ انتهاء العرض
        /// Offer end date
        /// </summary>
        public DateTime EndDate { get; set; }

        /// <summary>
        /// العدد الأقصى للاستخدامات
        /// Maximum usage count
        /// </summary>
        public int? MaxUsageCount { get; set; }

        /// <summary>
        /// العدد الحالي للاستخدامات
        /// Current usage count
        /// </summary>
        public int CurrentUsageCount { get; set; } = 0;

        /// <summary>
        /// هل العرض نشط
        /// Whether the offer is active
        /// </summary>
        public bool IsActive { get; set; } = true;

        /// <summary>
        /// كود العرض (اختياري)
        /// Offer code (optional)
        /// </summary>
        [MaxLength(50)]
        public string? OfferCode { get; set; }

        /// <summary>
        /// معرف العقار المرتبط بالعرض (اختياري)
        /// Associated property ID (optional)
        /// </summary>
        public Guid? PropertyId { get; set; }

        /// <summary>
        /// العقار المرتبط بالعرض
        /// Associated property
        /// </summary>
        public virtual Property? Property { get; set; }

        /// <summary>
        /// صورة العرض
        /// Offer image URL
        /// </summary>
        [MaxLength(500)]
        public string? ImageUrl { get; set; }

        /// <summary>
        /// أولوية العرض (للترتيب)
        /// Offer priority (for ordering)
        /// </summary>
        public int Priority { get; set; } = 0;

        /// <summary>
        /// شروط وأحكام العرض
        /// Offer terms and conditions
        /// </summary>
        [MaxLength(2000)]
        public string? TermsAndConditions { get; set; }
    }

    /// <summary>
    /// نوع العرض
    /// Offer type enumeration
    /// </summary>
    public enum OfferType
    {
        /// <summary>
        /// عرض عام
        /// General offer
        /// </summary>
        General = 1,

        /// <summary>
        /// عرض للحجز المبكر
        /// Early booking offer
        /// </summary>
        EarlyBooking = 2,

        /// <summary>
        /// عرض اللحظة الأخيرة
        /// Last minute offer
        /// </summary>
        LastMinute = 3,

        /// <summary>
        /// عرض الإقامة الطويلة
        /// Long stay offer
        /// </summary>
        LongStay = 4,

        /// <summary>
        /// عرض موسمي
        /// Seasonal offer
        /// </summary>
        Seasonal = 5,

        /// <summary>
        /// عرض للعملاء الجدد
        /// New customer offer
        /// </summary>
        NewCustomer = 6,

        /// <summary>
        /// عرض الولاء
        /// Loyalty offer
        /// </summary>
        Loyalty = 7
    }

    /// <summary>
    /// نوع الخصم
    /// Discount type enumeration
    /// </summary>
    public enum DiscountType
    {
        /// <summary>
        /// نسبة مئوية
        /// Percentage
        /// </summary>
        Percentage = 1,

        /// <summary>
        /// مبلغ ثابت
        /// Fixed amount
        /// </summary>
        FixedAmount = 2
    }
}
