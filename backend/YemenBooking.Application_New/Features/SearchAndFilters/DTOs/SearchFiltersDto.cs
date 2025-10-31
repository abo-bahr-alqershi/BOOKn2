using System;
using System.Collections.Generic;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.SearchAndFilters.DTOs {
    /// <summary>
    /// DTO لفلاتر البحث المتاحة
    /// Available search filters DTO
    /// </summary>
    public class SearchFiltersDto
    {
        /// <summary>
        /// المدن المتاحة
        /// Available cities
        /// </summary>
        public List<CityFilterDto> Cities { get; set; } = new();

        /// <summary>
        /// أنواع العقارات المتاحة
        /// Available property types
        /// </summary>
        public List<PropertyTypeFilterDto> PropertyTypes { get; set; } = new();

        /// <summary>
        /// نطاق الأسعار
        /// Price range
        /// </summary>
        public PriceRangeDto PriceRange { get; set; } = new();

        /// <summary>
        /// وسائل الراحة المتاحة
        /// Available amenities
        /// </summary>
        public List<AmenityFilterDto> Amenities { get; set; } = new();

        /// <summary>
        /// تقييمات النجوم المتاحة
        /// Available star ratings
        /// </summary>
        public List<int> StarRatings { get; set; } = new();

        /// <summary>
        /// قائمة المدن المتاحة كنصوص بسيطة
        /// Flat list of available cities
        /// </summary>
        public List<string> AvailableCities { get; set; } = new();

        /// <summary>
        /// الحد الأقصى للسعة الاستيعابية للضيوف
        /// Maximum guest capacity across properties
        /// </summary>
        public int MaxGuestCapacity { get; set; } = 0;

        /// <summary>
        /// أنواع الوحدات المتاحة
        /// Available unit types
        /// </summary>
        public List<UnitTypeFilterDto> UnitTypes { get; set; } = new();

        /// <summary>
        /// نطاق المسافة (بالكيلومتر)
        /// Distance range (in kilometers)
        /// </summary>
        public DistanceRangeDto DistanceRange { get; set; } = new();

        /// <summary>
        /// العملات المدعومة
        /// Supported currencies
        /// </summary>
        public List<string> SupportedCurrencies { get; set; } = new();

        /// <summary>
        /// الخدمات المتاحة
        /// Available services
        /// </summary>
        public List<ServiceFilterDto> Services { get; set; } = new();

        /// <summary>
        /// قيم الحقول الديناميكية المتاحة للفلترة
        /// Available dynamic field values for filtering
        /// </summary>
        public List<DynamicFieldValueFilterDto> DynamicFieldValues { get; set; } = new();
    }

    /// <summary>
    /// DTO لفلتر المدينة
    /// City filter DTO
    /// </summary>
    public class CityFilterDto
    {
        /// <summary>
        /// معرف المدينة
        /// City ID
        /// </summary>
        public Guid Id { get; set; }

        /// <summary>
        /// اسم المدينة
        /// City name
        /// </summary>
        public string Name { get; set; } = string.Empty;

        /// <summary>
        /// عدد العقارات المتاحة
        /// Available properties count
        /// </summary>
        public int PropertiesCount { get; set; }
    }

    /// <summary>
    /// DTO لفلتر نوع العقار
    /// Property type filter DTO
    /// </summary>
    public class PropertyTypeFilterDto
    {
        /// <summary>
        /// معرف نوع العقار
        /// Property type ID
        /// </summary>
        public Guid Id { get; set; }

        /// <summary>
        /// اسم نوع العقار
        /// Property type name
        /// </summary>
        public string Name { get; set; } = string.Empty;

        /// <summary>
        /// عدد العقارات المتاحة
        /// Available properties count
        /// </summary>
        public int PropertiesCount { get; set; }
    }



    /// <summary>
    /// DTO لفلتر وسيلة الراحة
    /// Amenity filter DTO
    /// </summary>
    public class AmenityFilterDto
    {
        /// <summary>
        /// معرف وسيلة الراحة
        /// Amenity ID
        /// </summary>
        public Guid Id { get; set; }

        /// <summary>
        /// اسم وسيلة الراحة
        /// Amenity name
        /// </summary>
        public string Name { get; set; } = string.Empty;

        /// <summary>
        /// فئة وسيلة الراحة
        /// Amenity category
        /// </summary>
        public string Category { get; set; } = string.Empty;

        /// <summary>
        /// عدد العقارات التي تحتوي على هذه الوسيلة
        /// PropertyDto count with this amenity
        /// </summary>
        public int PropertiesCount { get; set; }

        /// <summary>
        /// ايقونة وسيلة الراحة
        /// Amenity icon
        /// </summary>
        public string Icon { get; set; } = string.Empty;
    }

    /// <summary>
    /// DTO لفلتر نوع الوحدة
    /// Unit type filter DTO
    /// </summary>
    public class UnitTypeFilterDto
    {
        /// <summary>
        /// معرف نوع الوحدة
        /// Unit type ID
        /// </summary>
        public Guid Id { get; set; }

        /// <summary>
        /// اسم نوع الوحدة
        /// Unit type name
        /// </summary>
        public string Name { get; set; } = string.Empty;

        /// <summary>
        /// عدد الوحدات المتاحة
        /// Available units count
        /// </summary>
        public int UnitsCount { get; set; }

        /// <summary>
        /// هل يتطلب وجود بالغين
        /// Whether it requires adults
        /// </summary>
        public bool IsHasAdults { get; set; } = false;

        /// <summary>
        /// هل يتطلب وجود أطفال
        /// Whether it requires children
        /// </summary>
        public bool IsHasChildren { get; set; } = false;

        /// <summary>
        /// هل يتطلب وجود أكثر من يوم
        /// Whether it requires multiple days
        /// </summary>
        public bool IsMultiDays { get; set; } = false;

        /// <summary>
        /// هل يتطلب تحديد الساعة
        /// Whether it requires determining the hour
        /// </summary>
        public bool IsRequiredToDetermineTheHour { get; set; } = false;
    }

    /// <summary>
    /// DTO لنطاق المسافة
    /// Distance range DTO
    /// </summary>
    public class DistanceRangeDto
    {
        /// <summary>
        /// أقل مسافة (بالكيلومتر)
        /// Minimum distance (in kilometers)
        /// </summary>
        public double MinDistance { get; set; } = 0;

        /// <summary>
        /// أقصى مسافة (بالكيلومتر)
        /// Maximum distance (in kilometers)
        /// </summary>
        public double MaxDistance { get; set; } = 50;
    }

    /// <summary>
    /// DTO لفلتر الخدمة
    /// Service filter DTO
    /// </summary>
    public class ServiceFilterDto
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
        /// عدد العقارات التى توفر هذه الخدمة
        /// Available properties count that provide this service
        /// </summary>
        public int PropertiesCount { get; set; }

        /// <summary>
        /// ايقونة الخدمة
        /// Service icon
        /// </summary>
        public string Icon { get; set; } = string.Empty;
    }

    /// <summary>
    /// DTO لفلتر قيمة الحقل الديناميكى
    /// Dynamic field value filter DTO
    /// </summary>
    public class DynamicFieldValueFilterDto
    {
        /// <summary>
        /// اسم الحقل الديناميكى
        /// Dynamic field name
        /// </summary>
        public string FieldName { get; set; } = string.Empty;

        /// <summary>
        /// القيمة
        /// Value of the field
        /// </summary>
        public string Value { get; set; } = string.Empty;

        /// <summary>
        /// عدد الوحدات أو العقارات المطابقة للقيمة
        /// Count of matching units/properties
        /// </summary>
        public int Count { get; set; }
    }
}
