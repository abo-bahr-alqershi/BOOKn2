using System;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Properties.Queries.GetDownloadUrl
{
    /// <summary>
    /// استعلام للحصول على رابط تنزيل مؤقت لصورة حسب الحجم
    /// Query to get a temporary download URL for an image by size
    /// </summary>
    public class GetDownloadUrlQuery : IRequest<ResultDto<string>>
    {
        /// <summary>
        /// معرف الصورة
        /// Image unique identifier
        /// </summary>
        public Guid ImageId { get; set; }

        /// <summary>
        /// حجم التنزيل المطلوب (مثل small, medium, hd)
        /// Requested download size (e.g., small, medium, hd)
        /// </summary>
        public string? Size { get; set; }
    }
} 