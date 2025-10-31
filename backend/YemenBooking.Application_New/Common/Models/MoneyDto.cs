namespace YemenBooking.Application.Common.Models;

/// <summary>
/// DTO للمبالغ المالية والعملات
/// DTO for monetary amounts and currencies
/// </summary>
public class MoneyDto
{
    /// <summary>
    /// المبلغ المالي
    /// Monetary amount
    /// </summary>
    public decimal Amount { get; set; }
    
    /// <summary>
    /// رمز العملة
    /// Currency code
    /// </summary>
    public string Currency { get; set; } = "YER";
    
    /// <summary>
    /// سعر الصرف
    /// سعر الصرف
    /// Exchange rate
    /// </summary>
    public decimal ExchangeRate { get; set; }

    /// <summary>
    /// المبلغ المنسق للعرض
    /// Formatted amount for display
    /// </summary>
    public string FormattedAmount => $"{Amount:N2} {Currency}";
}