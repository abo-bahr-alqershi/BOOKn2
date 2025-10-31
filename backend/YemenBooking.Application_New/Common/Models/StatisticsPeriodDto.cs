namespace YemenBooking.Application.Common.Models;

/// <summary>
/// DTO فترة الإحصائيات
/// StatisticsDto period DTO
/// </summary>
public class StatisticsPeriodDto
{
    /// <summary>
    /// تاريخ البداية
    /// Start date
    /// </summary>
    public DateTime StartDate { get; set; }
    
    /// <summary>
    /// تاريخ النهاية
    /// End date
    /// </summary>
    public DateTime EndDate { get; set; }
    
    /// <summary>
    /// اسم الفترة
    /// Period name
    /// </summary>
    public string PeriodName { get; set; } = null!;
    
    /// <summary>
    /// نوع الفترة
    /// Period type
    /// </summary>
    public PeriodType PeriodType { get; set; }
    
    /// <summary>
    /// القيمة
    /// Value
    /// </summary>
    public decimal Value { get; set; }
    
    /// <summary>
    /// العدد
    /// Count
    /// </summary>
    public int Count { get; set; }
    
    /// <summary>
    /// المعدل
    /// Average
    /// </summary>
    public decimal? Average { get; set; }
    
    /// <summary>
    /// النسبة المئوية للتغيير
    /// Change percentage
    /// </summary>
    public decimal? ChangePercentage { get; set; }
    
    /// <summary>
    /// اتجاه التغيير
    /// Change direction
    /// </summary>
    public ChangeDirection? ChangeDirection { get; set; }
    
    /// <summary>
    /// بيانات إضافية
    /// Additional data
    /// </summary>
    public Dictionary<string, object>? AdditionalData { get; set; }
}

/// <summary>
/// نوع الفترة
/// Period type
/// </summary>
public enum PeriodType
{
    /// <summary>
    /// يومي
    /// Daily
    /// </summary>
    DAILY,
    
    /// <summary>
    /// أسبوعي
    /// Weekly
    /// </summary>
    WEEKLY,
    
    /// <summary>
    /// شهري
    /// Monthly
    /// </summary>
    MONTHLY,
    
    /// <summary>
    /// ربع سنوي
    /// Quarterly
    /// </summary>
    QUARTERLY,
    
    /// <summary>
    /// سنوي
    /// Yearly
    /// </summary>
    YEARLY,
    
    /// <summary>
    /// مخصص
    /// Custom
    /// </summary>
    CUSTOM
}

/// <summary>
/// اتجاه التغيير
/// Change direction
/// </summary>
public enum ChangeDirection
{
    /// <summary>
    /// زيادة
    /// Increase
    /// </summary>
    UP,
    
    /// <summary>
    /// نقصان
    /// Decrease
    /// </summary>
    DOWN,
    
    /// <summary>
    /// ثابت
    /// Stable
    /// </summary>
    STABLE
}