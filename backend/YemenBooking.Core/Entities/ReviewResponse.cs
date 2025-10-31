namespace YemenBooking.Core.Entities;

using System;
using System.ComponentModel.DataAnnotations;

/// <summary>
/// كيان رد على التقييم
/// Review response entity
/// </summary>
[Display(Name = "رد على التقييم")]
public class ReviewResponse : BaseEntity<Guid>
{
    /// <summary>
    /// معرف التقييم المرتبط
    /// Related review identifier
    /// </summary>
    [Display(Name = "معرف التقييم")]
    public Guid ReviewId { get; set; }

    /// <summary>
    /// نص الرد
    /// Response text
    /// </summary>
    [Display(Name = "نص الرد")]
    public string Text { get; set; } = string.Empty;

    /// <summary>
    /// تاريخ الرد
    /// Response date
    /// </summary>
    [Display(Name = "تاريخ الرد")]
    public DateTime RespondedAt { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// المستخدم الذي قام بالرد
    /// Responder user identifier
    /// </summary>
    [Display(Name = "معرّف المُجيب")]
    public Guid RespondedBy { get; set; }

    /// <summary>
    /// اسم المستخدم الذي قام بالرد (نسخ اختياري للتسريع)
    /// Cached responder name for quick reads
    /// </summary>
    [Display(Name = "اسم المُجيب")]
    public string RespondedByName { get; set; } = string.Empty;

    /// <summary>
    /// المراجعة المرتبطة
    /// Navigation to review
    /// </summary>
    public virtual Review Review { get; set; } = null!;
}

