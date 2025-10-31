namespace YemenBooking.Application.Common.Exceptions;

using FluentValidation.Results;

/// <summary>
/// استثناء التحقق من صحة البيانات
/// Validation exception
/// </summary>
public class ValidationException : Exception
{
    /// <summary>
    /// قائمة أخطاء التحقق
    /// List of validation errors
    /// </summary>
    public IEnumerable<string> Errors { get; }

    /// <summary>
    /// حقل الخطأ
    /// Error field
    /// </summary>
    public string? Field { get; }

    public ValidationException(string message) : base(message)
    {
        Errors = new[] { message };
    }

    public ValidationException(string field, string message) : base(message)
    {
        Field = field;
        Errors = new[] { message };
    }

    public ValidationException(IEnumerable<string> errors) : base("One or more validation errors occurred")
    {
        Errors = errors;
    }

    public ValidationException(string message, IEnumerable<string> errors) : base(message)
    {
        Errors = errors;
    }

    public ValidationException(string message, Exception innerException) : base(message, innerException)
    {
        Errors = new[] { message };
    }

    public ValidationException(IEnumerable<ValidationFailure> failures) : base("One or more validation errors occurred")
    {
        Errors = failures.Select(f => f.ErrorMessage);
    }
}