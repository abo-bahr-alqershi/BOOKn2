using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.SearchAndFilters.Queries.FilterAnalytics;
using YemenBooking.Application.Features.Analytics.DTOs;

namespace YemenBooking.Api.Controllers.Admin
{
    /// <summary>
    /// متحكم بنقاط نهاية احصائيات الفلاتر الديناميكية للوحدات
    /// Controller for unit dynamic filter analytics endpoints
    /// </summary>
    [Route("api/admin/search-analytics/unit-dynamic-filters")]
    [ApiController]
    [Authorize(Roles = "Admin")]
    public class SearchFiltersAnalyticsController : ControllerBase
    {
        private readonly IMediator _mediator;

        public SearchFiltersAnalyticsController(IMediator mediator)
        {
            _mediator = mediator;
        }

        /// <summary>
        /// جلب احصائيات الفلاتر الديناميكية للوحدات
        /// Get analytics for unit dynamic filters
        /// </summary>
        [HttpGet]
        public async Task<ActionResult<ResultDto<List<FieldFilterAnalyticsDto>>>> GetUnitDynamicFilterAnalytics(
            [FromQuery] GetUnitDynamicFilterAnalyticsQuery query,
            CancellationToken cancellationToken)
        {
            var result = await _mediator.Send(query, cancellationToken);
            return Ok(result);
        }
    }
} 