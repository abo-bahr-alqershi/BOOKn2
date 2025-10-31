// using System;
// using System.Collections.Generic;
// using System.Threading;
// using System.Threading.Tasks;
// using YemenBooking.Core.Entities;

// namespace YemenBooking.Core.Interfaces.Repositories;

// /// <summary>
// /// واجهة مستودع قواعد التسعير
// /// Pricing rule repository interface
// /// </summary>
// public interface IPricingRuleRepository : IRepository<PricingRule>
// {
//     /// <summary>
//     /// إنشاء قاعدة تسعير جديدة
//     /// Create new pricing rule
//     /// </summary>
//     Task<PricingRule> CreatePricingRuleAsync(PricingRule pricingRule, CancellationToken cancellationToken = default);

//     /// <summary>
//     /// الحصول على قاعدة التسعير بواسطة المعرف
//     /// Get pricing rule by id
//     /// </summary>
//     Task<PricingRule?> GetPricingRuleByIdAsync(Guid pricingRuleId, CancellationToken cancellationToken = default);

//     /// <summary>
//     /// تحديث قاعدة التسعير
//     /// Update pricing rule
//     /// </summary>
//     Task<PricingRule> UpdatePricingRuleAsync(PricingRule pricingRule, CancellationToken cancellationToken = default);

//     /// <summary>
//     /// حذف قاعدة التسعير
//     /// Delete pricing rule
//     /// </summary>
//     Task<bool> DeletePricingRuleAsync(Guid pricingRuleId, CancellationToken cancellationToken = default);

//     /// <summary>
//     /// الحصول على قواعد التسعير لوحدة معينة
//     /// Get pricing rules by unit
//     /// </summary>
//     Task<IEnumerable<PricingRule>> GetPricingRulesByUnitAsync(Guid unitId, DateTime? fromDate = null, DateTime? toDate = null, CancellationToken cancellationToken = default);

//     /// <summary>
//     /// التحقق من وجود تعارض في قواعد التسعير للفترة المحددة
//     /// Check for overlapping pricing rules in the specified period
//     /// </summary>
//     Task<bool> HasOverlapAsync(Guid unitId, DateTime startDate, DateTime endDate, CancellationToken cancellationToken = default);
// } 
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces;

namespace YemenBooking.Core.Interfaces.Repositories;

public interface IPricingRuleRepository : IRepository<PricingRule>
{
    Task<IEnumerable<PricingRule>> GetByUnitIdAsync(Guid unitId, DateTime? startDate = null, DateTime? endDate = null);
    Task<IEnumerable<PricingRule>> GetActiveRulesAsync(Guid unitId, DateTime date);
    Task<PricingRule?> GetPriceForDateAsync(Guid unitId, DateTime date);
    Task<IEnumerable<PricingRule>> GetByDateRangeAsync(Guid unitId, DateTime startDate, DateTime endDate);
    Task BulkCreateAsync(IEnumerable<PricingRule> rules);
    Task BulkUpdateAsync(IEnumerable<PricingRule> rules);
    Task DeleteRangeAsync(Guid unitId, DateTime startDate, DateTime endDate);
    Task<Dictionary<DateTime, decimal>> GetPricingCalendarAsync(Guid unitId, int year, int month);
}
