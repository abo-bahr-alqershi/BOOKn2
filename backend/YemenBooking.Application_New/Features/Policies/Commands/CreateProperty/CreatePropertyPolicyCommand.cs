using System;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Enums;

namespace YemenBooking.Application.Features.Policies.Commands.CreateProperty
{
    /// <summary>
    /// أمر لإنشاء سياسة جديدة للكيان
    /// Command to create a new property policy
    /// </summary>
    public class CreatePropertyPolicyCommand : IRequest<ResultDto<Guid>>
    {
        /// <summary>
        /// معرف الكيان
        /// </summary>
        public Guid PropertyId { get; set; }

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
        public int CancellationWindowDays { get; set; }

        /// <summary>
        /// يتطلب الدفع الكامل قبل التأكيد
        /// </summary>
        public bool RequireFullPaymentBeforeConfirmation { get; set; }

        /// <summary>
        /// الحد الأدنى لنسبة الدفع المقدمة
        /// </summary>
        public decimal MinimumDepositPercentage { get; set; }

        /// <summary>
        /// الحد الأدنى للساعات قبل تسجيل الوصول
        /// </summary>
        public int MinHoursBeforeCheckIn { get; set; }
    }
} 