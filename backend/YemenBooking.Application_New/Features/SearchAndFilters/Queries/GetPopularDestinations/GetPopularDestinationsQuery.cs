using MediatR;
using System.Collections.Generic;
using YemenBooking.Application.Common.Models;
// using YemenBooking.Application.Features.Statistics; // مؤقتاً حتى يتم إنشاء هذا المجلد
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.SearchAndFilters.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.SearchAndFilters.Queries.GetPopularDestinations;

/// <summary>
/// استعلام الحصول على الوجهات الشعبية
/// Query to get popular destinations
/// </summary>
public class GetPopularDestinationsQuery : IRequest<ResultDto<List<PopularDestinationDto>>>
{
    /// <summary>
    /// عدد الوجهات المطلوبة
    /// </summary>
    public int Count { get; set; } = 10;
}