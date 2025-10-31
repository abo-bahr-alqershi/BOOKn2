using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Data.Context;

namespace YemenBooking.Infrastructure.Repositories;

/// <summary>
/// تنفيذ مستودع مجموعات الحقول
/// FieldGroup repository implementation
/// </summary>
public class FieldGroupRepository : BaseRepository<FieldGroup>, IFieldGroupRepository
{
    public FieldGroupRepository(YemenBookingDbContext context) : base(context)
    {
    }

    public async Task<FieldGroup> CreateFieldGroupAsync(FieldGroup fieldGroup, CancellationToken cancellationToken = default)
    {
        await _dbSet.AddAsync(fieldGroup, cancellationToken);
        await _context.SaveChangesAsync(cancellationToken);
        return fieldGroup;
    }

    public async Task<FieldGroup?> GetFieldGroupByIdAsync(Guid groupId, CancellationToken cancellationToken = default)
        => await _dbSet.FindAsync(new object[] { groupId }, cancellationToken);

    public async Task<FieldGroup> UpdateFieldGroupAsync(FieldGroup fieldGroup, CancellationToken cancellationToken = default)
    {
        _dbSet.Update(fieldGroup);
        await _context.SaveChangesAsync(cancellationToken);
        return fieldGroup;
    }

    public async Task<bool> DeleteFieldGroupAsync(Guid groupId, CancellationToken cancellationToken = default)
    {
        var entity = await GetFieldGroupByIdAsync(groupId, cancellationToken);
        if (entity == null) return false;

        _dbSet.Remove(entity);
        await _context.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<IEnumerable<FieldGroup>> GetGroupsByUnitTypeIdAsync(Guid propertyTypeId, CancellationToken cancellationToken = default)
        => await _dbSet.Where(fg => fg.UnitTypeId == propertyTypeId).ToListAsync(cancellationToken);
} 