using System;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Enums;

namespace YemenBooking.Application.Features.Policies.Commands.UpdateProperty
{
    /// <summary>
    /// أمر لتحديث سياسة الكيان
    /// Command to update a property policy
    /// </summary>
    public class UpdatePropertyPolicyCommand : IRequest<ResultDto<bool>>
    {
        /// <summary>
        /// معرف السياسة
        /// </summary>
        public Guid PolicyId { get; set; }

        /// <summary>
        /// نوع السياسة
        /// </summary>
        public PolicyType Type { get; set; }

        /// <summary>
        /// الوصف
        /// </summary>
        public string Description { get; set; }

        /// <summary>
        /// القواعد
        /// </summary>
        public string Rules { get; set; }

        /// <summary>
        /// عدد أيام نافذة الإلغاء قبل تاريخ الوصول
        /// </summary>
        public int? CancellationWindowDays { get; set; }

        /// <summary>
        /// يتطلب الدفع الكامل قبل التأكيد
        /// </summary>
        public bool? RequireFullPaymentBeforeConfirmation { get; set; }

        /// <summary>
        /// الحد الأدنى لنسبة الدفع المقدمة
        /// </summary>
        public decimal? MinimumDepositPercentage { get; set; }

        /// <summary>
        /// الحد الأدنى للساعات قبل تسجيل الوصول
        /// </summary>
        public int? MinHoursBeforeCheckIn { get; set; }
    }
} 