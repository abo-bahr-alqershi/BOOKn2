namespace YemenBooking.Core.Enums;

/// <summary>
/// نوع المحتوى في القسم
/// </summary>
public enum ContentType
{
    /// <summary>
    /// عقارات فقط
    /// </summary>
    Properties = 0,

    /// <summary>
    /// وحدات فقط
    /// </summary>
    Units = 1,

    /// <summary>
    /// مختلط
    /// </summary>
    Mixed = 2,

    /// <summary>
    /// بدون عناصر (لا عقارات ولا وحدات)
    /// </summary>
    None = 3
}
