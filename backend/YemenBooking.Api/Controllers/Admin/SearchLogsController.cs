using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.SearchAndFilters.Queries.SearchLogs;
using YemenBooking.Application.Features.SearchAndFilters.DTOs;

namespace YemenBooking.Api.Controllers.Admin
{
    [Route("api/admin/search-logs")]
    [ApiController]
    [Authorize(Roles = "Admin")]
    public class SearchLogsController : ControllerBase
    {
        private readonly IMediator _mediator;

        public SearchLogsController(IMediator mediator)
        {
            _mediator = mediator;
        }

        /// <summary>
        /// جلب سجلات البحث مع الفلترة والصفحات
        /// Get search logs with filters and pagination
        /// </summary>
        [HttpGet]
        public async Task<ActionResult<PaginatedResult<SearchLogDto>>> GetSearchLogs([FromQuery] GetSearchLogsQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }
    }
} 