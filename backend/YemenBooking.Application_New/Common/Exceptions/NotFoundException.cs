namespace YemenBooking.Application.Common.Exceptions;

/// <summary>
/// استثناء عدم العثور على الكائن
/// Not found exception
/// </summary>
public class NotFoundException : Exception
{
    /// <summary>
    /// نوع الكائن غير الموجود
    /// Type of not found object
    /// </summary>
    public string ObjectType { get; }

    /// <summary>
    /// معرّف الكائن غير الموجود
    /// ID of not found object
    /// </summary>
    public string? ObjectId { get; }

    public NotFoundException(string objectType, string? objectId = null) 
        : base($"{objectType} {(objectId != null ? $"with ID '{objectId}'" : "")} was not found")
    {
        ObjectType = objectType;
        ObjectId = objectId;
    }

    public NotFoundException(string objectType, string? objectId, string message) 
        : base(message)
    {
        ObjectType = objectType;
        ObjectId = objectId;
    }

    public NotFoundException(string objectType, string? objectId, string message, Exception innerException) 
        : base(message, innerException)
    {
        ObjectType = objectType;
        ObjectId = objectId;
    }
}