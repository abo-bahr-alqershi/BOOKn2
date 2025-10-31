namespace YemenBooking.Core.ValueObjects;

/// <summary>
/// كائن قيمة معلومات الاتصال
/// Contact value object
/// </summary>
public class Contact
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
    /// معلومات إضافية
    /// Additional info
    /// </summary>
    public string? AdditionalInfo { get; set; }
    
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
    
    /// <summary>
    /// منطقة التوقيت
    /// Time zone
    /// </summary>
    public string? TimeZone { get; set; }
    
    /// <summary>
    /// اسم جهة الاتصال (للشركات)
    /// Contact person name (for companies)
    /// </summary>
    public string? ContactPersonName { get; set; }
    
    /// <summary>
    /// المنصب (للشركات)
    /// Position (for companies)
    /// </summary>
    public string? Position { get; set; }
    
    public Contact()
    {
    }
    
    public Contact(string? primaryPhone, string? primaryEmail)
    {
        PrimaryPhone = primaryPhone;
        PrimaryEmail = primaryEmail;
    }
    
    public Contact(string? primaryPhone, string? secondaryPhone, string? primaryEmail, string? secondaryEmail)
    {
        PrimaryPhone = primaryPhone;
        SecondaryPhone = secondaryPhone;
        PrimaryEmail = primaryEmail;
        SecondaryEmail = secondaryEmail;
    }
    
    /// <summary>
    /// الحصول على أفضل رقم هاتف
    /// Get best phone number
    /// </summary>
    public string? BestPhone => !string.IsNullOrWhiteSpace(PrimaryPhone) ? PrimaryPhone : SecondaryPhone;
    
    /// <summary>
    /// الحصول على أفضل بريد إلكتروني
    /// Get best email
    /// </summary>
    public string? BestEmail => !string.IsNullOrWhiteSpace(PrimaryEmail) ? PrimaryEmail : SecondaryEmail;
    
    /// <summary>
    /// هل يوجد معلومات اتصال صالحة
    /// Has valid contact information
    /// </summary>
    public bool HasValidContact => !string.IsNullOrWhiteSpace(BestPhone) || !string.IsNullOrWhiteSpace(BestEmail);
    
    /// <summary>
    /// عدد طرق الاتصال المتاحة
    /// Number of available contact methods
    /// </summary>
    public int AvailableContactMethods
    {
        get
        {
            var count = 0;
            if (!string.IsNullOrWhiteSpace(PrimaryPhone)) count++;
            if (!string.IsNullOrWhiteSpace(SecondaryPhone)) count++;
            if (!string.IsNullOrWhiteSpace(PrimaryEmail)) count++;
            if (!string.IsNullOrWhiteSpace(SecondaryEmail)) count++;
            if (!string.IsNullOrWhiteSpace(Website)) count++;
            return count;
        }
    }
    
    public override string ToString()
    {
        var parts = new List<string>();
        
        if (!string.IsNullOrWhiteSpace(BestPhone))
            parts.Add($"Phone: {BestPhone}");
            
        if (!string.IsNullOrWhiteSpace(BestEmail))
            parts.Add($"Email: {BestEmail}");
            
        return string.Join(", ", parts);
    }
    
    public override bool Equals(object? obj)
    {
        if (obj is not Contact other) return false;
        
        return PrimaryPhone == other.PrimaryPhone &&
               SecondaryPhone == other.SecondaryPhone &&
               PrimaryEmail == other.PrimaryEmail &&
               SecondaryEmail == other.SecondaryEmail &&
               Website == other.Website &&
               Fax == other.Fax;
    }
    
    public override int GetHashCode()
    {
        return HashCode.Combine(PrimaryPhone, SecondaryPhone, PrimaryEmail, SecondaryEmail, Website, Fax);
    }
}