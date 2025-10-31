using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.Accounting.Commands.Payouts;

namespace YemenBooking.Api.Controllers.Admin
{
    [ApiController]
    [Route("api/admin/[controller]")]
    [Authorize(Roles = "Admin,Accountant,Finance")]
    public class AccountingController : ControllerBase
    {
        private readonly IMediator _mediator;

        public AccountingController(IMediator mediator)
        {
            _mediator = mediator;
        }

        [HttpPost("owner-payouts/process")]
        public async Task<IActionResult> ProcessOwnerPayouts([FromBody] ProcessOwnerPayoutsRequest request)
        {
            var cmd = new ProcessOwnerPayoutsCommand
            {
                OwnerIds = request.OwnerIds?.Where(id => Guid.TryParse(id, out _)).Select(Guid.Parse).ToList() ?? new List<Guid>(),
                MinimumAmountThreshold = request.MinimumAmountThreshold ?? 1000,
                IncludePendingTransactions = request.IncludePendingTransactions ?? false,
                PreviewOnly = request.PreviewOnly ?? false,
                Notes = request.Notes ?? string.Empty
            };

            var result = await _mediator.Send(cmd);
            if (result.Success)
            {
                return Ok(result);
            }
            return BadRequest(result);
        }
    }

    public class ProcessOwnerPayoutsRequest
    {
        public List<string>? OwnerIds { get; set; }
        public decimal? MinimumAmountThreshold { get; set; }
        public bool? IncludePendingTransactions { get; set; }
        public bool? PreviewOnly { get; set; }
        public string? Notes { get; set; }
    }
}
