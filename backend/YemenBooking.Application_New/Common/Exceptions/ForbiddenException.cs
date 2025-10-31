namespace YemenBooking.Application.Common.Exceptions;

/// <summary>
/// استثناء المنع
/// Forbidden exception
/// </summary>
public class ForbiddenException : Exception
{
    /// <summary>
    /// نوع العملية المحظورة
    /// Forbidden operation type
    /// </summary>
    public string? OperationType { get; }

    /// <summary>
    /// المورد المحظور
    /// Forbidden resource
    /// </summary>
    public string? Resource { get; }

    /// <summary>
    /// سبب المنع
    /// Reason for prohibition
    /// </summary>
    public string? Reason { get; }

    public ForbiddenException() : base("Operation forbidden")
    {
    }

    public ForbiddenException(string message) : base(message)
    {
    }

    public ForbiddenException(string operationType, string resource) 
        : base($"Operation '{operationType}' is forbidden on resource '{resource}'")
    {
        OperationType = operationType;
        Resource = resource;
    }

    public ForbiddenException(string operationType, string resource, string reason) 
        : base($"Operation '{operationType}' is forbidden on resource '{resource}'. Reason: {reason}")
    {
        OperationType = operationType;
        Resource = resource;
        Reason = reason;
    }

    public ForbiddenException(string message, Exception innerException) : base(message, innerException)
    {
    }
}