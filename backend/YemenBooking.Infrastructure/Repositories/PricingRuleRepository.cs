// using System;
// using System.Collections.Generic;
// using System.Linq;
// using System.Threading;
// using System.Threading.Tasks;
// using Microsoft.EntityFrameworkCore;
// using YemenBooking.Core.Entities;
// using YemenBooking.Core.Interfaces.Repositories;
// using YemenBooking.Infrastructure.Data.Context;

// namespace YemenBooking.Infrastructure.Repositories
// {
//     /// <summary>
//     /// تنفيذ مستودع قواعد التسعير
//     /// Pricing rule repository implementation
//     /// </summary>
//     public class PricingRuleRepository : BaseRepository<PricingRule>, IPricingRuleRepository
//     {
//         public PricingRuleRepository(YemenBookingDbContext context) : base(context) { }

//         public async Task<PricingRule> CreatePricingRuleAsync(PricingRule pricingRule, CancellationToken cancellationToken = default)
//         {
//             await _dbSet.AddAsync(pricingRule, cancellationToken);
//             await _context.SaveChangesAsync(cancellationToken);
//             return pricingRule;
//         }

//         public async Task<PricingRule?> GetPricingRuleByIdAsync(Guid pricingRuleId, CancellationToken cancellationToken = default)
//             => await _dbSet.FindAsync(new object[] { pricingRuleId }, cancellationToken);

//         public async Task<PricingRule> UpdatePricingRuleAsync(PricingRule pricingRule, CancellationToken cancellationToken = default)
//         {
//             _dbSet.Update(pricingRule);
//             await _context.SaveChangesAsync(cancellationToken);
//             return pricingRule;
//         }

//         public async Task<bool> DeletePricingRuleAsync(Guid pricingRuleId, CancellationToken cancellationToken = default)
//         {
//             var existing = await GetPricingRuleByIdAsync(pricingRuleId, cancellationToken);
//             if (existing == null) return false;
//             _dbSet.Remove(existing);
//             await _context.SaveChangesAsync(cancellationToken);
//             return true;
//         }

//         public async Task<IEnumerable<PricingRule>> GetPricingRulesByUnitAsync(Guid unitId, DateTime? fromDate = null, DateTime? toDate = null, CancellationToken cancellationToken = default)
//         {
//             var query = _dbSet.AsQueryable().Where(p => p.UnitId == unitId);
//             if (fromDate.HasValue)
//                 query = query.Where(p => p.StartDate >= fromDate.Value);
//             if (toDate.HasValue)
//                 query = query.Where(p => p.EndDate <= toDate.Value);
//             return await query.ToListAsync(cancellationToken);
//         }

//         public async Task<bool> HasOverlapAsync(Guid unitId, DateTime startDate, DateTime endDate, CancellationToken cancellationToken = default)
//         {
//             return await _dbSet.AnyAsync(p => p.UnitId == unitId && p.StartDate < endDate && p.EndDate > startDate, cancellationToken);
//         }
//     }
// } 

using Microsoft.EntityFrameworkCore;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Data;
using YemenBooking.Infrastructure.Data.Context;

namespace YemenBooking.Infrastructure.Repositories;

public class PricingRuleRepository : BaseRepository<PricingRule>, IPricingRuleRepository
{
    public PricingRuleRepository(YemenBookingDbContext context) : base(context)
    {
    }

    public async Task<IEnumerable<PricingRule>> GetByUnitIdAsync(Guid unitId, DateTime? startDate = null, DateTime? endDate = null)
    {
        var query = _dbSet.Where(pr => pr.UnitId == unitId && !pr.IsDeleted);
        
        if (startDate.HasValue)
            query = query.Where(pr => pr.EndDate >= startDate.Value);
            
        if (endDate.HasValue)
            query = query.Where(pr => pr.StartDate <= endDate.Value);
            
        return await query
            .OrderBy(pr => pr.StartDate)
            .ThenBy(pr => pr.PricingTier)
            .ToListAsync();
    }

    public async Task<IEnumerable<PricingRule>> GetActiveRulesAsync(Guid unitId, DateTime date)
    {
        return await _dbSet
            .Where(pr => pr.UnitId == unitId 
                && !pr.IsDeleted
                && pr.StartDate <= date 
                && pr.EndDate >= date)
            .OrderBy(pr => pr.PricingTier)
            .ToListAsync();
    }

    public async Task<PricingRule?> GetPriceForDateAsync(Guid unitId, DateTime date)
    {
        // Get the highest priority rule for the date
        return await _dbSet
            .Where(pr => pr.UnitId == unitId 
                && !pr.IsDeleted
                && pr.StartDate <= date 
                && pr.EndDate >= date)
            .OrderBy(pr => pr.PricingTier)
            .FirstOrDefaultAsync();
    }

    public async Task<IEnumerable<PricingRule>> GetByDateRangeAsync(Guid unitId, DateTime startDate, DateTime endDate)
    {
        return await _dbSet
            .Where(pr => pr.UnitId == unitId 
                && !pr.IsDeleted
                && pr.StartDate <= endDate 
                && pr.EndDate >= startDate)
            .OrderBy(pr => pr.StartDate)
            .ThenBy(pr => pr.PricingTier)
            .ToListAsync();
    }

    public async Task BulkCreateAsync(IEnumerable<PricingRule> rules)
    {
        // Normalize and validate currencies to avoid FK failures
        var rulesList = rules.ToList();

        // Guard: ensure all UnitIds exist to avoid FK constraint failures
        var distinctUnitIds = rulesList.Select(r => r.UnitId).Distinct().ToList();
        var existingUnitIds = await _context.Units
            .Where(u => distinctUnitIds.Contains(u.Id))
            .Select(u => u.Id)
            .ToListAsync();
        var missingUnitIds = distinctUnitIds.Except(existingUnitIds).ToList();
        if (missingUnitIds.Count > 0)
        {
            throw new InvalidOperationException($"One or more UnitIds do not exist: {string.Join(", ", missingUnitIds)}");
        }

        // Preload existing currency codes for validation
        var existingCurrencyCodes = await _context.Currencies
            .Select(c => c.Code)
            .ToListAsync();

        // Group units to preload base currencies where needed
        var unitIdToCurrency = await _context.Units
            .Where(u => distinctUnitIds.Contains(u.Id))
            .Select(u => new { u.Id, Currency = u.BasePrice.Currency })
            .ToDictionaryAsync(x => x.Id, x => x.Currency);

        foreach (var rule in rulesList)
        {
            // Normalize currency
            var code = (rule.Currency ?? string.Empty).Trim();
            code = string.IsNullOrEmpty(code)
                ? (unitIdToCurrency.TryGetValue(rule.UnitId, out var uc) ? uc : null)
                : code;
            code = (code ?? "YER").ToUpperInvariant();

            // Fallback if code not in Currencies table
            if (!existingCurrencyCodes.Contains(code))
            {
                // Try unit base currency if different
                if (unitIdToCurrency.TryGetValue(rule.UnitId, out var unitCurrency))
                {
                    var ucUpper = (unitCurrency ?? "").ToUpperInvariant();
                    if (!string.IsNullOrEmpty(ucUpper) && existingCurrencyCodes.Contains(ucUpper))
                    {
                        code = ucUpper;
                    }
                }
            }
            // Final fallback to YER if exists
            if (!existingCurrencyCodes.Contains(code) && existingCurrencyCodes.Contains("YER"))
            {
                code = "YER";
            }
            rule.Currency = code;

            // Light normalization for strings
            rule.PriceType = string.IsNullOrWhiteSpace(rule.PriceType) ? "Custom" : rule.PriceType.Trim();
            rule.PricingTier = string.IsNullOrWhiteSpace(rule.PricingTier) ? "1" : rule.PricingTier.Trim();
        }

        // Ensure required currency rows exist to satisfy FK
        var finalCodes = rulesList.Select(r => r.Currency).Where(c => !string.IsNullOrWhiteSpace(c)).Select(c => c!).Distinct().ToList();
        var missingCodes = finalCodes.Where(c => !existingCurrencyCodes.Contains(c)).Distinct().ToList();
        if (missingCodes.Count > 0)
        {
            var newCurrencies = missingCodes.Select(c => new Currency
            {
                Code = c,
                Name = c,
                ArabicName = c,
                ArabicCode = c,
                IsDefault = c == "YER"
            });
            await _context.Currencies.AddRangeAsync(newCurrencies);
            await _context.SaveChangesAsync();
            existingCurrencyCodes.AddRange(missingCodes);
        }

        await _dbSet.AddRangeAsync(rulesList);
        await _context.SaveChangesAsync();
    }

    public async Task BulkUpdateAsync(IEnumerable<PricingRule> rules)
    {
        _dbSet.UpdateRange(rules);
        await _context.SaveChangesAsync();
    }

    public async Task DeleteRangeAsync(Guid unitId, DateTime startDate, DateTime endDate)
    {
        // Delete any rule that overlaps with the given window
        var toDelete = await _dbSet
            .Where(pr => pr.UnitId == unitId 
                && !pr.IsDeleted
                && pr.StartDate <= endDate 
                && pr.EndDate >= startDate)
            .ToListAsync();

        foreach (var item in toDelete)
        {
            item.IsDeleted = true;
            item.DeletedAt = DateTime.UtcNow;
        }

        await _context.SaveChangesAsync();
    }

    public async Task<Dictionary<DateTime, decimal>> GetPricingCalendarAsync(Guid unitId, int year, int month)
    {
        var startOfMonth = new DateTime(year, month, 1, 0, 0, 0, DateTimeKind.Utc);
        var endOfMonth = startOfMonth.AddMonths(1).AddDays(-1);
        
        var rules = await GetByDateRangeAsync(unitId, startOfMonth, endOfMonth);
        var calendar = new Dictionary<DateTime, decimal>();
        
        // Get unit base price
        var unit = await _context.Units.FindAsync(unitId);
        var basePrice = unit?.BasePrice?.Amount ?? 0;
        
        int GetTierPriority(string tier)
        {
            if (string.IsNullOrWhiteSpace(tier)) return 5;
            if (int.TryParse(tier, out var n)) return n;
            switch (tier.Trim().ToLowerInvariant())
            {
                case "discount": return 0;
                case "normal": return 1;
                case "high": return 2;
                case "peak": return 3;
                case "seasonal": return 2;
                case "weekend": return 2;
                case "holiday": return 3;
                default: return 5;
            }
        }
        
        for (var date = startOfMonth; date <= endOfMonth; date = date.AddDays(1))
        {
            var dayRule = rules
                .Where(r => date >= r.StartDate.Date && date <= r.EndDate.Date)
                .OrderBy(r => GetTierPriority(r.PricingTier))
                .ThenByDescending(r => r.UpdatedAt)
                .FirstOrDefault();
                
            calendar[date] = dayRule?.PriceAmount ?? basePrice;
        }
        
        return calendar;
    }
}