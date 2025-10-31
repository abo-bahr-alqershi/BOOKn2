using System;

namespace YemenBooking.Application.Features.Users.DTOs {
    /// <summary>
    /// DTO لبيانات الدور
    /// DTO for role data
    /// </summary>
    public class RoleDto
    {
        /// <summary>
        /// المعرف الفريد للدور
        /// Role unique identifier
        /// </summary>
        public Guid Id { get; set; }

        /// <summary>
        /// اسم الدور
        /// Role name
        /// </summary>
        public string Name { get; set; }
    }
} 