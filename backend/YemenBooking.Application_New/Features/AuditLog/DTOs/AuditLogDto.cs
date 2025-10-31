using System;
using System.Collections.Generic;

namespace YemenBooking.Application.Features.AuditLog.DTOs
{
    /// <summary>
    /// DTO لسجلات التدقيق
    /// DTO for audit log entries
    /// </summary>
    public class AuditLogDto
    {
        /// <summary>
        /// المعرف الفريد للسجل
        /// Log identifier
        /// </summary>
        public Guid Id { get; set; }

        /// <summary>
        /// اسم الجدول أو الكيان
        /// Name of the table or entity
        /// </summary>
        public string TableName { get; set; } = string.Empty;

        /// <summary>
        /// العملية (إنشاء، تحديث، حذف)
        /// Action (Create, Update, Delete)
        /// </summary>
        public string Action { get; set; } = string.Empty;

        /// <summary>
        /// معرف السجل المتأثر
        /// ID of the affected record
        /// </summary>
        public Guid RecordId { get; set; }

        /// <summary>
        /// معرف المستخدم الذي قام بالتغيير
        /// User ID who performed the change
        /// </summary>
        public Guid UserId { get; set; }

        /// <summary>
        /// وصف التغييرات
        /// Description of the changes
        /// </summary>
        public string Changes { get; set; } = string.Empty;

        /// <summary>
        /// تاريخ العملية
        /// Timestamp of the action
        /// </summary>
        public DateTime Timestamp { get; set; }

        /// <summary>
        /// Old values (JSON)
        /// </summary>
        public Dictionary<string, object>? OldValues { get; set; }

        /// <summary>
        /// New values (JSON)
        /// </summary>
        public Dictionary<string, object>? NewValues { get; set; }

        /// <summary>
        /// Username who performed the action
        /// </summary>
        public string Username { get; set; } = string.Empty;

        /// <summary>
        /// Additional notes
        /// </summary>
        public string? Notes { get; set; }

        /// <summary>
        /// Metadata (JSON)
        /// </summary>
        public Dictionary<string, object>? Metadata { get; set; }

        /// <summary>
        /// Indicates if operation was slow
        /// </summary>
        public bool IsSlowOperation { get; set; }

        /// <summary>
        /// اسم السجل المتأثر
        /// Name of the affected record
        /// </summary>
        public string RecordName { get; set; } = string.Empty;
    }
} 