using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Users.Queries.GetUserById;

/// <summary>
/// استعلام للحصول على بيانات مستخدم باستخدام المعرف
/// Query to get user data by ID
/// </summary>
public class GetUserByIdQuery : IRequest<ResultDto<object>>
{
    /// <summary>
    /// معرف المستخدم
    /// User ID
    /// </summary>
    public Guid UserId { get; set; }
} 