using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace YemenBooking.Core.Entities
{
    /// <summary>
    /// كيان بيانات تعريف الفهارس
    /// يحتفظ بمعلومات آخر تحديث وحالة كل فهرس للتحديث التدريجي
    /// Index metadata entity for incremental indexing tracking
    /// </summary>
    [Table("IndexMetadata")]
    public class IndexMetadata
    {
        /// <summary>
        /// نوع الفهرس (مفتاح أساسي)
        /// Index type - primary key (price, city, amenities, dynamic-field-{fieldId}, etc.)
        /// </summary>
        [Key]
        [Required]
        [MaxLength(100)]
        public string IndexType { get; set; } = string.Empty;

        /// <summary>
        /// آخر وقت تحديث للفهرس
        /// Last time this index was updated
        /// </summary>
        [Required]
        public DateTime LastUpdateTime { get; set; } = DateTime.UtcNow;

        /// <summary>
        /// عدد السجلات في الفهرس
        /// Total number of records in the index
        /// </summary>
        [Required]
        public int TotalRecords { get; set; } = 0;

        /// <summary>
        /// آخر معرف تم معالجته (للتحديث التدريجي)
        /// Last processed entity ID for incremental updates
        /// </summary>
        public Guid? LastProcessedId { get; set; }

        /// <summary>
        /// حالة الفهرس
        /// Index status (Active, Building, Error, Disabled)
        /// </summary>
        [Required]
        [MaxLength(50)]
        public string Status { get; set; } = "Active";

        /// <summary>
        /// رقم الإصدار للتأكد من التزامن
        /// Version number for concurrency control
        /// </summary>
        [Required]
        public long Version { get; set; } = 1;

        /// <summary>
        /// حجم الفهرس بالبايت
        /// Index file size in bytes
        /// </summary>
        public long FileSizeBytes { get; set; } = 0;

        /// <summary>
        /// عدد العمليات منذ آخر تحسين
        /// Number of operations since last optimization
        /// </summary>
        public int OperationsSinceOptimization { get; set; } = 0;

        /// <summary>
        /// آخر وقت تحسين للفهرس
        /// Last time the index was optimized
        /// </summary>
        public DateTime? LastOptimizationTime { get; set; }

        /// <summary>
        /// معلومات إضافية بصيغة JSON
        /// Additional metadata in JSON format
        /// </summary>
        [MaxLength(2000)]
        public string? Metadata { get; set; }

        /// <summary>
        /// رسالة الخطأ الأخيرة (إن وجدت)
        /// Last error message if any
        /// </summary>
        [MaxLength(1000)]
        public string? LastErrorMessage { get; set; }

        /// <summary>
        /// عدد محاولات إعادة البناء
        /// Number of rebuild attempts
        /// </summary>
        public int RebuildAttempts { get; set; } = 0;

        /// <summary>
        /// تاريخ الإنشاء
        /// Creation timestamp
        /// </summary>
        [Required]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        /// <summary>
        /// تاريخ آخر تعديل
        /// Last update timestamp
        /// </summary>
        [Required]
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        /// <summary>
        /// تحديث طابع زمني التعديل
        /// Update the UpdatedAt timestamp
        /// </summary>
        public void MarkAsUpdated()
        {
            UpdatedAt = DateTime.UtcNow;
            Version++;
        }

        /// <summary>
        /// تحديد حالة الفهرس كنشط
        /// Mark index as active
        /// </summary>
        public void MarkAsActive(int recordCount, long fileSize)
        {
            Status = "Active";
            TotalRecords = recordCount;
            FileSizeBytes = fileSize;
            LastErrorMessage = null;
            MarkAsUpdated();
        }

        /// <summary>
        /// تحديد حالة الفهرس كخطأ
        /// Mark index as error
        /// </summary>
        public void MarkAsError(string errorMessage)
        {
            Status = "Error";
            LastErrorMessage = errorMessage;
            RebuildAttempts++;
            MarkAsUpdated();
        }

        /// <summary>
        /// تحديد حالة الفهرس كقيد البناء
        /// Mark index as building
        /// </summary>
        public void MarkAsBuilding()
        {
            Status = "Building";
            LastErrorMessage = null;
            MarkAsUpdated();
        }
    }
}