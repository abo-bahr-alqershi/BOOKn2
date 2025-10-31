using System;
using System.Collections.Generic;
using YemenBooking.Core.Entities;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
namespace YemenBooking.Application.Common.Interfaces
{
    /// <summary>
    /// واجهة خدمة المستخدم الحالي
    /// Interface for current user service
    /// </summary>
    public interface ICurrentUserService
    {
        /// <summary>
        /// معرف المستخدم الحالي
        /// Identifier of the current user
        /// </summary>
        Guid UserId { get; }

        /// <summary>
        /// اسم المستخدم الحالي
        /// Username of the current user
        /// </summary>
        string Username { get; }

        /// <summary>
        /// الدور الخاص بالمستخدم الحالي
        /// Role of the current user
        /// </summary>
        string Role { get; }

        /// <summary>
        /// نوع الحساب الموحّد (Admin, Owner, Staff, Customer)
        /// Unified account role
        /// </summary>
        string AccountRole { get; }

        /// <summary>
        /// قائمة الأذونات الخاصة بالمستخدم الحالي
        /// Permissions of the current user
        /// </summary>
        IEnumerable<string> Permissions { get; }

        /// <summary>
        /// قائمة الأدوار الخاصة بالمستخدم الحالي
        /// User roles of the current user
        /// </summary>
        IEnumerable<string> UserRoles { get; }

        /// <summary>
        /// معرف التتبّع لربط الطلبات
        /// Correlation identifier for tracing
        /// </summary>
        string CorrelationId { get; }

        /// <summary>
        /// معرف الكيان المرتبط بالمستخدم (إن وجد)
        /// Property ID related to the user (if owner or staff)
        /// </summary>
        Guid? PropertyId { get; }

        /// <summary>
        /// اسم الكيان المرتبط بالمستخدم (إن وجد)
        /// Property name related to the user (if owner or staff)
        /// </summary>
        string? PropertyName { get; }

        /// <summary>
        /// عملة العقار المرتبط بالمستخدم (إن وجدت)
        /// Property currency code (if any)
        /// </summary>
        string? PropertyCurrency { get; }

        /// <summary>
        /// معرف موظف الكيان المرتبط بالمستخدم (إن وجد)
        /// Property name related to the user (if owner or staff)
        /// </summary>
        Guid? StaffId { get; }

        /// <summary>
        /// التحقق مما إذا كان المستخدم الحالي موظفاً في الكيان المحدد
        /// Checks if the current user is staff of the specified property
        /// </summary>
        bool IsStaffInProperty(Guid propertyId);

        Task<User> GetCurrentUserAsync(CancellationToken cancellationToken = default);

        /// <summary>
        /// التحقق بشكل غير متزامن مما إذا كان المستخدم الحالي يمتلك الدور المحدد
        /// </summary>
        Task<bool> IsInRoleAsync(string role);

        /// <summary>
        /// الحصول على معلومات الموقع الجغرافي للمستخدم
        /// </summary>
        Task<UserLocationInfo> GetUserLocationAsync();

        /// <summary>
        /// تحويل التوقيت من UTC إلى التوقيت المحلي للمستخدم
        /// </summary>
        Task<DateTime> ConvertFromUtcToUserLocalAsync(DateTime utcDateTime);

        /// <summary>
        /// تحويل التوقيت من التوقيت المحلي للمستخدم إلى UTC
        /// </summary>
        Task<DateTime> ConvertFromUserLocalToUtcAsync(DateTime localDateTime);

        /// <summary>
        /// الحصول على معرف المنطقة الزمنية للمستخدم
        /// </summary>
        Task<string> GetUserTimeZoneIdAsync();

        /// <summary>
        /// الحصول على الإزاحة الزمنية الحالية للمستخدم من UTC
        /// </summary>
        Task<TimeSpan> GetUserTimeZoneOffsetAsync();
    }

    public class UserLocationInfo
    {
        public string Country { get; set; }
        public string CountryCode { get; set; }
        public string City { get; set; }
        public string TimeZoneId { get; set; }
        public TimeSpan UtcOffset { get; set; }
        public string TimeZoneName { get; set; }
        public bool IsDaylightSaving { get; set; }
        public string Source { get; set; } // "Headers", "UserProfile", "IP", "Default"
    }
} 