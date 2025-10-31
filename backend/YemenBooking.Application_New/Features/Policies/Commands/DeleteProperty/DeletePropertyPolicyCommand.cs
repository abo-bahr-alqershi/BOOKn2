using System;
using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Policies.Commands.DeleteProperty;

/// <summary>
/// أمر لحذف سياسة كيان
/// Command to delete a property policy
/// </summary>
public class DeletePropertyPolicyCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف السياسة
    /// Policy identifier
    /// </summary>
    public Guid PolicyId { get; set; }
} 