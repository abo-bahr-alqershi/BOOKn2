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
/// تنفيذ مستودع روابط الحقول والمجموعات
/// FieldGroupField repository implementation
/// </summary>
public class FieldGroupFieldRepository : BaseRepository<FieldGroupField>, IFieldGroupFieldRepository
{
    public FieldGroupFieldRepository(YemenBookingDbContext context) : base(context)
    {
    }

    public async Task<FieldGroupField> AssignFieldToGroupAsync(FieldGroupField fieldGroupField, CancellationToken cancellationToken = default)
    {
        await _dbSet.AddAsync(fieldGroupField, cancellationToken);
        await _context.SaveChangesAsync(cancellationToken);
        return fieldGroupField;
    }

    public async Task<bool> RemoveFieldFromGroupAsync(Guid fieldId, Guid groupId, CancellationToken cancellationToken = default)
    {
        var entity = await _dbSet.FindAsync(new object[] { fieldId, groupId }, cancellationToken);
        if (entity == null) return false;
        _dbSet.Remove(entity);
        await _context.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<IEnumerable<FieldGroupField>> GetFieldsByGroupIdAsync(Guid groupId, CancellationToken cancellationToken = default)
        => await _dbSet.Where(fgf => fgf.GroupId == groupId).ToListAsync(cancellationToken);

    public async Task<IEnumerable<FieldGroupField>> GetGroupsByFieldIdAsync(Guid fieldId, CancellationToken cancellationToken = default)
        => await _dbSet.Where(fgf => fgf.FieldId == fieldId).ToListAsync(cancellationToken);

    public async Task<bool> GroupHasFieldAsync(Guid groupId, Guid fieldId, CancellationToken cancellationToken = default)
        => await _dbSet.AnyAsync(fgf => fgf.GroupId == groupId && fgf.FieldId == fieldId, cancellationToken);
} 