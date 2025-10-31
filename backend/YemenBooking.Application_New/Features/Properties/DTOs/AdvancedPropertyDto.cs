using System;
using System.Collections.Generic;

namespace YemenBooking.Application.Features.Properties.DTOs
{
    /// <summary>
    /// بيانات عرض الكيان في نتائج البحث المتقدم
    /// </summary>
    public class AdvancedPropertyDto
    {
        /// <summary>
        /// الصورة الرئيسية للفندق
        /// URL of main image
        /// </summary>
        public string MainImageUrl { get; set; }

        /// <summary>
        /// اسم الفندق
        /// Property name
        /// </summary>
        public string Name { get; set; }

        /// <summary>
        /// متوسط تقييم الفندق
        /// Average rating
        /// </summary>
        public double AverageRating { get; set; }

        /// <summary>
        /// هل هو مفضل لدى العميل الحالي
        /// Is it in current user's favorites
        /// </summary>
        public bool IsFavorite { get; set; }

        /// <summary>
        /// عدد المراجعات
        /// Reviews count
        /// </summary>
        public int ReviewsCount { get; set; }

        /// <summary>
        /// نجوم الفندق (تم تعيينها عند الإنشاء)
        /// Star rating
        /// </summary>
        public int StarRating { get; set; }

        /// <summary>
        /// السعر الأساسي للوحدة المناسب للبحث
        /// Base price of matching unit
        /// </summary>
        public decimal BasePrice { get; set; }

        /// <summary>
        /// السعر بعد التخفيض (إن وجد)
        /// Discounted price if a pricing rule applies and is lower than base price
        /// </summary>
        public decimal EffectivePrice { get; set; }

        /// <summary>
        /// قيم الحقول الديناميكية المعروضة في الكروت
        /// Field values for fields where ShowInCards == true
        /// </summary>
        public Dictionary<string, string> CardFieldValues { get; set; }

        /// <summary>
        /// إحداثيات الموقع (خط العرض، خط الطول)
        /// Coordinates
        /// </summary>
        public (decimal Latitude, decimal Longitude) Coordinates { get; set; }
    }
} 