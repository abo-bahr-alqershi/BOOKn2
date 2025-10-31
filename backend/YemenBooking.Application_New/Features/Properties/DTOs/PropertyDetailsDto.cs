using System.Collections.Generic;
using YemenBooking.Application.Features.Units;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Amenities.DTOs;
using YemenBooking.Application.Features.Properties.DTOs;
using YemenBooking.Application.Features.Services.DTOs;
using YemenBooking.Application.Features.Units.DTOs;

namespace YemenBooking.Application.Features.Properties.DTOs;

/// <summary>
/// تفاصيل العقار
/// Property details DTO
/// </summary>
public class PropertyDetailsDto
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
    /// نوع العقار
    /// Property type
    /// </summary>
    public PropertyTypeDto PropertyType { get; set; } = null!;
    
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
    /// الوصف
    /// Description
    /// </summary>
    public string Description { get; set; } = string.Empty;
    
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
    /// عدد المشاهدات
    /// View count
    /// </summary>
    public int ViewCount { get; set; }
    
    /// <summary>
    /// عدد الحجوزات
    /// BookingDto count
    /// </summary>
    public int BookingCount { get; set; }
    
    /// <summary>
    /// هل في قائمة المفضلات
    /// Is favorite
    /// </summary>
    public bool IsFavorite { get; set; }
    
    /// <summary>
    /// الصور
    /// Images
    /// </summary>
    public List<PropertyImageDto> Images { get; set; } = new();
    
    /// <summary>
    /// وسائل الراحة
    /// Amenities
    /// </summary>
    public List<PropertyAmenityDto> Amenities { get; set; } = new();
    
    /// <summary>
    /// الخدمات
    /// Services
    /// </summary>
    public List<PropertyServiceDto> Services { get; set; } = new();
    
    /// <summary>
    /// السياسات
    /// Policies
    /// </summary>
    public List<PropertyPolicyDto> Policies { get; set; } = new();
    
    /// <summary>
    /// الوحدات المتاحة
    /// Available units
    /// </summary>
    public List<UnitDetailsDto> Units { get; set; } = new();

    /// <summary>
    /// معرف المالك
    /// Owner ID
    /// </summary>
    public Guid OwnerId { get; set; }

    /// <summary>
    /// معرف نوع العقار
    /// Property type ID
    /// </summary>
    public Guid TypeId { get; set; }

    /// <summary>
    /// هل تمت الموافقة عليه
    /// Is approved
    /// </summary>
    public bool IsApproved { get; set; }

    /// <summary>
    /// تاريخ الإنشاء
    /// Created at
    /// </summary>
    public DateTime CreatedAt { get; set; }

    /// <summary>
    /// اسم المالك
    /// Owner name
    /// </summary>
    public string OwnerName { get; set; } = string.Empty;

    /// <summary>
    /// اسم نوع العقار
    /// Property type name
    /// </summary>
    public string TypeName { get; set; } = string.Empty;
}





/// <summary>
/// بيانات خدمة العقار
/// Property service DTO
/// </summary>
public class PropertyServiceDto
{
    /// <summary>
    /// معرف الخدمة
    /// Service ID
    /// </summary>
    public Guid Id { get; set; }
    
    /// <summary>
    /// اسم الخدمة
    /// Service name
    /// </summary>
    public string Name { get; set; } = string.Empty;
    
    /// <summary>
    /// السعر
    /// Price
    /// </summary>
    public decimal Price { get; set; }
    
    /// <summary>
    /// العملة
    /// Currency
    /// </summary>
    public string Currency { get; set; } = string.Empty;
    
    /// <summary>
    /// نموذج التسعير
    /// Pricing model
    /// </summary>
    public string PricingModel { get; set; } = string.Empty;
}


