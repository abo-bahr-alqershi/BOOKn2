using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Users;
using YemenBooking.Application.Features.Users.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Users.Queries.GetCurrentUser;

/// <summary>
/// استعلام للحصول على بيانات المستخدم الحالي
/// Query to get current logged-in user data
/// </summary>
public class GetCurrentUserQuery : IRequest<ResultDto<UserDto>>
{
} 