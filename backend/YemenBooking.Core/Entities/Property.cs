namespace YemenBooking.Core.Entities;

using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

/// <summary>
/// كيان الكيان
/// Property entity
/// </summary>
[Display(Name = "كيان الكيان")]
public class Property : BaseEntity<Guid>
{
    /// <summary>
    /// معرف المالك
    /// Owner identifier
    /// </summary>
    [Display(Name = "معرف المالك")]
    public Guid OwnerId { get; set; }
    
    /// <summary>
    /// معرف نوع الكيان
    /// Property type identifier
    /// </summary>
    [Display(Name = "معرف نوع الكيان")]
    public Guid TypeId { get; set; }
    
    /// <summary>
    /// اسم الكيان
    /// Property name
    /// </summary>
    [Display(Name = "اسم الكيان")]
    public string Name { get; set; }
    
    /// <summary>
    /// وصف قصير للكيان
    /// Short description of the property
    /// </summary>
    [Display(Name = "وصف قصير للكيان")]
    public string? ShortDescription { get; set; }
    
    
    
    /// <summary>
    /// عنوان الكيان
    /// Property address
    /// </summary>
    [Display(Name = "عنوان الكيان")]
    public string Address { get; set; }
    
    /// <summary>
    /// المدينة
    /// City
    /// </summary>
    [Display(Name = "المدينة")]
    public string City { get; set; }
    
    /// <summary>
    /// خط العرض
    /// Latitude
    /// </summary>
    [Display(Name = "خط العرض")]
    public decimal Latitude { get; set; }
    
    /// <summary>
    /// خط الطول
    /// Longitude
    /// </summary>
    [Display(Name = "خط الطول")]
    public decimal Longitude { get; set; }
    
    /// <summary>
    /// تصنيف النجوم
    /// Star rating
    /// </summary>
    [Display(Name = "تصنيف النجوم")]
    public int StarRating { get; set; }
    
    /// <summary>
    /// وصف الكيان
    /// Property description
    /// </summary>
    [Display(Name = "وصف الكيان")]
    public string Description { get; set; }
    
    /// <summary>
    /// حالة الموافقة على الكيان
    /// Property approval status
    /// </summary>
    [Display(Name = "حالة الموافقة على الكيان")]
    public bool IsApproved { get; set; } = true;
    
    /// <summary>
    /// تاريخ إنشاء الكيان
    /// Property creation date
    /// </summary>
    [Display(Name = "تاريخ إنشاء الكيان")]
    public DateTime CreatedAt { get; set; }

    /// <summary>
    /// عدد مرات المشاهدة
    /// View count
    /// </summary>
    [Display(Name = "عدد مرات المشاهدة")]
    public int ViewCount { get; set; } = 0;

    /// <summary>
    /// عدد الحجوزات
    /// Booking count
    /// </summary>
    [Display(Name = "عدد الحجوزات")]
    public int BookingCount { get; set; } = 0;
    
    /// <summary>
    /// متوسط التقييم
    /// Average rating of the property
    /// </summary>
    [Display(Name = "متوسط التقييم")]
    public decimal AverageRating { get; set; } = 0m;

    /// <summary>
    /// العملة
    /// Currency
    /// </summary>
    [Display(Name = "العملة")]
    public string Currency { get; set; }
    
    /// <summary>
    /// هل العقار مميز لعرضه في الواجهة
    /// Whether property is featured to show in listing
    /// </summary>
    public bool IsFeatured { get; set; } = false;
    
    /// <summary>
    /// المالك المرتبط بالكيان
    /// Owner associated with the property
    /// </summary>
    [Display(Name = "المالك المرتبط بالكيان")]
    public virtual User Owner { get; set; }
    
    /// <summary>
    /// نوع الكيان المرتبط
    /// Property type associated
    /// </summary>
    [Display(Name = "نوع الكيان المرتبط")]
    public virtual PropertyType PropertyType { get; set; }
    
    /// <summary>
    /// الملاحة إلى كيان المدينة
    /// Navigation to City entity
    /// </summary>
    public virtual City? CityRef { get; set; }
    
    /// <summary>
    /// الوحدات المرتبطة بالكيان
    /// Units associated with the property
    /// </summary>
    [Display(Name = "الوحدات المرتبطة بالكيان")]
    public virtual ICollection<Unit> Units { get; set; } = new List<Unit>();
    
    /// <summary>
    /// الخدمات المرتبطة بالكيان
    /// Services associated with the property
    /// </summary>
    [Display(Name = "الخدمات المرتبطة بالكيان")]
    public virtual ICollection<PropertyService> Services { get; set; } = new List<PropertyService>();
    
    /// <summary>
    /// السياسات المرتبطة بالكيان
    /// Policies associated with the property
    /// </summary>
    [Display(Name = "السياسات المرتبطة بالكيان")]
    public virtual ICollection<PropertyPolicy> Policies { get; set; } = new List<PropertyPolicy>();
    
    /// <summary>
    /// المراجعات المرتبطة بالكيان
    /// Reviews associated with the property
    /// </summary>
    [Display(Name = "المراجعات المرتبطة بالكيان")]
    public virtual ICollection<Review> Reviews { get; set; } = new List<Review>();
    
    /// <summary>
    /// الموظفون المرتبطون بالكيان
    /// Staff associated with the property
    /// </summary>
    [Display(Name = "الموظفون المرتبطون بالكيان")]
    public virtual ICollection<Staff> Staff { get; set; } = new List<Staff>();
    
    /// <summary>
    /// الصور المرتبطة بالكيان
    /// Images associated with the property
    /// </summary>
    [Display(Name = "الصور المرتبطة بالكيان")]
    public virtual ICollection<PropertyImage> Images { get; set; } = new List<PropertyImage>();
    
    /// <summary>
    /// الوسائل المرتبطة بالكيان
    /// Amenities associated with the property
    /// </summary>
    [Display(Name = "الوسائل المرتبطة بالكيان")]
    public virtual ICollection<PropertyAmenity> Amenities { get; set; } = new List<PropertyAmenity>();

    /// <summary>
    /// البلاغات المرتبطة بالكيان
    /// Reports associated with the property
    /// </summary>
    [Display(Name = "البلاغات المرتبطة بالكيان")]
    public virtual ICollection<Report> Reports { get; set; } = new List<Report>();

    // Legacy SectionItems removed in favor of rich entities PropertyInSection and UnitInSection

    /// <summary>
    /// سجلات الغنية لعقار في الأقسام
    /// Rich section-property records
    /// </summary>
    public virtual ICollection<PropertyInSection> PropertyInSections { get; set; } = new List<PropertyInSection>();

    /// <summary>
    /// سجلات الغنية لوحدات في الأقسام التابعة لهذا العقار
    /// Rich section-unit records for this property's units
    /// </summary>
    public virtual ICollection<UnitInSection> UnitInSections { get; set; } = new List<UnitInSection>();

} 