using System;
using System.Linq.Expressions;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Specifications
{
    /// <summary>
    /// معاملات البحث في الإشعارات
    /// Notification search parameters
    /// </summary>
    public class NotificationSearchParameters
    {
        public Guid? RecipientId { get; set; }
        public string? NotificationType { get; set; }
        public string? Status { get; set; }
        public DateTime? SentAfter { get; set; }
        public DateTime? SentBefore { get; set; }
        public string? SortBy { get; set; }
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 10;
    }

    /// <summary>
    /// مواصفة البحث في الإشعارات
    /// Specification for searching notifications
    /// </summary>
    public class NotificationSearchSpecification : BaseSpecification<Notification>
    {
        public NotificationSearchSpecification(NotificationSearchParameters parameters)
            : base()
        {
            AddCriteria(n => true);

            if (parameters.RecipientId.HasValue)
                AddCriteria(n => n.RecipientId == parameters.RecipientId.Value);

            if (!string.IsNullOrWhiteSpace(parameters.NotificationType))
            {
                var type = parameters.NotificationType.Trim().ToLower();
                AddCriteria(n => n.Type.ToLower() == type);
            }

            if (!string.IsNullOrWhiteSpace(parameters.Status))
            {
                var st = parameters.Status.Trim().ToLower();
                AddCriteria(n => n.Status.ToLower() == st);
            }

            if (parameters.SentAfter.HasValue)
                AddCriteria(n => n.CreatedAt >= parameters.SentAfter.Value);

            if (parameters.SentBefore.HasValue)
                AddCriteria(n => n.CreatedAt <= parameters.SentBefore.Value);

            // الترتيب حسب المتغير المحدد
            if (!string.IsNullOrWhiteSpace(parameters.SortBy))
            {
                switch (parameters.SortBy.Trim().ToLower())
                {
                    case "sent_date": ApplyOrderBy(n => n.CreatedAt); break;
                    case "status": ApplyOrderBy(n => n.Status); break;
                    case "recipient_name": ApplyOrderBy(n => n.Recipient.Name); break;
                    default: ApplyOrderBy(n => n.CreatedAt); break;
                }
            }

            if (parameters.PageNumber > 0 && parameters.PageSize > 0)
                ApplyPaging(parameters.PageNumber, parameters.PageSize);

            ApplyNoTracking();
            ApplySplitQuery();
        }
    }
} 