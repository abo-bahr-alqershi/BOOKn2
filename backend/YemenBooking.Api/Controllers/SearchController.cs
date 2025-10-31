using Microsoft.AspNetCore.Mvc;
using MediatR;
using YemenBooking.Application.Features.Properties.Queries.SearchProperties;
using YemenBooking.Application.Features.SearchAndFilters.DTOs;
using YemenBooking.Application.Common.Models;
using Microsoft.AspNetCore.Authorization;

namespace YemenBooking.Api.Controllers;

/// <summary>
/// وحدة تحكم البحث
/// Search controller
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class SearchController : ControllerBase
{
    private readonly IMediator _mediator;
    private readonly ILogger<SearchController> _logger;

    public SearchController(
        IMediator mediator,
        ILogger<SearchController> logger)
    {
        _mediator = mediator;
        _logger = logger;
    }

    /// <summary>
    /// البحث في العقارات عبر معالج الاستعلام
    /// Search properties via query handler
    /// </summary>
    [HttpPost("properties")]
    public async Task<ActionResult<ResultDto<SearchPropertiesResponse>>> SearchProperties(
        [FromBody] SearchPropertiesQuery query,
        CancellationToken cancellationToken)
    {
        try
        {
            var result = await _mediator.Send(query, cancellationToken);
            if (!result.IsSuccess)
                return BadRequest(result);
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في البحث عن العقارات عبر المعالج");
            return BadRequest(ResultDto<SearchPropertiesResponse>.Failed("حدث خطأ أثناء البحث"));
        }
    }
}