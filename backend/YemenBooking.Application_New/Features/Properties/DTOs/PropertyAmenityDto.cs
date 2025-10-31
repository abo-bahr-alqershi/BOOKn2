using System;
using YemenBooking.Application.Features.Amenities.DTOs;

namespace YemenBooking.Application.Features.Properties.DTOs
{
    /// <summary>
    /// مرفق الكيان
    /// </summary>
    public class PropertyAmenityDto
    {
        /// <summary>
        /// معرف المرفق
        /// </summary>
        public Guid AmenityId { get; set; }

        /// <summary>
        /// هل متاح
        /// </summary>
        public bool IsAvailable { get; set; } = true;

        /// <summary>
        /// التكلفة الإضافية
        /// </summary>
        public decimal? ExtraCost { get; set; }

        /// <summary>
        /// الوصف
        /// </summary>
        public string? Description { get; set; }

        /// <summary>
        /// المعرف العام للمرفق (لاستخدام موحد عبر الأنظمة)
        /// Global unique identifier for the amenity (used by handlers)
        /// </summary>
        public Guid Id { get; set; }

        /// <summary>
        /// اسم المرفق (يستخدم في واجهة العميل)
        /// Amenity name
        /// </summary>
        public string? Name { get; set; }

        /// <summary>
        /// رابط أيقونة المرفق
        /// Icon URL of the amenity
        /// </summary>
        public string? IconUrl { get; set; }

        /// <summary>
        /// فئة المرفق (خدمة، أمان، ترفيه، ...)
        /// Amenity category (Service, Safety, Entertainment, ...)
        /// </summary>
        public string? Category { get; set; }
    }
} 