namespace YemenBooking.Core.Entities;

using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

/// <summary>
/// كيان المستخدم
/// User entity
/// </summary>
[Display(Name = "كيان المستخدم")]
public class User : BaseEntity<Guid>
{
    /// <summary>
    /// اسم المستخدم
    /// User name
    /// </summary>
    [Display(Name = "اسم المستخدم")]
    public string Name { get; set; }


    /// <summary>
    /// البريد الإلكتروني للمستخدم
    /// User email
    /// </summary>
    [Display(Name = "البريد الإلكتروني للمستخدم")]
    public string Email { get; set; }

    /// <summary>
    /// كلمة المرور للمستخدم
    /// User password
    /// </summary>
    [Display(Name = "كلمة المرور للمستخدم")]
    public string Password { get; set; }

    /// <summary>
    /// رقم هاتف المستخدم
    /// User phone number
    /// </summary>
    [Display(Name = "رقم هاتف المستخدم")]
    public string Phone { get; set; }

    /// <summary>
    /// صورة المستخدم
    /// User name
    /// </summary>
    [Display(Name = "صورة المستخدم")]
    public string? ProfileImage { get; set; }

    /// <summary>
    /// رابط صورة الملف الشخصي (متوافق مع معالجات الموبايل)
    /// Profile image URL (alias for ProfileImage)
    /// </summary>
    public string? ProfileImageUrl
    {
        get => ProfileImage;
        set => ProfileImage = value;
    }

    /// <summary>
    /// تاريخ إنشاء حساب المستخدم
    /// User account creation date
    /// </summary>
    [Display(Name = "تاريخ إنشاء حساب المستخدم")]
    public DateTime CreatedAt { get; set; }

    /// <summary>
    /// حالة تفعيل الحساب
    /// Account activation status
    /// </summary>
    [Display(Name = "حالة تفعيل الحساب")]
    public bool IsActive { get; set; }

    /// <summary>
    /// تاريخ آخر تسجيل دخول
    /// Last login date
    /// </summary>
    [Display(Name = "تاريخ آخر تسجيل دخول")]
    public DateTime? LastLoginDate { get; set; }

    /// <summary>
    /// تاريخ آخر ظهور للمستخدم (يتم تحديثه عند أي نشاط)
    /// Last seen date (updated on any activity)
    /// </summary>
    [Display(Name = "تاريخ آخر ظهور")]
    public DateTime? LastSeen { get; set; }

    /// <summary>
    /// إجمالي المبلغ المنفق
    /// Total amount spent
    /// </summary>
    [Display(Name = "إجمالي المبلغ المنفق")]
    public decimal TotalSpent { get; set; } = 0;

    /// <summary>
    /// فئة الولاء (برونزي، فضي، ذهبي)
    /// Loyalty tier (Bronze, Silver, Gold)
    /// </summary>
    [Display(Name = "فئة الولاء")]
    public string? LoyaltyTier { get; set; }

    /// <summary>
    /// الأدوار المرتبطة بالمستخدم
    /// Roles associated with the user
    /// </summary>
    [Display(Name = "الأدوار المرتبطة بالمستخدم")]
    public virtual ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();

    /// <summary>
    /// الكيانات المملوكة من قبل المستخدم
    /// Properties owned by the user
    /// </summary>
    [Display(Name = "الكيانات المملوكة من قبل المستخدم")]
    public virtual ICollection<Property> Properties { get; set; } = new List<Property>();

    /// <summary>
    /// الحجوزات التي قام بها المستخدم
    /// Bookings made by the user
    /// </summary>
    [Display(Name = "الحجوزات التي قام بها المستخدم")]
    public virtual ICollection<Booking> Bookings { get; set; } = new List<Booking>();

    /// <summary>
    /// الوظائف التي يشغلها المستخدم كموظف
    /// Staff positions held by the user
    /// </summary>
    [Display(Name = "الوظائف التي يشغلها المستخدم كموظف")]
    public virtual ICollection<Staff> StaffPositions { get; set; } = new List<Staff>();

    /// <summary>
    /// هل تم تأكيد البريد الإلكتروني
    /// Email confirmed status
    /// </summary>
    [Display(Name = "هل تم تأكيد البريد الإلكتروني")]
    public bool EmailConfirmed { get; set; } = false;

    /// <summary>
    /// هل تم التحقق من البريد الإلكتروني
    /// Is email verified
    /// </summary>
    [Display(Name = "هل تم التحقق من البريد الإلكتروني")]
    public bool IsEmailVerified { get; set; } = false;

    /// <summary>
    /// تاريخ التحقق من البريد الإلكتروني
    /// Email verification date
    /// </summary>
    [Display(Name = "تاريخ التحقق من البريد الإلكتروني")]
    public DateTime? EmailVerifiedAt { get; set; }

    /// <summary>
    /// رمز تأكيد البريد الإلكتروني
    /// Email confirmation token
    /// </summary>
    [Display(Name = "رمز تأكيد البريد الإلكتروني")]
    public string? EmailConfirmationToken { get; set; }

    /// <summary>
    /// تاريخ انتهاء صلاحية رمز تأكيد البريد الإلكتروني
    /// Expiration date of the email confirmation token
    /// </summary>
    [Display(Name = "تاريخ انتهاء صلاحية رمز تأكيد البريد الإلكتروني")]
    public DateTime? EmailConfirmationTokenExpires { get; set; }

    /// <summary>
    /// رمز إعادة تعيين كلمة المرور
    /// Password reset token
    /// </summary>
    [Display(Name = "رمز إعادة تعيين كلمة المرور")]
    public string? PasswordResetToken { get; set; }

    /// <summary>
    /// تاريخ انتهاء صلاحية رمز إعادة تعيين كلمة المرور
    /// Expiration date of the password reset token
    /// </summary>
    [Display(Name = "تاريخ انتهاء صلاحية رمز إعادة تعيين كلمة المرور")]
    public DateTime? PasswordResetTokenExpires { get; set; }

    /// <summary>
    /// هل تم تأكيد رقم الهاتف
    /// Phone number confirmed status
    /// </summary>
    [Display(Name = "هل تم تأكيد رقم الهاتف")]
    public bool PhoneNumberConfirmed { get; set; } = false;

    /// <summary>
    /// هل تم التحقق من رقم الهاتف
    /// Is phone number verified
    /// </summary>
    [Display(Name = "هل تم التحقق من رقم الهاتف")]
    public bool IsPhoneNumberVerified { get; set; } = false;

    /// <summary>
    /// تاريخ التحقق من رقم الهاتف
    /// Phone number verification date
    /// </summary>
    [Display(Name = "تاريخ التحقق من رقم الهاتف")]
    public DateTime? PhoneNumberVerifiedAt { get; set; }

    /// <summary>
    /// رمز تأكيد رقم الهاتف
    /// Phone number confirmation code
    /// </summary>
    [Display(Name = "رمز تأكيد رقم الهاتف")]
    public string? PhoneNumberConfirmationCode { get; set; }

    /// <summary>
    /// تاريخ انتهاء صلاحية رمز تأكيد رقم الهاتف
    /// Expiration date of the phone number confirmation code
    /// </summary>
    [Display(Name = "تاريخ انتهاء صلاحية رمز تأكيد رقم الهاتف")]
    public DateTime? PhoneNumberConfirmationCodeExpires { get; set; }

    /// <summary>
    /// إعدادات المستخدم بصيغة JSON
    /// User settings in JSON format
    /// </summary>
    [Display(Name = "إعدادات المستخدم بصيغة JSON")]
    public string SettingsJson { get; set; } = "{}";

    /// <summary>
    /// قائمة المفضلة للمستخدم بصيغة JSON
    /// User favorites list in JSON format
    /// </summary>
    [Display(Name = "قائمة المفضلة للمستخدم بصيغة JSON")]
    public string FavoritesJson { get; set; } = "[]";

    /// <summary>
    /// معرف المنطقة الزمنية للمستخدم
    /// </summary>
    [Display(Name = "معرف المنطقة الزمنية للمستخدم")]
    public string? TimeZoneId { get; set; }
    
    /// <summary>
    /// الدولة
    /// </summary>
    [Display(Name = "الدولة")]
    public string? Country { get; set; }
    
    /// <summary>
    /// المدينة
    /// </summary>
    [Display(Name = "المدينة")]
    public string? City { get; set; }

    /// <summary>
    /// البلاغات التي قام بها المستخدم
    /// Reports filed by the user
    /// </summary>
    [Display(Name = "البلاغات التي قام بها المستخدم")]
    public virtual ICollection<Report> ReportsMade { get; set; } = new List<Report>();

    /// <summary>
    /// البلاغات المقدمة ضد المستخدم
    /// Reports filed against the user
    /// </summary>
    [Display(Name = "البلاغات المقدمة ضد المستخدم")]
    public virtual ICollection<Report> ReportsAgainstUser { get; set; } = new List<Report>();
    
} 