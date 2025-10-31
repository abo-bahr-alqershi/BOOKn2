using System;

namespace YemenBooking.Application.Common.Models
{
    /// <summary>
    /// DTO للمستندات القانونية
    /// Legal document DTO
    /// </summary>
    public class LegalDocumentDto
    {
        /// <summary>
        /// معرف المستند
        /// Document identifier
        /// </summary>
        public Guid Id { get; set; }

        /// <summary>
        /// نوع المستند
        /// Document type
        /// </summary>
        public string Type { get; set; } = string.Empty;

        /// <summary>
        /// عنوان المستند
        /// Document title
        /// </summary>
        public string Title { get; set; } = string.Empty;

        /// <summary>
        /// محتوى المستند
        /// Document content
        /// </summary>
        public string Content { get; set; } = string.Empty;

        /// <summary>
        /// اللغة
        /// Language
        /// </summary>
        public string Language { get; set; } = "ar";

        /// <summary>
        /// الإصدار
        /// Version
        /// </summary>
        public string Version { get; set; } = "1.0";

        /// <summary>
        /// تاريخ آخر تحديث
        /// Last updated date
        /// </summary>
        public DateTime LastUpdated { get; set; }

        /// <summary>
        /// هل المستند نشط
        /// Whether the document is active
        /// </summary>
        public bool IsActive { get; set; }
    }
}
