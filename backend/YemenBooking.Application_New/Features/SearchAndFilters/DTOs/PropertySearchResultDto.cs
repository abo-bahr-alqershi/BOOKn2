using System;
using System.Collections.Generic;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Reviews.DTOs;

namespace YemenBooking.Application.Features.SearchAndFilters.DTOs {
    /// <summary>
    /// نتيجة البحث في العقارات - عنصر واحد
    /// Property search result item DTO
    /// </summary>
    public class PropertySearchResultDto
    {
        /// <summary>
        /// معرف العقار
        /// Property ID
        /// </summary>
        public Guid Id { get; set; }

        /// <summary>
        /// اسم العقار
        /// Property name
        /// </summary>
        public string Name { get; set; } = string.Empty;

        /// <summary>
        /// وصف العقار
        /// Property description
        /// </summary>
        public string Description { get; set; } = string.Empty;

        /// <summary>
        /// العنوان
        /// Address
        /// </summary>
        public string Address { get; set; } = string.Empty;

        /// <summary>
        /// المدينة
        /// City
        /// </summary>
        public string City { get; set; } = string.Empty;

        /// <summary>
        /// تقييم النجوم
        /// Star rating
        /// </summary>
        public int StarRating { get; set; }

        /// <summary>
        /// متوسط التقييم
        /// Average rating
        /// </summary>
        public decimal AverageRating { get; set; }

        /// <summary>
        /// عدد المراجعات
        /// Reviews count
        /// </summary>
        public int ReviewsCount { get; set; }

        /// <summary>
        /// أقل سعر متاح
        /// Minimum price
        /// </summary>
        public decimal MinPrice { get; set; }

        /// <summary>
        /// السعر بعد الخصم (إن وجد)
        /// Discounted price (if any)
        /// </summary>
        public decimal DiscountedPrice { get; set; }

        /// <summary>
        /// العملة
        /// Currency
        /// </summary>
        public string Currency { get; set; } = string.Empty;

        /// <summary>
        /// رابط الصورة الرئيسية
        /// Main image URL
        /// </summary>
        public string? MainImageUrl { get; set; }

        /// <summary>
        /// هل موصى به
        /// Is recommended
        /// </summary>
        public bool IsRecommended { get; set; }

        /// <summary>
        /// المسافة بالكيلومتر (إذا كان البحث جغرافي)
        /// Distance in kilometers (if geographic search)
        /// </summary>
        public double? DistanceKm { get; set; }

        /// <summary>
        /// خط العرض للموقع
        /// Latitude coordinate
        /// </summary>
        public decimal Latitude { get; set; }

        /// <summary>
        /// خط الطول للموقع
        /// Longitude coordinate
        /// </summary>
        public decimal Longitude { get; set; }

        /// <summary>
        /// معرف الوحدة الأولى المطابقة للفلترة
        /// First matching unit ID
        /// </summary>
        public Guid? UnitId { get; set; }

        /// <summary>
        /// اسم الوحدة الأولى المطابقة (يُعاد فقط عند تحديد فلترة الإتاحة)
        /// First matching unit name (returned only when availability filter is provided)
        /// </summary>
        public string? UnitName { get; set; }

        /// <summary>
        /// قيم الحقول الديناميكية القابلة للعرض
        /// Visible dynamic field values
        /// </summary>
        public Dictionary<string, object> DynamicFieldValues { get; set; } = new();

        /// <summary>
        /// مؤشر التفضيل
        /// Is favorite
        /// </summary>
        public bool IsFavorite { get; set; }
        /// <summary>
        /// نسبة التطابق مع معايير البحث
        /// Match percentage
        /// </summary>
        public int MatchPercentage { get; set; }

        /// <summary>
        /// هل متاح للحجز
        /// Is available for booking
        /// </summary>
        public bool IsAvailable { get; set; } = true;

        /// <summary>
        /// عدد الوحدات المتاحة
        /// Available units count
        /// </summary>
        public int AvailableUnitsCount { get; set; }

        /// <summary>
        /// نوع العقار
        /// Property type
        /// </summary>
        public string PropertyType { get; set; } = string.Empty;

        /// <summary>
        /// هل مميز
        /// Is featured
        /// </summary>
        public bool IsFeatured { get; set; }

        /// <summary>
        /// قائمة وسائل الراحة الرئيسية
        /// Main amenities list
        /// </summary>
        public List<string> MainAmenities { get; set; } = new();

        /// <summary>
        /// قائمة المراجعات مع الردود
        /// Reviews with responses
        /// </summary>
        public List<ReviewDto> Reviews { get; set; } = new();
        /// <summary>
        /// السعة القصوى
        /// Maximum capacity
        /// </summary>
        public int MaxCapacity { get; set; }
        /// <summary>
        /// وقت آخر تحديث
        /// Last updated timestamp
        /// </summary>
        public DateTime LastUpdated { get; set; }
        /// <summary>
        /// روابط الصور
        /// Additional image URLs
        /// </summary>
        public List<string> ImageUrls { get; set; } = new();
    }
} 