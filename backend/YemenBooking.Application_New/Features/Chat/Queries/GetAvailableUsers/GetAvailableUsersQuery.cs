using YemenBooking.Application.Features.Users.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Chat.Queries.GetAvailableUsers
{
    using System;
    using System.Collections.Generic;
    using MediatR;
    using YemenBooking.Application.Common.Models;
    using YemenBooking.Application.Features.Users;

    /// <summary>
    /// استعلام لجلب قائمة المستخدمين المتاحين للمحادثة
    /// Query to get available users for chat
    /// </summary>
    public class GetAvailableUsersQuery : IRequest<ResultDto<IEnumerable<ChatUserDto>>>
    {
        /// <summary>نوع المستخدم (admin, property_owner, customer)</summary>
        public string? UserType { get; set; }

        /// <summary>معرّف الفندق (لـproperty_owner)</summary>
        public Guid? PropertyId { get; set; }
    }
} 