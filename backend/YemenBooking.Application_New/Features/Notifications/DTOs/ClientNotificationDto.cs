using System;

namespace YemenBooking.Application.Features.Notifications.DTOs;

/// <summary>
/// DTO لإشعارات العميل
/// Client notification DTO
/// </summary>
public class ClientNotificationDto
{
    /// <summary>
    /// معرف الإشعار
    /// Notification ID
    /// </summary>
    public Guid Id { get; set; }

    /// <summary>
    /// عنوان الإشعار
    /// Notification title
    /// </summary>
    public string Title { get; set; } = string.Empty;

    /// <summary>
    /// محتوى الإشعار
    /// Notification content
    /// </summary>
    public string Content { get; set; } = string.Empty;

    /// <summary>
    /// نوع الإشعار
    /// Notification type
    /// </summary>
    public string Type { get; set; } = string.Empty;

    /// <summary>
    /// أولوية الإشعار
    /// Notification priority
    /// </summary>
    public string Priority { get; set; } = "MEDIUM";

    /// <summary>
    /// هل تم قراءة الإشعار
    /// Is notification read
    /// </summary>
    public bool IsRead { get; set; }

    /// <summary>
    /// تاريخ الإنشاء
    /// Creation date
    /// </summary>
    public DateTime CreatedAt { get; set; }

    /// <summary>
    /// تاريخ القراءة
    /// Read date
    /// </summary>
    public DateTime? ReadAt { get; set; }

    /// <summary>
    /// رابط الأيقونة
    /// Icon URL
    /// </summary>
    public string? IconUrl { get; set; }

    /// <summary>
    /// رابط الصورة
    /// Image URL
    /// </summary>
    public string? ImageUrl { get; set; }

    /// <summary>
    /// بيانات إضافية
    /// Additional data
    /// </summary>
    public string? AdditionalData { get; set; }

    /// <summary>
    /// رابط الإجراء
    /// Action URL
    /// </summary>
    public string? ActionUrl { get; set; }

    /// <summary>
    /// هل يمكن إخفاء الإشعار
    /// Can dismiss notification
    /// </summary>
    public bool CanDismiss { get; set; } = true;
}
