using System;

namespace YemenBooking.Application.Features.Reviews.DTOs {
    /// <summary>
    /// DTO لاستجابة إرسال المراجعة
    /// Submit review response DTO
    /// </summary>
    public class SubmitReviewResponse
    {
        /// <summary>
        /// معرف المراجعة
        /// Review ID
        /// </summary>
        public Guid ReviewId { get; set; }

        /// <summary>
        /// رسالة النجاح
        /// Success message
        /// </summary>
        public string Message { get; set; } = string.Empty;

        /// <summary>
        /// هل تم إرسال المراجعة بنجاح
        /// Whether review was submitted successfully
        /// </summary>
        public bool IsSuccess { get; set; }

        /// <summary>
        /// التقييم المرسل
        /// Submitted rating
        /// </summary>
        public int Rating { get; set; }

        /// <summary>
        /// نص المراجعة
        /// Review text
        /// </summary>
        public string ReviewText { get; set; } = string.Empty;

        /// <summary>
        /// تاريخ الإرسال
        /// Submission date
        /// </summary>
        public DateTime SubmissionDate { get; set; }

        /// <summary>
        /// هل المراجعة قيد المراجعة
        /// Whether review is under moderation
        /// </summary>
        public bool IsUnderModeration { get; set; }

        /// <summary>
        /// نقاط المكافآت المكتسبة
        /// Reward points earned
        /// </summary>
        public int RewardPointsEarned { get; set; }
    }
}
