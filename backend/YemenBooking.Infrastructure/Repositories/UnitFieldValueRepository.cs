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
/// تنفيذ مستودع قيم الحقول للوحدات
/// UnitFieldValue repository implementation
/// </summary>
public class UnitFieldValueRepository : BaseRepository<UnitFieldValue>, IUnitFieldValueRepository
{
    public UnitFieldValueRepository(YemenBookingDbContext context) : base(context)
    {
    }

    public async Task<UnitFieldValue> CreateUnitFieldValueAsync(UnitFieldValue unitFieldValue, CancellationToken cancellationToken = default)
    {
        await _dbSet.AddAsync(unitFieldValue, cancellationToken);
        await _context.SaveChangesAsync(cancellationToken);
        return unitFieldValue;
    }

    public async Task<UnitFieldValue?> GetUnitFieldValueByIdAsync(Guid valueId, CancellationToken cancellationToken = default)
        => await _dbSet.FindAsync(new object[] { valueId }, cancellationToken);

    public async Task<UnitFieldValue> UpdateUnitFieldValueAsync(UnitFieldValue unitFieldValue, CancellationToken cancellationToken = default)
    {
        _dbSet.Update(unitFieldValue);
        await _context.SaveChangesAsync(cancellationToken);
        return unitFieldValue;
    }

    public async Task<bool> DeleteUnitFieldValueAsync(Guid valueId, CancellationToken cancellationToken = default)
    {
        var entity = await GetUnitFieldValueByIdAsync(valueId, cancellationToken);
        if (entity == null) return false;
        _dbSet.Remove(entity);
        await _context.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<IEnumerable<UnitFieldValue>> GetValuesByUnitIdAsync(Guid unitId, CancellationToken cancellationToken = default)
        => await _dbSet.Where(ufv => ufv.UnitId == unitId).ToListAsync(cancellationToken);

    public async Task<IEnumerable<UnitFieldValue>> GetByFieldIdAsync(Guid fieldId, CancellationToken cancellationToken = default)
        => await _dbSet.Where(ufv => ufv.UnitTypeFieldId == fieldId).ToListAsync(cancellationToken);
}