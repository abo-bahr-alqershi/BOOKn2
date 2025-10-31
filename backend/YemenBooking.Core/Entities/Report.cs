using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace YemenBooking.Core.Entities
{
/// <summary>
    /// كيان البلاغات لإدارة بلاغات المستخدمين عن المحتوى والسلوك
/// </summary>
[Display(Name = "كيان البلاغات لإدارة بلاغات المستخدمين عن المحتوى والسلوك")]
public class Report : BaseEntity<Guid>
{
    /// <summary>
    /// معرف المستخدم المبلغ
    /// </summary>
    [Display(Name = "معرف المستخدم المبلغ")]
    public Guid ReporterUserId { get; set; }

        /// <summary>
        /// المستخدم المبلغ
        /// </summary>
        [Display(Name = "المستخدم المبلغ")]
        [ForeignKey(nameof(ReporterUserId))]
        public User ReporterUser { get; set; }

    /// <summary>
    /// معرف المستخدم المبلغ عنه (اختياري)
    /// </summary>
    [Display(Name = "معرف المستخدم المبلغ عنه")]
    public Guid? ReportedUserId { get; set; }

        /// <summary>
        /// المستخدم المبلغ عنه
        /// </summary>
        [Display(Name = "المستخدم المبلغ عنه")]
        [ForeignKey(nameof(ReportedUserId))]
        public User ReportedUser { get; set; }

    /// <summary>
    /// معرف الكيان المبلغ عنه (اختياري)
    /// </summary>
    [Display(Name = "معرف الكيان المبلغ عنه")]
    public Guid? ReportedPropertyId { get; set; }

        /// <summary>
        /// الكيان المبلغ عنه
        /// </summary>
        [Display(Name = "الكيان المبلغ عنه")]
        [ForeignKey(nameof(ReportedPropertyId))]
        public Property ReportedProperty { get; set; }

    /// <summary>
    /// سبب البلاغ
        /// </summary>
        [Display(Name = "سبب البلاغ")]
        [Required]
        public string Reason { get; set; }

        /// <summary>
        /// الوصف التفصيلي للبلاغ
        /// </summary>
        [Display(Name = "الوصف التفصيلي للبلاغ")]
        public string Description { get; set; }

        /// <summary>
        /// حالة البلاغ (pending, reviewed, resolved, dismissed, escalated)
    /// </summary>
        [Display(Name = "حالة البلاغ")]
        [Required]
        public string Status { get; set; } = "pending";

    /// <summary>
        /// ملاحظات الإجراء من قبل الإدارة
    /// </summary>
        [Display(Name = "ملاحظات الإجراء من قبل الإدارة")]
        public string ActionNote { get; set; }

    /// <summary>
        /// معرف مسؤول الإدارة الذي اتخذ الإجراء (اختياري)
    /// </summary>
        [Display(Name = "معرف مسؤول الإدارة الذي اتخذ الإجراء")]
        public Guid? AdminId { get; set; }
    }
} 