namespace YemenBooking.Application.Common.Models;

/// <summary>
/// DTO معلومات الاتصال
/// Contact information DTO
/// </summary>
public class ContactDto
{
    /// <summary>
    /// رقم الهاتف الأساسي
    /// Primary phone
    /// </summary>
    public string? PrimaryPhone { get; set; }
    
    /// <summary>
    /// رقم الهاتف الثانوي
    /// Secondary phone
    /// </summary>
    public string? SecondaryPhone { get; set; }
    
    /// <summary>
    /// البريد الإلكتروني الأساسي
    /// Primary email
    /// </summary>
    public string? PrimaryEmail { get; set; }
    
    /// <summary>
    /// البريد الإلكتروني الثانوي
    /// Secondary email
    /// </summary>
    public string? SecondaryEmail { get; set; }
    
    /// <summary>
    /// الموقع الإلكتروني
    /// Website
    /// </summary>
    public string? Website { get; set; }
    
    /// <summary>
    /// الفاكس
    /// Fax
    /// </summary>
    public string? Fax { get; set; }
    
    /// <summary>
    /// رقم الطوارئ
    /// Emergency contact
    /// </summary>
    public string? EmergencyContact { get; set; }
    
    /// <summary>
    /// أفضل وقت للاتصال
    /// Best time to contact
    /// </summary>
    public string? BestTimeToContact { get; set; }
    
    /// <summary>
    /// لغة التواصل المفضلة
    /// Preferred communication language
    /// </summary>
    public string? PreferredLanguage { get; set; }
    
    /// <summary>
    /// الطريقة المفضلة للتواصل
    /// Preferred contact method
    /// </summary>
    public string? PreferredContactMethod { get; set; }
}