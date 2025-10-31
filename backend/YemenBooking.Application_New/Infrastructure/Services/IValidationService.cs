namespace YemenBooking.Application.Infrastructure.Services;

/// <summary>
/// خدمة التحقق من صحة البيانات
/// </summary>
public interface IValidationService
{
    /// <summary>
    /// التحقق من صحة بيانات الحجز
    /// </summary>
    Task<ValidationResult> ValidateBookingAsync(object bookingData, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// التحقق من صحة بيانات Unit
    /// </summary>
    Task<ValidationResult> ValidateUnitAsync(object unitData, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// التحقق من صحة بيانات المستخدم
    /// </summary>
    Task<ValidationResult> ValidateUserAsync(object userData, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// التحقق من صحة بيانات property
    /// </summary>
    Task<ValidationResult> ValidatePropertyAsync(object propertyData, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// التحقق من صحة بيانات الدفع
    /// </summary>
    Task<ValidationResult> ValidatePaymentAsync(object paymentData, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// التحقق من صحة البريد الإلكتروني
    /// </summary>
    Task<bool> IsValidEmailAsync(string email, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// التحقق من صحة رقم الهاتف
    /// </summary>
    Task<bool> IsValidPhoneAsync(string phone, string? countryCode = null, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// التحقق من قوة كلمة المرور
    /// </summary>
    Task<PasswordValidationResult> ValidatePasswordAsync(string password, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// التحقق من صحة الرقم الوطني
    /// </summary>
    Task<bool> IsValidNationalIdAsync(string nationalId, string? country = null, CancellationToken cancellationToken = default);
}

/// <summary>
/// نتيجة التحقق من صحة البيانات
/// </summary>
public class ValidationResult
{
    public bool IsValid { get; set; }
    public List<ValidationError> Errors { get; set; } = new();
    public List<ValidationWarning> Warnings { get; set; } = new();
    public string? Message { get; set; }
    
    public static ValidationResult Success() => new() { IsValid = true };
    public static ValidationResult Failure(string message, string code) => new() 
    { 
        IsValid = false, 
        Errors = new() { new ValidationError { Message = message, Code = code } } 
    };
}

/// <summary>
/// خطأ في التحقق من صحة البيانات
/// </summary>
public class ValidationError
{
    public string Code { get; set; } = null!;
    public string Message { get; set; } = null!;
    public string? Field { get; set; }
    public object? Value { get; set; }
}

/// <summary>
/// تحذير في التحقق من صحة البيانات
/// </summary>
public class ValidationWarning
{
    public string Code { get; set; } = null!;
    public string Message { get; set; } = null!;
    public string? Field { get; set; }
    public object? Value { get; set; }
}

/// <summary>
/// نتيجة التحقق من كلمة المرور
/// </summary>
public class PasswordValidationResult
{
    public bool IsValid { get; set; }
    public int Score { get; set; } // 0-100
    public PasswordStrength Strength { get; set; }
    public List<string> Requirements { get; set; } = new();
    public List<string> Suggestions { get; set; } = new();
}

/// <summary>
/// قوة كلمة المرور
/// </summary>
public enum PasswordStrength
{
    /// <summary>
    /// ضعيف جداً
    /// </summary>
    VERY_WEAK,
    
    /// <summary>
    /// ضعيف
    /// </summary>
    WEAK,
    
    /// <summary>
    /// متوسط
    /// </summary>
    FAIR,
    
    /// <summary>
    /// جيد
    /// </summary>
    GOOD,
    
    /// <summary>
    /// ممتاز
    /// </summary>
    EXCELLENT
}
