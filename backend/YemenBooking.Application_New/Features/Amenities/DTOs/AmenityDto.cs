using System;

namespace YemenBooking.Application.Features.Amenities.DTOs {
    /// <summary>
    /// DTO لبيانات وسيلة الراحة
    /// Amenity data DTO
    /// </summary>
    public class AmenityDto
    {
        /// <summary>
        /// معرف الوسيلة
        /// Amenity ID
        /// </summary>
        public Guid Id { get; set; }
        
        /// <summary>
        /// اسم الوسيلة
        /// Amenity name
        /// </summary>
        public string Name { get; set; } = string.Empty;
        
        /// <summary>
        /// وصف الوسيلة
        /// Amenity description
        /// </summary>
        public string Description { get; set; } = string.Empty;
        
        /// <summary>
        /// رابط أيقونة الوسيلة
        /// Amenity icon URL
        /// </summary>
        public string IconUrl { get; set; } = string.Empty;
        
        /// <summary>
        /// فئة الوسيلة
        /// Amenity category
        /// </summary>
        public string Category { get; set; } = string.Empty;

        /// <summary>
        /// أيقونة المرفق
        /// Amenity icon
        /// </summary>
        public string Icon { get; set; } = string.Empty;

        /// <summary>
        /// هل الوسيلة نشطة
        /// Whether amenity is active
        /// </summary>
        public bool IsActive { get; set; } = true;

        /// <summary>
        /// ترتيب العرض
        /// Display order
        /// </summary>
        public int DisplayOrder { get; set; }

        /// <summary>
        /// تاريخ الإنشاء
        /// Creation date
        /// </summary>
        public DateTime CreatedAt { get; set; }
        
        /// <summary>
        /// تاريخ آخر تحديث
        /// Last update date
        /// </summary>
        public DateTime? UpdatedAt { get; set; }
        
    }
}
