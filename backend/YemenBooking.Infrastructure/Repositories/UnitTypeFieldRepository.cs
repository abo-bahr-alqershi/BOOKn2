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
/// تنفيذ مستودع حقول نوع الكيان
/// UnitTypeField repository implementation
/// </summary>
public class UnitTypeFieldRepository : BaseRepository<UnitTypeField>, IUnitTypeFieldRepository
{
    public UnitTypeFieldRepository(YemenBookingDbContext context) : base(context)
    {
    }

    public async Task<UnitTypeField> CreateUnitTypeFieldAsync(UnitTypeField unitTypeField, CancellationToken cancellationToken = default)
    {
        await _dbSet.AddAsync(unitTypeField, cancellationToken);
        await _context.SaveChangesAsync(cancellationToken);
        return unitTypeField;
    }

    public async Task<UnitTypeField?> GetUnitTypeFieldByIdAsync(Guid fieldId, CancellationToken cancellationToken = default)
        => await _dbSet.FindAsync(new object[] { fieldId }, cancellationToken);

    public async Task<UnitTypeField> UpdateUnitTypeFieldAsync(UnitTypeField unitTypeField, CancellationToken cancellationToken = default)
    {
        _dbSet.Update(unitTypeField);
        await _context.SaveChangesAsync(cancellationToken);
        return unitTypeField;
    }

    public async Task<bool> DeleteUnitTypeFieldAsync(Guid fieldId, CancellationToken cancellationToken = default)
    {
        var entity = await GetUnitTypeFieldByIdAsync(fieldId, cancellationToken);
        if (entity == null) return false;
        _dbSet.Remove(entity);
        await _context.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<IEnumerable<UnitTypeField>> GetFieldsByUnitTypeIdAsync(Guid unitTypeId, CancellationToken cancellationToken = default)
        => await _dbSet.Where(ptf => ptf.UnitTypeId == unitTypeId).ToListAsync(cancellationToken);
} 