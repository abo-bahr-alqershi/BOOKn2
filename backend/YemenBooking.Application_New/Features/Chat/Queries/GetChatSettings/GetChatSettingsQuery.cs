using YemenBooking.Application.Features.Chat.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Chat.Queries.GetChatSettings
{
    using MediatR;
    using YemenBooking.Application.Common.Models;

    /// <summary>
    /// استعلام لجلب إعدادات الشات الخاصة بالمستخدم الحالي
    /// Query to get chat settings for the current user
    /// </summary>
    public class GetChatSettingsQuery : IRequest<ResultDto<ChatSettingsDto>>
    {
    }
} 