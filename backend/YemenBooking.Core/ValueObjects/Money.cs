namespace YemenBooking.Core.ValueObjects;

/// <summary>
/// كائن قيمة للتعامل مع المبالغ المالية والعملات
/// Value object for handling monetary amounts and currencies
/// </summary>
public record Money
{
    /// <summary>
    /// المبلغ المالي
    /// Monetary amount
    /// </summary>
    public decimal Amount { get; init; }
    
    /// <summary>
    /// رمز العملة (USD, EUR, YER, etc.)
    /// Currency code (USD, EUR, YER, etc.)
    /// </summary>
    public string Currency { get; init; }
    
    /// <summary>
    /// سعر الصرف
    /// Exchange rate
    /// </summary>
    public decimal ExchangeRate { get; set; }

    /// <summary>
    /// منشئ كائن المال
    /// Money constructor
    /// </summary>
    /// <param name="amount">المبلغ</param>
    /// <param name="currency">رمز العملة</param>
    public Money(decimal amount, string currency)
    {
        if (amount < 0)
            throw new ArgumentException("المبلغ لا يمكن أن يكون سالباً", nameof(amount));

        if (string.IsNullOrWhiteSpace(currency))
            throw new ArgumentException("رمز العملة مطلوب", nameof(currency));

        Amount = amount;
        Currency = currency.ToUpperInvariant();
    }
    
    /// <summary>
    /// إنشاء كائن مال بالدولار الأمريكي
    /// Create a Money object with USD currency
    /// </summary>
    public static Money Usd(decimal amount) => new(amount, "USD");
    
    /// <summary>
    /// إنشاء كائن مال بالريال اليمني
    /// Create a Money object with Yemeni Rial currency
    /// </summary>
    public static Money Yer(decimal amount) => new(amount, "YER");
    
    /// <summary>
    /// إنشاء كائج مال بالمجان (صفر)
    /// Create a free (zero) Money object
    /// </summary>
    public static Money Zero(string currency) => new(0, currency);
    
    /// <summary>
    /// إنشاء كائن مال بالريال السعودي
    /// Create a Money object with Saudi Riyal currency
    /// </summary>
    public static Money Sar(decimal amount) => new(amount, "SAR");
    
    /// <summary>
    /// إنشاء كائن مال بأي عملة
    /// Create a Money object with any currency
    /// </summary>
    public static Money Create(decimal amount, string currency) => new(amount, currency);
    
    /// <summary>
    /// جمع المبالغ من نفس العملة
    /// Add amounts of the same currency
    /// </summary>
    public static Money operator +(Money left, Money right)
    {
        if (left.Currency != right.Currency)
            throw new InvalidOperationException("لا يمكن جمع عملات مختلفة");
        
        return new Money(left.Amount + right.Amount, left.Currency);
    }
    
    /// <summary>
    /// طرح المبالغ من نفس العملة
    /// Subtract amounts of the same currency
    /// </summary>
    public static Money operator -(Money left, Money right)
    {
        if (left.Currency != right.Currency)
            throw new InvalidOperationException("لا يمكن طرح عملات مختلفة");
        
        return new Money(left.Amount - right.Amount, left.Currency);
    }
    
    /// <summary>
    /// ضرب المبلغ في رقم
    /// Multiply amount by a number
    /// </summary>
    public static Money operator *(Money money, decimal multiplier)
    {
        return new Money(money.Amount * multiplier, money.Currency);
    }
    
    /// <summary>
    /// إضافة مبلغ عشري إلى كائن Money
    /// Add a decimal amount to Money
    /// </summary>
    public static Money operator +(Money money, decimal amount)
    {
        return new Money(money.Amount + amount, money.Currency);
    }

    /// <summary>
    /// إضافة كائن Money إلى مبلغ عشري
    /// Add Money to a decimal amount
    /// </summary>
    public static Money operator +(decimal amount, Money money)
    {
        return new Money(money.Amount + amount, money.Currency);
    }
    
    /// <summary>
    /// تنسيق المبلغ للعرض
    /// Format amount for display
    /// </summary>
    /// <summary>
    /// التحويل الضمني إلى decimal لإرجاع المبلغ فقط
    /// Implicit conversion to decimal (amount)
    /// </summary>
    public static implicit operator decimal(Money money) => money.Amount;

    public override string ToString()
    {
        return $"{Amount:N2} {Currency}";
    }
}