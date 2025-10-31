using System.Collections.Generic;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Amenities.DTOs;
using YemenBooking.Application.Features.Analytics.DTOs;
using YemenBooking.Application.Features.Properties.DTOs;

namespace YemenBooking.Application.Features.Users.DTOs;

/// <summary>
/// استجابة قائمة المفضلات
/// User favorites response
/// </summary>
public class UserFavoritesResponse
{
    /// <summary>
    /// قائمة العقارات المفضلة
    /// List of favorite properties
    /// </summary>
    public List<FavoritePropertyDto> Favorites { get; set; } = new();
    
    /// <summary>
    /// إجمالي عدد المفضلات
    /// Total count of favorites
    /// </summary>
    public int TotalCount { get; set; }
}

/// <summary>
/// بيانات العقار المفضل (موسعة لتطابق نموذج الموبايل)
/// Expanded favorite property data to match mobile model
/// </summary>
public class FavoritePropertyDto
{
    /// <summary>
    /// معرف سجل المفضلة
    /// Favorite record ID
    /// </summary>
    public Guid FavoriteId { get; set; }

    /// <summary>
    /// معرف المستخدم
    /// User ID
    /// </summary>
    public Guid UserId { get; set; }

    /// <summary>
    /// معرف العقار
    /// Property ID
    /// </summary>
    public Guid PropertyId { get; set; }
    
    /// <summary>
    /// اسم العقار
    /// Property name
    /// </summary>
    public string PropertyName { get; set; } = string.Empty;
    
    /// <summary>
    /// رابط الصورة الرئيسية
    /// Main image URL
    /// </summary>
    public string PropertyImage { get; set; } = string.Empty;

    /// <summary>
    /// موقع العقار (مدينة أو عنوان مختصر)
    /// Property location (city or short address)
    /// </summary>
    public string PropertyLocation { get; set; } = string.Empty;

    /// <summary>
    /// معرف نوع العقار
    /// Property type ID
    /// </summary>
    public Guid TypeId { get; set; }

    /// <summary>
    /// اسم نوع العقار
    /// Property type name
    /// </summary>
    public string TypeName { get; set; } = string.Empty;

    /// <summary>
    /// اسم المالك
    /// Owner name
    /// </summary>
    public string OwnerName { get; set; } = string.Empty;

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
    /// خط العرض
    /// Latitude
    /// </summary>
    public decimal Latitude { get; set; }

    /// <summary>
    /// خط الطول
    /// Longitude
    /// </summary>
    public decimal Longitude { get; set; }

    /// <summary>
    /// تصنيف النجوم
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
    /// أقل سعر (اختياري)
    /// Minimum price (optional)
    /// </summary>
    public decimal MinPrice { get; set; }

    /// <summary>
    /// العملة
    /// Currency
    /// </summary>
    public string Currency { get; set; } = string.Empty;

    /// <summary>
    /// الصور
    /// Images
    /// </summary>
    public List<FavoritePropertyImageDto> Images { get; set; } = new();

    /// <summary>
    /// المرافق / الوسائل
    /// Amenities
    /// </summary>
    public List<FavoriteAmenityDto> Amenities { get; set; } = new();

    /// <summary>
    /// تاريخ إنشاء سجل المفضلة (يعرض كـ created_at في JSON)
    /// Favorite creation date (exposed as created_at)
    /// </summary>
    public DateTime CreatedAt { get; set; }
}

/// <summary>
/// صورة لعقار مفضل (مطابقة لاحتياجات تطبيق الموبايل)
/// Image for a favorite property (mobile compatible)
/// </summary>
public class FavoritePropertyImageDto
{
    public Guid Id { get; set; }
    public Guid? PropertyId { get; set; }
    public Guid? UnitId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Url { get; set; } = string.Empty;
    public long SizeBytes { get; set; }
    public string Type { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string Caption { get; set; } = string.Empty;
    public string AltText { get; set; } = string.Empty;
    public string Tags { get; set; } = string.Empty;
    public string Sizes { get; set; } = string.Empty;
    public bool IsMain { get; set; }
    public int DisplayOrder { get; set; }
    public DateTime UploadedAt { get; set; }
    public string Status { get; set; } = string.Empty;
    public string AssociationType { get; set; } = string.Empty;
}

/// <summary>
/// مرفق (Amenity) لعقار مفضل
/// Amenity for a favorite property
/// </summary>
public class FavoriteAmenityDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string IconUrl { get; set; } = string.Empty; // Placeholder - backend may extend
    public string Category { get; set; } = string.Empty; // Placeholder
    public bool IsActive { get; set; } = true; // Default active
    public int DisplayOrder { get; set; } = 0; // Placeholder / sort order
    public DateTime CreatedAt { get; set; }
}
