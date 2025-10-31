using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Units.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.PropertyTypes.Queries.GetAllUnitTypes
{
    /// <summary>
    /// استعلام للحصول على جميع أنواع الوحدات
    /// Query to get all unit types
    /// </summary>
    public class GetAllUnitTypesQuery : IRequest<PaginatedResult<UnitTypeDto>>
    {
        /// <summary>
        /// رقم الصفحة
        /// Page number
        /// </summary>
        public int PageNumber { get; set; } = 1;

        /// <summary>
        /// حجم الصفحة
        /// Page size
        /// </summary>
        public int PageSize { get; set; } = 10;

        /// <summary>
        /// مصطلح البحث (اختياري)
        /// Search term (optional)
        /// </summary>
        public string? SearchTerm { get; set; }
    }
} 