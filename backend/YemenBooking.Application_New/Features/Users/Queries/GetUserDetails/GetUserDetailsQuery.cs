using System;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Users.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Users.Queries.GetUserDetails
{
    /// <summary>استعلام جلب تفاصيل المستخدم</summary>
    public class GetUserDetailsQuery : IRequest<ResultDto<UserDetailsDto>>
    {
        /// <summary>معرف المستخدم</summary>
        public Guid UserId { get; set; }
    }
} 