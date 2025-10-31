namespace YemenBooking.Application.Common.Exceptions;

/// <summary>
/// استثناء التعارض
/// Conflict exception
/// </summary>
public class ConflictException : Exception
{
    /// <summary>
    /// نوع التعارض
    /// Conflict type
    /// </summary>
    public string ConflictType { get; }

    /// <summary>
    /// الكائن المتعارض
    /// Conflicting object
    /// </summary>
    public object? ConflictingObject { get; }

    /// <summary>
    /// الكائن الحالي
    /// Current object
    /// </summary>
    public object? CurrentObject { get; }

    public ConflictException(string conflictType, string message) : base(message)
    {
        ConflictType = conflictType;
    }

    public ConflictException(string conflictType, string message, object? conflictingObject) : base(message)
    {
        ConflictType = conflictType;
        ConflictingObject = conflictingObject;
    }

    public ConflictException(string conflictType, string message, object? conflictingObject, object? currentObject) : base(message)
    {
        ConflictType = conflictType;
        ConflictingObject = conflictingObject;
        CurrentObject = currentObject;
    }

    public ConflictException(string conflictType, string message, Exception innerException) : base(message, innerException)
    {
        ConflictType = conflictType;
    }
}