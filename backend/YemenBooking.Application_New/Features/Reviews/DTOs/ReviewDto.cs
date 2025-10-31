using System;
using System.Collections.Generic;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Properties.DTOs;

namespace YemenBooking.Application.Features.Reviews.DTOs {
    /// <summary>
    /// DTO لبيانات المراجعة
    /// DTO for review data
    /// </summary>
    public class ReviewDto
    {
        /// <summary>
        /// معرف المراجعة
        /// Review identifier
        /// </summary>
        public Guid Id { get; set; }

        /// <summary>
        /// معرف الحجز
        /// BookingDto identifier
        /// </summary>
        public Guid BookingId { get; set; }

        /// <summary>
        /// تقييم النظافة
        /// Cleanliness rating
        /// </summary>
        public int Cleanliness { get; set; }

        /// <summary>
        /// تقييم الخدمة
        /// Service rating
        /// </summary>
        public int Service { get; set; }

        /// <summary>
        /// تقييم الموقع
        /// Location rating
        /// </summary>
        public int Location { get; set; }

        /// <summary>
        /// تقييم القيمة
        /// Value rating
        /// </summary>
        public int Value { get; set; }

        /// <summary>
        /// متوسط التقييم
        /// Average rating
        /// </summary>
        public decimal AverageRating { get; set; }

        /// <summary>
        /// نص رد الإدارة على المراجعة
        /// Response text from management
        /// </summary>
        public string? ResponseText { get; set; }

        /// <summary>
        /// تاريخ الرد
        /// Response date
        /// </summary>
        public DateTime? ResponseDate { get; set; }
        
        /// <summary>
        /// هل المراجعة معتمدة
        /// </summary>
        public bool IsApproved { get; set; }
        
        /// <summary>
        /// هل المراجعة بانتظار المراجعة
        /// </summary>
        public bool IsPending { get; set; }
        
        /// <summary>
        /// معرف من قام بالرد
        /// </summary>
        public Guid? RespondedBy { get; set; }
        
        /// <summary>
        /// تعليق المراجعة
        /// Review comment
        /// </summary>
        public string Comment { get; set; }

        /// <summary>
        /// تاريخ إنشاء المراجعة
        /// Review creation date
        /// </summary>
        public DateTime CreatedAt { get; set; }

        /// <summary>
        /// صور التقييم
        /// Review images
        /// </summary>
        public List<ReviewImageDto> Images { get; set; } = new List<ReviewImageDto>();
       
        /// <summary>
        /// اسم الكيان المرتبط بالتقييم
        /// Property name
        /// </summary>
        public string PropertyName { get; set; }
       
        /// <summary>
        /// اسم المستخدم الذي قام بالتقييم
        /// Reviewer user name
        /// </summary>
        public string UserName { get; set; }
    }
} 