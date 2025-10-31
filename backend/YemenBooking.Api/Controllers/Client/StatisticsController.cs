using MediatR;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.Users.Queries.GetUserStatisticsStatistics;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Users.DTOs;

namespace YemenBooking.Api.Controllers.Client
{
    /// <summary>
    /// كونترولر الإحصائيات للعملاء
    /// Client Statistics Controller
    /// </summary>
    public class StatisticsController : BaseClientController
    {
        public StatisticsController(IMediator mediator) : base(mediator)
        {
        }

        /// <summary>
        /// الحصول على إحصائيات المستخدم
        /// Get user statistics
        /// </summary>
        /// <param name="query">معايير الإحصائيات</param>
        /// <returns>إحصائيات المستخدم</returns>
        [HttpGet("user")]
        public async Task<ActionResult<ResultDto<UserStatisticsDto>>> GetUserStatistics([FromQuery] GetUserStatisticsQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }
    }
}
