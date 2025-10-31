using System;
using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Reports.Commands.ManageReports
{
    /// <summary>
    /// أمر لاتخاذ إجراء على البلاغ (مراجعة، حله، رفضه، تصعيده، فتح تحقيق)
    /// Command to take action on a report
    /// </summary>
    public class TakeReportActionCommand : IRequest<ResultDto<bool>>
    {
        /// <summary>
        /// معرف البلاغ
        /// </summary>
        public Guid Id { get; set; }

        /// <summary>
        /// نوع الإجراء (review, resolve, dismiss, escalate, investigate)
        /// </summary>
        public string Action { get; set; } = string.Empty;

        /// <summary>
        /// ملاحظات الإجراء (اختياري)
        /// </summary>
        public string? ActionNote { get; set; }

        /// <summary>
        /// معرف مسؤول الإدارة الذي اتخذ الإجراء
        /// </summary>
        public Guid AdminId { get; set; }
    }
} 