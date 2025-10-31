using System;
using YemenBooking.Core.Enums;

namespace YemenBooking.Application.Features.Staffs.DTOs {
    /// <summary>
    /// DTO لبيانات الموظف
    /// DTO for staff data
    /// </summary>
    public class StaffDto
    {
        /// <summary>
        /// معرف الموظف
        /// Staff identifier
        /// </summary>
        public Guid Id { get; set; }

        /// <summary>
        /// معرف المستخدم
        /// User identifier
        /// </summary>
        public Guid UserId { get; set; }

        /// <summary>
        /// اسم المستخدم
        /// User name
        /// </summary>
        public string UserName { get; set; }

        /// <summary>
        /// معرف الكيان
        /// Property identifier
        /// </summary>
        public Guid PropertyId { get; set; }

        /// <summary>
        /// اسم الكيان
        /// Property name
        /// </summary>
        public string PropertyName { get; set; }

        /// <summary>
        /// منصب الموظف
        /// Staff position
        /// </summary>
        public StaffPosition Position { get; set; }

        /// <summary>
        /// الصلاحيات
        /// Permissions (JSON)
        /// </summary>
        public string Permissions { get; set; }
    }
} 