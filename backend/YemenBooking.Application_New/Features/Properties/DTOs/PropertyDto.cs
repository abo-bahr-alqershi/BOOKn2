using System;
using System.Collections.Generic;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Properties.DTOs;

namespace YemenBooking.Application.Features.Properties.DTOs
{
    /// <summary>
    /// DTO لبيانات الكيان
    /// DTO for property data
    /// </summary>
    public class PropertyDto
    {
        /// <summary>
        /// المعرف الفريد للكيان
        /// Property unique identifier
        /// </summary>
        public Guid Id { get; set; }

        /// <summary>
        /// معرف المالك
        /// Owner identifier
        /// </summary>
        public Guid OwnerId { get; set; }

        /// <summary>
        /// معرف نوع الكيان
        /// Property type identifier
        /// </summary>
        public Guid TypeId { get; set; }

        /// <summary>
        /// اسم الكيان
        /// Property name
        /// </summary>
        public string Name { get; set; }

        /// <summary>
        /// العنوان الكامل للكيان
        /// Full address of the property
        /// </summary>
        public string Address { get; set; }

        /// <summary>
        /// المدينة
        /// City
        /// </summary>
        public string City { get; set; }

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
        /// تقييم النجوم
        /// Star rating
        /// </summary>
        public int StarRating { get; set; }

        /// <summary>
        /// وصف الكيان
        /// Property description
        /// </summary>
        public string Description { get; set; }

        /// <summary>
        /// حالة الموافقة على الكيان
        /// Is approved status
        /// </summary>
        public bool IsApproved { get; set; }

        /// <summary>
        /// تاريخ إنشاء الكيان
        /// Creation date
        /// </summary>
        public DateTime CreatedAt { get; set; }

        /// <summary>
        /// اسم المالك
        /// Name of the owner
        /// </summary>
        public string OwnerName { get; set; }

        /// <summary>
        /// اسم نوع الكيان
        /// Property type name
        /// </summary>
        public string TypeName { get; set; }
        /// <summary>
        /// صور الكيان
        /// Property images
        /// </summary>
        public IEnumerable<PropertyImageDto> Images { get; set; } = new List<PropertyImageDto>();

        /// <summary>
        /// المسافة من الموقع الحالي بالكيلومترات
        /// Distance from current location in kilometers
        /// </summary>
        public double? DistanceKm { get; set; }

        /// <summary>
        /// متوسط التقييم
        /// Average rating of the property
        /// </summary>
        public decimal AverageRating { get; set; }
    }
}
 