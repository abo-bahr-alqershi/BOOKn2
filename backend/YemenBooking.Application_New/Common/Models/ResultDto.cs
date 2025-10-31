namespace YemenBooking.Application.Common.Models;

/// <summary>
/// DTO لنتائج العمليات
/// DTO for operation results
/// </summary>
/// <typeparam name="T">نوع البيانات المرجعة</typeparam>
public class ResultDto<T>
{
    /// <summary>
    /// هل العملية نجحت
    /// Is operation successful
    /// </summary>
    public bool Success { get; set; }
    
    /// <summary>
    /// البيانات المرجعة
    /// Returned data
    /// </summary>
    public T? Data { get; set; }
    
    /// <summary>
    /// رسالة النجاح أو الخطأ
    /// Success or error message
    /// </summary>
    public string? Message { get; set; }
    
    /// <summary>
    /// قائمة الأخطاء
    /// List of errors
    /// </summary>
    public IEnumerable<string> Errors { get; set; } = new List<string>();
    
    /// <summary>
    /// كود الخطأ
    /// Error code
    /// </summary>
    public string? ErrorCode { get; set; }
    
    /// <summary>
    /// الطابع الزمني
    /// Timestamp
    /// </summary>
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    
    /// <summary>
    /// هل العملية نجحت (alias for Success)
    /// Is operation successful (alias for Success)
    /// </summary>
    public bool IsSuccess => Success;
    
    /// <summary>
    /// كود العملية
    /// Operation code
    /// </summary>
    public string? Code { get; set; }
    
    /// <summary>
    /// هل ينبغي عرض الرسالة كحواري بدلاً من رسالة خطأ
    /// Whether the client should present the message as a dialog instead of an error toast
    /// </summary>
    public bool ShowAsDialog { get; set; } = false;
    

    /// <summary>
    /// إنشاء نتيجة ناجحة
    /// Create successful result
    /// </summary>
    public static ResultDto<T> Ok(T? data, string? arabicMessage = null, string? englishMessage = null, bool showAsDialog = false)
    {
        return new ResultDto<T>
        {
            Success = true,
            Data = data,
            Message = arabicMessage ?? englishMessage,
            ShowAsDialog = showAsDialog
        };
    }
    
    /// <summary>
    /// Alias for Ok to maintain existing Succeeded calls.
    /// </summary>
    public static ResultDto<T> Succeeded(T? data, string? arabicMessage = null, string? englishMessage = null, bool showAsDialog = false)
    {
        return Ok(data, arabicMessage, englishMessage, showAsDialog);
    }
    
    /// <summary>
    /// Alias named Success to match handler usage
    /// </summary>
    public static ResultDto<T> SuccessResult(T? data, string? arabicMessage = null, string? englishMessage = null, bool showAsDialog = false)
    {
        return Ok(data, arabicMessage, englishMessage, showAsDialog);
    }
        
    /// <summary>
    /// إنشاء نتيجة فاشلة
    /// Create failed result
    /// </summary>
    public static ResultDto<T> Failure(string arabicMessage, string? englishMessage = null, string? errorCode = null, bool showAsDialog = false)
    {
        return new ResultDto<T>
        {
            Success = false,
            Message = arabicMessage ?? englishMessage,
            ErrorCode = errorCode,
            Errors = new[] { arabicMessage ?? englishMessage ?? "خطأ غير محدد" },
            ShowAsDialog = showAsDialog
        };
    }
    
    /// <summary>
    /// إنشاء نتيجة فاشلة مع أخطاء متعددة
    /// Create failed result with multiple errors
    /// </summary>
    public static ResultDto<T> Failed(IEnumerable<string> errors, string? message = null, string? errorCode = null, bool showAsDialog = false)
    {
        return new ResultDto<T>
        {
            Success = false,
            Message = message ?? "حدثت أخطاء متعددة",
            ErrorCode = errorCode,
            Errors = errors,
            ShowAsDialog = showAsDialog
        };
    }
    
    /// <summary>
    /// إنشاء نتيجة فاشلة بسيطة
    /// Create simple failed result
    /// </summary>
    public static ResultDto<T> Failed(string arabicMessage, string? errorCode = null, bool showAsDialog = false)
    {
        return new ResultDto<T>
        {
            Success = false,
            Message = arabicMessage,
            ErrorCode = errorCode,
            Errors = new[] { arabicMessage },
            ShowAsDialog = showAsDialog
        };
    }
}

/// <summary>
/// DTO لنتائج العمليات بدون بيانات
/// DTO for operation results without data
/// </summary>
public class ResultDto
{
    /// <summary>
    /// هل العملية نجحت
    /// Is operation successful
    /// </summary>
    public bool Success { get; set; }

    /// <summary>
    /// رسالة النجاح أو الخطأ
    /// Success or error message
    /// </summary>
    public string? Message { get; set; }

    /// <summary>
    /// قائمة الأخطاء
    /// List of errors
    /// </summary>
    public IEnumerable<string> Errors { get; set; } = new List<string>();

    /// <summary>
    /// كود الخطأ
    /// Error code
    /// </summary>
    public string? ErrorCode { get; set; }

    /// <summary>
    /// الطابع الزمني
    /// Timestamp
    /// </summary>
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    
        /// <summary>
    /// هل ينبغي عرض الرسالة كحواري بدلاً من رسالة خطأ
    /// Whether the client should present the message as a dialog instead of an error toast
    /// </summary>
    public bool ShowAsDialog { get; set; } = false;

    /// <summary>
    /// هل العملية نجحت (alias for Success)
    /// Is operation successful (alias for Success)
    /// </summary>
    public bool IsSuccess => Success;
    
    /// <summary>
    /// كود العملية
    /// Operation code
    /// </summary>
    public string? Code { get; set; }

    /// <summary>
    /// إنشاء نتيجة ناجحة
    /// Create successful result
    /// </summary>
    public static ResultDto Ok(string? arabicMessage = null, string? englishMessage = null, bool showAsDialog = false)
    {
        return new ResultDto
        {
            Success = true,
            Message = arabicMessage ?? englishMessage,
            ShowAsDialog = showAsDialog
        };
    }

    /// <summary>
    /// Alias for Ok, to maintain existing Succeeded calls.
    /// </summary>
    public static ResultDto Succeeded(string? arabicMessage = null, string? englishMessage = null, bool showAsDialog = false)
    {
        return Ok(arabicMessage, englishMessage, showAsDialog);
    }
    /// <summary>
    /// Alias named Success to match handler usage
    /// </summary>
    public static ResultDto SuccessResult(string? arabicMessage = null, string? englishMessage = null, bool showAsDialog = false)
    {
        return Ok(arabicMessage, englishMessage, showAsDialog);
    }

    /// <summary>
    /// إنشاء نتيجة فاشلة
    /// Create failed result
    /// </summary>
    public static ResultDto Failure(string arabicMessage, string? englishMessage = null, string? errorCode = null, bool showAsDialog = false)
    {
        return new ResultDto
        {
            Success = false,
            Message = arabicMessage ?? englishMessage,
            ErrorCode = errorCode,
            Errors = new[] { arabicMessage ?? englishMessage ?? "خطأ غير محدد" },
            ShowAsDialog = showAsDialog
        };
    }

    /// <summary>
    /// إنشاء نتيجة فاشلة مع أخطاء متعددة
    /// Create failed result with multiple errors
    /// </summary>
    public static ResultDto Failed(IEnumerable<string> errors, string? message = null, string? errorCode = null, bool showAsDialog = false)
    {
        return new ResultDto
        {
            Success = false,
            Message = message ?? "حدثت أخطاء متعددة",
            ErrorCode = errorCode,
            Errors = errors,
            ShowAsDialog = showAsDialog
        };
    }
    
    /// <summary>
    /// إنشاء نتيجة فاشلة مع أخطاء متعددة
    /// Create failed result with multiple errors
    /// </summary>
    public static ResultDto Failed(string? message = null, string? errorCode = null, bool showAsDialog = false)
    {
        return new ResultDto
        {
            Success = false,
            Message = message ?? "حدثت أخطاء متعددة",
            ErrorCode = errorCode,
            Errors = new[] { message ?? "خطأ غير محدد" },
            ShowAsDialog = showAsDialog
        };
    }
}