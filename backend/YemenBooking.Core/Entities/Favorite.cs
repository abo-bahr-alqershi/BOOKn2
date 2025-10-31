using System.ComponentModel.DataAnnotations;

namespace YemenBooking.Core.Entities;

/// <summary>
/// كيان المفضلة
/// Favorite entity
/// </summary>
[Display(Name = "المفضلة")]
public class Favorite : BaseEntity<Guid>
{
    /// <summary>
    /// معرف المستخدم
    /// User ID
    /// </summary>
    [Display(Name = "معرف المستخدم")]
    public Guid UserId { get; set; }

    /// <summary>
    /// معرف العقار
    /// Property ID
    /// </summary>
    [Display(Name = "معرف العقار")]
    public Guid PropertyId { get; set; }

    /// <summary>
    /// تاريخ الإضافة للمفضلة
    /// Date added to favorites
    /// </summary>
    [Display(Name = "تاريخ الإضافة")]
    public DateTime DateAdded { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// ملاحظات المستخدم (اختيارية)
    /// User notes (optional)
    /// </summary>
    [Display(Name = "الملاحظات")]
    [MaxLength(500)]
    public string? Notes { get; set; }

    /// <summary>
    /// أولوية المفضلة (1-5)
    /// Favorite priority (1-5)
    /// </summary>
    [Display(Name = "الأولوية")]
    [Range(1, 5)]
    public int Priority { get; set; } = 3;

    /// <summary>
    /// المستخدم المرتبط
    /// Related user
    /// </summary>
    public virtual User? User { get; set; }

    /// <summary>
    /// العقار المرتبط
    /// Related property
    /// </summary>
    public virtual Property? Property { get; set; }
}
