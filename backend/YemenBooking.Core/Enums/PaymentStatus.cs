namespace YemenBooking.Core.Enums;

/// <summary>
/// تعداد حالات الدفع
/// Payment Status enumeration
/// </summary>
public enum PaymentStatus
{
    /// <summary>
    /// ناجح
    /// Successful
    /// </summary>
    Successful,
    
    /// <summary>
    /// فاشل
    /// Failed
    /// </summary>
    Failed,
    
    /// <summary>
    /// معلق
    /// Pending
    /// </summary>
    Pending,
    
    /// <summary>
    /// مسترد
    /// Refunded
    /// </summary>
    Refunded,
    
    /// <summary>
    /// إبطال الدفع
    /// Voided
    /// </summary>
    Voided,
    
    /// <summary>
    /// استرداد جزئي
    /// Partially refunded
    /// </summary>
    PartiallyRefunded,

    /// <summary>
    /// مرفوض
    /// Rejected
    /// </summary>
    Rejected
} 