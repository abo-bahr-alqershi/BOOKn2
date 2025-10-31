using System;
using System.Collections.Generic;

namespace YemenBooking.Application.Features.SearchAndFilters.DTOs {
    /// <summary>
    /// عنصر في نتائج البحث
    /// </summary>
    public class PropertySearchItemDto
    {
        /// <summary>
        /// معرف الكيان
        /// </summary>
        public Guid Id { get; set; }

        /// <summary>
        /// اسم الكيان
        /// </summary>
        public string Name { get; set; }

        /// <summary>
        /// وصف الكيان
        /// </summary>
        public string? Description { get; set; }

        /// <summary>
        /// المدينة
        /// </summary>
        public string City { get; set; }

        /// <summary>
        /// العنوان
        /// </summary>
        public string Address { get; set; }

        /// <summary>
        /// تقييم النجوم
        /// </summary>
        public int StarRating { get; set; }

        /// <summary>
        /// متوسط التقييم
        /// </summary>
        public decimal? AverageRating { get; set; }

        /// <summary>
        /// عدد المراجعات
        /// </summary>
        public int ReviewCount { get; set; }

        /// <summary>
        /// الحد الأدنى للسعر
        /// </summary>
        public decimal MinPrice { get; set; }

        /// <summary>
        /// عملة السعر
        /// </summary>
        public string Currency { get; set; }

        /// <summary>
        /// الصورة الرئيسية
        /// </summary>
        public string? MainImageUrl { get; set; }

        /// <summary>
        /// قائمة الصور
        /// </summary>
        public List<string> ImageUrls { get; set; } = new List<string>();

        /// <summary>
        /// المرافق المتاحة
        /// </summary>
        public List<string> Amenities { get; set; } = new List<string>();

        /// <summary>
        /// نوع الكيان
        /// </summary>
        public string PropertyType { get; set; }

        /// <summary>
        /// المسافة من نقطة البحث (بالكيلومتر)
        /// </summary>
        public double? DistanceKm { get; set; }

        /// <summary>
        /// حالة التوفر
        /// </summary>
        public bool IsAvailable { get; set; }

        /// <summary>
        /// عدد الوحدات المتاحة
        /// </summary>
        public int AvailableUnitsCount { get; set; }

        /// <summary>
        /// السعة القصوى
        /// </summary>
        public int MaxCapacity { get; set; }

        /// <summary>
        /// هل مميز
        /// </summary>
        public bool IsFeatured { get; set; }

        /// <summary>
        /// تاريخ آخر تحديث
        /// </summary>
        public DateTime LastUpdated { get; set; }
    }
} 