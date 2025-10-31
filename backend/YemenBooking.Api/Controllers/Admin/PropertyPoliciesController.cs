using System;
using System.Threading.Tasks;
using MediatR;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using YemenBooking.Application.Features.Policies.Commands.ManagePolicies;
using YemenBooking.Application.Features.Policies.Commands.CreateProperty;
using YemenBooking.Application.Features.Policies.Commands.UpdateProperty;
using YemenBooking.Application.Features.Policies.Commands.DeleteProperty;
using YemenBooking.Application.Features.Policies.Queries.GetPropertyPolicies;
using YemenBooking.Application.Features.Policies.Queries.GetAllPolicies;
using YemenBooking.Application.Features.Policies.Queries.GetPoliciesByType;
using YemenBooking.Application.Features.Policies.Queries.GetPolicyStats;
using YemenBooking.Application.Features.Policies.Queries.GetPolicyById;

namespace YemenBooking.Api.Controllers.Admin
{
    /// <summary>
    /// متحكم بسياسات الكيانات للمدراء
    /// Controller for managing property policies by admins
    /// </summary>
    [ApiController]
    [Route("api/admin/[controller]")]
    [Authorize(Roles = "Admin,Owner")]
    public class PropertyPoliciesController : ControllerBase
    {
        private readonly IMediator _mediator;

        public PropertyPoliciesController(IMediator mediator)
        {
            _mediator = mediator;
        }

        /// <summary>
        /// إنشاء سياسة جديدة للكيان
        /// Create a new property policy
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> CreatePropertyPolicy([FromBody] CreatePropertyPolicyCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// تحديث سياسة للكيان
        /// Update an existing property policy
        /// </summary>
        [HttpPut("{policyId}")]
        public async Task<IActionResult> UpdatePropertyPolicy(Guid policyId, [FromBody] UpdatePropertyPolicyCommand command)
        {
            command.PolicyId = policyId;
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// حذف سياسة للكيان
        /// Delete a property policy
        /// </summary>
        [HttpDelete("{policyId}")]
        public async Task<IActionResult> DeletePropertyPolicy(Guid policyId)
        {
            var command = new DeletePropertyPolicyCommand { PolicyId = policyId };
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// جلب جميع سياسات كيان معين
        /// Get all property policies
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetPropertyPolicies([FromQuery] GetPropertyPoliciesQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// جلب سياسة معينة حسب المعرف
        /// Get a property policy by ID
        /// </summary>
        [HttpGet("{policyId}")]
        public async Task<IActionResult> GetPolicyById(Guid policyId)
        {
            var query = new GetPolicyByIdQuery { PolicyId = policyId };
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// جلب السياسات حسب النوع مع الصفحات
        /// Get policies by type with pagination
        /// </summary>
        [HttpGet("by-type")]
        public async Task<IActionResult> GetPoliciesByType([FromQuery] GetPoliciesByTypeQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// جلب جميع السياسات مع الصفحات
        /// Get all policies with pagination
        /// </summary>
        [HttpGet("all")]
        public async Task<IActionResult> GetAllPolicies([FromQuery] GetAllPoliciesQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// تفعيل/تعطيل السياسة
        /// Toggle policy status
        /// </summary>
        [HttpPatch("{policyId}/toggle-status")]
        public async Task<IActionResult> TogglePolicyStatus(Guid policyId)
        {
            var command = new TogglePolicyStatusCommand { PolicyId = policyId };
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// جلب إحصائيات السياسات
        /// Get policy statistics
        /// </summary>
        [HttpGet("stats")]
        public async Task<IActionResult> GetPolicyStats([FromQuery] GetPolicyStatsQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }
    }
} 