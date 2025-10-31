using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Authentication.Commands.Login;

/// <summary>
/// أمر تسجيل دخول المستخدم للعميل
/// Client login user command
/// </summary>
public class ClientLoginUserCommand : IRequest<ResultDto<ClientLoginUserResponse>>
{
    /// <summary>
    /// البريد الإلكتروني أو رقم الهاتف
    /// </summary>
    public string EmailOrPhone { get; set; } = string.Empty;
    
    /// <summary>
    /// كلمة المرور
    /// </summary>
    public string Password { get; set; } = string.Empty;
    
    /// <summary>
    /// تذكر تسجيل الدخول
    /// </summary>
    public bool RememberMe { get; set; }
}

/// <summary>
/// استجابة تسجيل الدخول للعميل
/// Client login response
/// </summary>
public class ClientLoginUserResponse
{
    /// <summary>
    /// معرف المستخدم
    /// </summary>
    public Guid UserId { get; set; }
    
    /// <summary>
    /// اسم المستخدم
    /// </summary>
    public string Name { get; set; } = string.Empty;
    
    /// <summary>
    /// البريد الإلكتروني
    /// </summary>
    public string Email { get; set; } = string.Empty;
    
    /// <summary>
    /// رقم الهاتف
    /// </summary>
    public string Phone { get; set; } = string.Empty;
    
    /// <summary>
    /// رمز الوصول
    /// </summary>
    public string AccessToken { get; set; } = string.Empty;
    
    /// <summary>
    /// رمز التحديث
    /// </summary>
    public string RefreshToken { get; set; } = string.Empty;
    
    /// <summary>
    /// الأدوار المخصصة للمستخدم
    /// </summary>
    public List<string> Roles { get; set; } = new();
}