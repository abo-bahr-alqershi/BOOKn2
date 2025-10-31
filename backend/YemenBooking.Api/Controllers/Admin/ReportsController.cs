using System;
using System.Threading.Tasks;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.Reports.Commands.ManageReports;
using YemenBooking.Application.Features.Reports.Queries.GetAllReports;
using YemenBooking.Application.Features.Reports.Queries.GetReportsByProperty;
using YemenBooking.Application.Features.Reports.Queries.GetReportsByReportedUser;
using YemenBooking.Application.Features.Reports.Queries.GetReportStats;

namespace YemenBooking.Api.Controllers.Admin
{
    /// <summary>
    /// متحكم بالبلاغات للمدراء
    /// Controller for report management by admins (Reports as complaints)
    /// </summary>
    public class ReportsController : BaseAdminController
    {
        public ReportsController(IMediator mediator) : base(mediator) { }

        /// <summary>
        /// إنشاء بلاغ جديد
        /// Create a new report
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> CreateReport([FromBody] CreateReportCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// تحديث بلاغ
        /// Update an existing report
        /// </summary>
        [HttpPut("{reportId}")]
        public async Task<IActionResult> UpdateReport(Guid reportId, [FromBody] UpdateReportCommand command)
        {
            command.Id = reportId;
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// حذف بلاغ
        /// Delete a report
        /// </summary>
        [HttpDelete("{reportId}")]
        public async Task<IActionResult> DeleteReport(Guid reportId)
        {
            var command = new DeleteReportCommand { Id = reportId };
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// جلب جميع البلاغات
        /// Get all reports with pagination
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetAllReports([FromQuery] GetAllReportsQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// جلب البلاغات حسب كيان
        /// Get reports by property
        /// </summary>
        [HttpGet("property/{propertyId}")]
        public async Task<IActionResult> GetReportsByProperty(Guid propertyId, [FromQuery] GetReportsByPropertyQuery query)
        {
            query.PropertyId = propertyId;
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// جلب البلاغات حسب المستخدم المبلّغ عنه
        /// Get reports by reported user
        /// </summary>
        [HttpGet("reported-user/{reportedUserId}")]
        public async Task<IActionResult> GetReportsByReportedUser(Guid reportedUserId, [FromQuery] GetReportsByReportedUserQuery query)
        {
            query.UserId = reportedUserId;
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// جلب إحصائيات البلاغات
        /// Get report analytics and statistics
        /// </summary>
        [HttpGet("stats")]
        public async Task<IActionResult> GetReportStats()
        {
            var result = await _mediator.Send(new GetReportStatsQuery());
            return Ok(result);
        }
    }
} 