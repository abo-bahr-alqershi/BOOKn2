using System.Threading.Tasks;
using MediatR;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.SearchAndFilters.Commands.Search;
using YemenBooking.Application.Features.Units.Queries.SearchUnits;

namespace YemenBooking.Api.Controllers.Common
{
    /// <summary>
    /// متحكم بنقاط نهاية البحث المشتركة
    /// Controller for shared search endpoints
    /// </summary>
    public class SearchController : BaseCommonController
    {
        public SearchController(IMediator mediator) : base(mediator) { }

        /// <summary>
        /// البحث في الكيانات بناءً على المعايير الديناميكية والفرز والتصفح
        /// Search properties with dynamic filters, sorting, and pagination
        /// </summary>
        [HttpPost("properties")]
        public async Task<IActionResult> SearchProperties([FromBody] SearchPropertiesCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// البحث في الوحدات بناءً على المعايير الديناميكية والفرز والتصفح
        /// Search units with dynamic filters, sorting, and pagination
        /// </summary>
        [HttpPost("units")]
        public async Task<IActionResult> SearchUnits([FromBody] SearchUnitsQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }
    }
} 