using System;
using System.Collections.Generic;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Properties.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Analytics.Queries {
    /// <summary>
    /// استعلام للحصول على أفضل الكيانات أداءً بناءً على عدد الحجوزات
    /// Query to retrieve top performing properties based on booking count
    /// </summary>
    public class GetTopPerformingPropertiesQuery : IRequest<IEnumerable<YemenBooking.Application.Features.Properties.DTOs.PropertyDto>>
    {
        /// <summary>
        /// عدد الكيانات المطلوب جلبها
        /// Number of top properties to retrieve
        /// </summary>
        public int Count { get; set; }

        public GetTopPerformingPropertiesQuery(int count)
        {
            Count = count;
        }
    }
} 