using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Data.Context;

namespace YemenBooking.Infrastructure.Repositories
{
    /// <summary>
    /// تنفيذ مستودع السياسات
    /// Policy repository implementation
    /// </summary>
    public class PolicyRepository : BaseRepository<PropertyPolicy>, IPolicyRepository
    {
        public PolicyRepository(YemenBookingDbContext context) : base(context) { }

        public async Task<PropertyPolicy> CreatePropertyPolicyAsync(PropertyPolicy propertyPolicy, CancellationToken cancellationToken = default)
        {
            await _dbSet.AddAsync(propertyPolicy, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);
            return propertyPolicy;
        }

        public async Task<PropertyPolicy?> GetPolicyByIdAsync(Guid policyId, CancellationToken cancellationToken = default)
            => await _dbSet.FindAsync(new object[]{policyId}, cancellationToken);

        public async Task<PropertyPolicy> UpdatePropertyPolicyAsync(PropertyPolicy propertyPolicy, CancellationToken cancellationToken = default)
        {
            _dbSet.Update(propertyPolicy);
            await _context.SaveChangesAsync(cancellationToken);
            return propertyPolicy;
        }

        public async Task<bool> DeletePolicyAsync(Guid policyId, CancellationToken cancellationToken = default)
        {
            var pol = await GetPolicyByIdAsync(policyId, cancellationToken);
            if (pol == null) return false;
            _dbSet.Remove(pol);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

        public async Task<IEnumerable<PropertyPolicy>> GetPropertyPoliciesAsync(Guid propertyId, CancellationToken cancellationToken = default)
            => await _dbSet.Where(p => p.PropertyId == propertyId).ToListAsync(cancellationToken);

        public async Task<IEnumerable<PropertyPolicy>> GetPoliciesByTypeAsync(string policyType, CancellationToken cancellationToken = default)
            => await _dbSet.Where(p => p.Type.ToString() == policyType).ToListAsync(cancellationToken);

        public async Task<Property?> GetPropertyByIdAsync(Guid propertyId, CancellationToken cancellationToken = default)
            => await _context.Set<Property>().FirstOrDefaultAsync(p => p.Id == propertyId, cancellationToken);
    }
} 