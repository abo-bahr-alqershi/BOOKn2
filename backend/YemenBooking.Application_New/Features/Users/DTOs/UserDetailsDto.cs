using System;

namespace YemenBooking.Application.Features.Users.DTOs {
    /// <summary>بيانات تفصيلية عن المستخدم</summary>
    public class UserDetailsDto
    {
        // معلومات مشتركة لجميع المستخدمين
        /// <summary>معرف المستخدم</summary>
        public Guid Id { get; set; }

        /// <summary>اسم المستخدم</summary>
        public string UserName { get; set; }

        /// <summary>رابط صورة المستخدم</summary>
        public string AvatarUrl { get; set; }

        /// <summary>البريد الإلكتروني</summary>
        public string Email { get; set; }

        /// <summary>رقم الهاتف</summary>
        public string PhoneNumber { get; set; }

        /// <summary>تاريخ إنشاء الحساب</summary>
        public DateTime CreatedAt { get; set; }

        /// <summary>هل الحساب مفعل</summary>
        public bool IsActive { get; set; }

        /// <summary>تاريخ آخر نشاط للمستخدم</summary>
        public DateTime? LastSeen { get; set; }

        /// <summary>تاريخ آخر تسجيل دخول</summary>
        public DateTime? LastLoginDate { get; set; }

        // بيانات حساب العميل وايضا الكيان
        /// <summary>إجمالي عدد الحجوزات للمستخدم في حال كان الحساب عميل</summary>
        /// <summary>إجمالي عدد الحجوزات للكيان في حال كان الحساب مالك او موظف</summary>
        public int BookingsCount { get; set; }

        /// <summary>عدد الحجوزات الملغاة للمستخدم في حال كان الحساب عميل</summary>
        /// <summary>عدد الحجوزات الملغاة للكيان في حال كان الحساب مالك او موظف</summary>
        public int CanceledBookingsCount { get; set; }

        /// <summary>عدد الحجوزات المعلقة للمستخدم في حال كان الحساب عميل</summary>
        /// <summary>عدد الحجوزات المعلقة للكيان في حال كان الحساب مالك او موظف</summary>
        public int PendingBookingsCount { get; set; }

        /// <summary>تاريخ أول حجز للمستخدم في حال كان الحساب عميل</summary>
        /// <summary>تاريخ أول حجز للكيان في حال كان الحساب مالك او موظف</summary>
        public DateTime? FirstBookingDate { get; set; }

        /// <summary>تاريخ آخر حجز للمستخدم في حال كان الحساب عميل</summary>
        /// <summary>تاريخ آخر حجز للكيان في حال كان الحساب مالك او موظف</summary>
        public DateTime? LastBookingDate { get; set; }

        /// <summary>عدد البلاغات التي أنشأها المستخدم في حال كان الحساب عميل</summary>
        /// <summary>عدد البلاغات التي أنشأها الفندق (سواء مالك او موظفين) في حال كان الحساب مالك او موظف</summary>
        public int ReportsCreatedCount { get; set; }

        /// <summary>عدد البلاغات ضده (على المستخدم) في حال كان الحساب عميل</summary>
        /// <summary>عدد البلاغات ضده (على الكيان) في حال كان الحساب مالك او موظف</summary>
        public int ReportsAgainstCount { get; set; }

        /// <summary>إجمالي المدفوعات للمستخدم في حال كان الحساب عميل</summary>
        /// <summary>إجمالي المدفوعات للكيان (سواء مالك او موظفين) في حال كان الحساب مالك او موظف</summary>
        public decimal TotalPayments { get; set; }

        /// <summary>إجمالي المردودات للمستخدم في حال كان الحساب عميل</summary>
        /// <summary>إجمالي المردودات للكيان (سواء مالك او موظفين) في حال كان الحساب مالك او موظف</summary>
        public decimal TotalRefunds { get; set; }

        /// <summary>عدد المراجعات التي أجرىها المستخدم في حال كان الحساب عميل</summary>
        /// <summary>عدد المراجعات التي أجراها العملاء على الكيان في حال كان الحساب مالك او موظف</summary>
        public int ReviewsCount { get; set; }

        // بيانات حساب المالك أو الموظف (Owner/Staff-only)
        /// <summary>وظيفة المستخدم (Owner أو Staff)</summary>
        public string Role { get; set; }

        /// <summary>معرف الكيان المرتبط</summary>
        public Guid? PropertyId { get; set; }

        /// <summary>اسم الكيان المرتبط</summary>
        public string PropertyName { get; set; }

        /// <summary>عدد الوحدات في الكيان</summary>
        public int? UnitsCount { get; set; }

        /// <summary>عدد صور الكيان</summary>
        public int? PropertyImagesCount { get; set; }

        /// <summary>عدد صور الوحدات</summary>
        public int? UnitImagesCount { get; set; }

        /// <summary>صافي الإيراد للكيان</summary>
        public decimal? NetRevenue { get; set; }

        /// <summary>عدد الردود على البلاغات (غير مستخدم حاليًا)</summary>
        public int? RepliesCount { get; set; }
    }
} 