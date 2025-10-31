using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Expressions;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Specifications
{
    /// <summary>
    /// معاملات البحث في المستخدمين
    /// User search parameters
    /// </summary>
    public class UserSearchParameters
    {
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 10;
        public string? SearchTerm { get; set; }
        public string? SortBy { get; set; }
        public bool IsAscending { get; set; } = true;
        public Guid? RoleId { get; set; }
        public bool? IsActive { get; set; }
        public DateTime? CreatedAfter { get; set; }
        public DateTime? CreatedBefore { get; set; }
        public DateTime? LastLoginAfter { get; set; }
        public string? LoyaltyTier { get; set; }
        public decimal? MinTotalSpent { get; set; }
    }

    /// <summary>
    /// مواصفة البحث في المستخدمين
    /// Specification for searching users
    /// </summary>
    public class UserSearchSpecification : BaseSpecification<User>
    {
        public UserSearchSpecification(UserSearchParameters parameters)
            : base()
        {
            // المعايير الأساسية: المستخدمين غير المحذوفين
            AddCriteria(u => !u.IsDeleted);

            // البحث النصي بالاسم أو البريد الإلكتروني
            if (!string.IsNullOrWhiteSpace(parameters.SearchTerm))
            {
                var term = parameters.SearchTerm.Trim().ToLower();
                AddCriteria(u => u.Name.ToLower().Contains(term) || u.Email.ToLower().Contains(term));
            }

            // فلترة بالدور
            if (parameters.RoleId.HasValue)
                AddCriteria(u => u.UserRoles.Any(ur => ur.RoleId == parameters.RoleId.Value));

            // حالة التفعيل
            if (parameters.IsActive.HasValue)
                AddCriteria(u => u.IsActive == parameters.IsActive.Value);

            // فلترة بتاريخ الإنشاء
            if (parameters.CreatedAfter.HasValue)
                AddCriteria(u => u.CreatedAt >= parameters.CreatedAfter.Value);
            if (parameters.CreatedBefore.HasValue)
                AddCriteria(u => u.CreatedAt <= parameters.CreatedBefore.Value);

            // فلترة بآخر تسجيل دخول
            if (parameters.LastLoginAfter.HasValue)
                AddCriteria(u => u.LastLoginDate.HasValue && u.LastLoginDate.Value >= parameters.LastLoginAfter.Value);

            // فئة الولاء
            if (!string.IsNullOrWhiteSpace(parameters.LoyaltyTier))
                AddCriteria(u => u.LoyaltyTier == parameters.LoyaltyTier);

            // الحد الأدنى للإنفاق الكلي
            if (parameters.MinTotalSpent.HasValue)
                AddCriteria(u => u.TotalSpent >= parameters.MinTotalSpent.Value);

            // تضمينات
            AddInclude(u => u.UserRoles);
            AddInclude("UserRoles.Role");

            // الترتيب
            if (!string.IsNullOrWhiteSpace(parameters.SortBy))
            {
                switch (parameters.SortBy.ToLower())
                {
                    case "name":
                        if (parameters.IsAscending) ApplyOrderBy(u => u.Name);
                        else ApplyOrderByDescending(u => u.Name);
                        break;
                    case "email":
                        if (parameters.IsAscending) ApplyOrderBy(u => u.Email);
                        else ApplyOrderByDescending(u => u.Email);
                        break;
                    case "created":
                        if (parameters.IsAscending) ApplyOrderBy(u => u.CreatedAt);
                        else ApplyOrderByDescending(u => u.CreatedAt);
                        break;
                    case "spent":
                        if (parameters.IsAscending) ApplyOrderBy(u => u.TotalSpent);
                        else ApplyOrderByDescending(u => u.TotalSpent);
                        break;
                    case "lastlogin":
                        if (parameters.IsAscending) ApplyOrderBy(u => u.LastLoginDate);
                        else ApplyOrderByDescending(u => u.LastLoginDate);
                        break;
                    default:
                        if (parameters.IsAscending) ApplyOrderBy(u => u.Name);
                        else ApplyOrderByDescending(u => u.Name);
                        break;
                }
            }

            // التصفح
            if (parameters.PageNumber > 0 && parameters.PageSize > 0)
                ApplyPaging(parameters.PageNumber, parameters.PageSize);

            // تحسين الأداء
            ApplyNoTracking();
            ApplySplitQuery();
        }
    }
} 