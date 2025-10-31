using System;

namespace YemenBooking.Application.Features.Authentication.DTOs {
    /// <summary>
    /// استجابة حذف الحساب
    /// Delete account response DTO
    /// </summary>
    public class DeleteAccountResponse
    {
        /// <summary>
        /// نجاح العملية
        /// Operation success
        /// </summary>
        public bool Success { get; set; }
        
        /// <summary>
        /// رسالة النتيجة
        /// Result message
        /// </summary>
        public string Message { get; set; } = string.Empty;
        
        /// <summary>
        /// تاريخ حذف الحساب
        /// Account deletion date
        /// </summary>
        public DateTime? DeletionDate { get; set; }
        
        /// <summary>
        /// فترة الاسترداد (بالأيام)
        /// Recovery period in days
        /// </summary>
        public int RecoveryPeriodDays { get; set; } = 30;
        
        /// <summary>
        /// معرف عملية الحذف للمراجعة
        /// Deletion operation ID for audit
        /// </summary>
        public Guid? DeletionOperationId { get; set; }
    }
}
