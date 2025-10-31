using MediatR;
using System.Collections.Generic;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Properties.DTOs;

namespace YemenBooking.Application.Features.PropertyTypes.Queries.GetAllPropertyTypes
{
    /// <summary>
    /// استعلام للحصول على جميع أنواع الكيانات
    /// Query to get all property types
    /// </summary>
    public class GetAllPropertyTypesQuery : IRequest<PaginatedResult<PropertyTypeDto>>
    {
        /// <summary>
        /// رقم الصفحة
        /// </summary>
        public int PageNumber { get; set; } = 1;

        /// <summary>
        /// حجم الصفحة
        /// </summary>
        public int PageSize { get; set; } = 10;
    }
} 