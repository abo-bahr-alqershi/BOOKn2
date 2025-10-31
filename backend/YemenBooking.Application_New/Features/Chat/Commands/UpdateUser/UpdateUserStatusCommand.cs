using System.Text.Json.Serialization;
using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Chat.Commands.UpdateUser
{
    /// <summary>
    /// أمر لتحديث حالة المستخدم (online, offline, away, busy)
    /// Command to update user status
    /// </summary>
    public class UpdateUserStatusCommand : IRequest<ResultDto>
    {
        /// <summary>الحالة الجديدة للمستخدم</summary>
        [JsonPropertyName("status")]
        public string Status { get; set; } = string.Empty;
    }
} 