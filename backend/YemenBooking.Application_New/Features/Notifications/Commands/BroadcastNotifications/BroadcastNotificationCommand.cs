using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Notifications.Commands.BroadcastNotifications
{
    /// <summary>
    /// بث إشعار لمجموعة من المستخدمين حسب معايير اختيار
    /// Broadcast notification to target users
    /// </summary>
    public class BroadcastNotificationCommand : IRequest<ResultDto<int>>
    {
        public string Type { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;

        // Targeting
        public bool TargetAllUsers { get; set; } = false;
        public Guid[]? TargetUserIds { get; set; }
        public string[]? TargetRoles { get; set; }
        public Guid? TargetChannelId { get; set; } // New: Target specific channel

        // Optional scheduling
        public DateTime? ScheduledFor { get; set; }
        public string Priority { get; set; } = "MEDIUM";
        
        // Additional data
        public Dictionary<string, string>? Data { get; set; }
    }
}

