using YemenBooking.Application.Features.Policies.DTOs;

namespace YemenBooking.Application.Features.Properties.DTOs
{
    /// <summary>
    /// DTO لسياسة الكيان
    /// DTO for property policy
    /// </summary>
    using System.Collections.Generic;
using System;

    public class PropertyPolicyDto
    {
        /// <summary>
        /// نوع السياسة
        /// Policy type
        /// </summary>
        public string PolicyType { get; set; } = string.Empty;

        /// <summary>
        /// محتوى السياسة
        /// Policy content
        /// </summary>
        public string PolicyContent { get; set; } = string.Empty;

        /// <summary>
        /// هل نشطة
        /// Is active
        /// </summary>
        public bool IsActive { get; set; } = true;

        // ---------------- Mobile App specific properties ----------------
        /// <summary>
        /// معرف السياسة
        /// Policy identifier
        /// </summary>
        public Guid Id { get; set; }

        /// <summary>
        /// نوع السياسة (check_in, check_out, cancellation, etc.)
        /// Policy type
        /// </summary>
        public string Type { get; set; } = string.Empty;

        /// <summary>
        /// وصف السياسة
        /// Policy description
        /// </summary>
        public string Description { get; set; } = string.Empty;

        /// <summary>
        /// قواعد السياسة (قابلة للتسلسل إلى JSON)
        /// Policy rules (serialisable to JSON)
        /// </summary>
        public Dictionary<string, object> Rules { get; set; } = new();
    }
} 