namespace YemenBooking.Application.Common.Exceptions;

/// <summary>
/// استثناء انتهاك قاعدة العمل
/// Business rule exception
/// </summary>
public class BusinessRuleException : Exception
{
    /// <summary>
    /// اسم القاعدة التي تم انتهاكها
    /// Name of the violated rule
    /// </summary>
    public string RuleName { get; }

    /// <summary>
    /// رمز القاعدة
    /// Rule code
    /// </summary>
    public string? RuleCode { get; }

    /// <summary>
    /// كائن القاعدة المعنية
    /// Related object
    /// </summary>
    public object? RelatedObject { get; }

    public BusinessRuleException(string ruleName, string message) : base(message)
    {
        RuleName = ruleName;
    }

    public BusinessRuleException(string ruleName, string ruleCode, string message) : base(message)
    {
        RuleName = ruleName;
        RuleCode = ruleCode;
    }

    public BusinessRuleException(string ruleName, string message, object? relatedObject) : base(message)
    {
        RuleName = ruleName;
        RelatedObject = relatedObject;
    }

    public BusinessRuleException(string ruleName, string ruleCode, string message, object? relatedObject) : base(message)
    {
        RuleName = ruleName;
        RuleCode = ruleCode;
        RelatedObject = relatedObject;
    }

    public BusinessRuleException(string ruleName, string message, Exception innerException) : base(message, innerException)
    {
        RuleName = ruleName;
    }
}