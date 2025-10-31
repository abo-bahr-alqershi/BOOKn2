namespace YemenBooking.Application.Common.Exceptions;

/// <summary>
/// استثناء عدم التفويض
/// Unauthorized exception
/// </summary>
public class UnauthorizedException : Exception
{
    /// <summary>
    /// نوع العملية المطلوبة
    /// Required operation type
    /// </summary>
    public string? OperationType { get; }

    /// <summary>
    /// المورد المطلوب الوصول إليه
    /// Required resource
    /// </summary>
    public string? Resource { get; }

    /// <summary>
    /// الصلاحية المطلوبة
    /// Required permission
    /// </summary>
    public string? RequiredPermission { get; }

    public UnauthorizedException() : base("Access denied")
    {
    }

    public UnauthorizedException(string message) : base(message)
    {
    }

    public UnauthorizedException(string operationType, string resource) 
        : base($"Access denied to {operationType} on {resource}")
    {
        OperationType = operationType;
        Resource = resource;
    }

    public UnauthorizedException(string operationType, string resource, string requiredPermission) 
        : base($"Access denied to {operationType} on {resource}. Required permission: {requiredPermission}")
    {
        OperationType = operationType;
        Resource = resource;
        RequiredPermission = requiredPermission;
    }

    public UnauthorizedException(string message, Exception innerException) : base(message, innerException)
    {
    }
}