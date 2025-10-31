using System;
using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Policies.Commands.ManagePolicies
{
    /// <summary>
    /// أمر لتفعيل/تعطيل السياسة
    /// Command to toggle policy status
    /// </summary>
    public class TogglePolicyStatusCommand : IRequest<ResultDto<bool>>
    {
        /// <summary>
        /// معرف السياسة
        /// Policy identifier
        /// </summary>
        public Guid PolicyId { get; set; }
    }
}
