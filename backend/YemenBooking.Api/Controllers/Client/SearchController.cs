using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.SearchAndFilters.Queries.SearchSuggestions;
using YemenBooking.Application.Common.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace YemenBooking.Api.Controllers.Client
{
    [ApiController]
    [Route("api/client/[controller]")]
    [AllowAnonymous]
    public class SearchController : BaseClientController
    {
        public SearchController(IMediator mediator) : base(mediator) { }

        /// <summary>
        /// اقتراحات البحث بناءً على سجل البحث السابق
        /// </summary>
        /// <param name="query">استعلام الاقتراح</param>
        /// <returns>قائمة اقتراحات نصية</returns>
        [HttpGet("suggestions")]
        public async Task<ActionResult<ResultDto<List<string>>>> GetSearchSuggestions([FromQuery] GetSearchSuggestionsQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }
    }
}