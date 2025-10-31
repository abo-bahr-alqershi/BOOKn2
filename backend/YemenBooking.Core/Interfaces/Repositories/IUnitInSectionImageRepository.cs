using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces;

namespace YemenBooking.Core.Interfaces.Repositories;

public interface IUnitInSectionImageRepository : IRepository<UnitInSectionImage>
{
    Task<UnitInSectionImage> CreateAsync(UnitInSectionImage image, CancellationToken cancellationToken = default);
    Task<UnitInSectionImage?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<UnitInSectionImage> UpdateAsync(UnitInSectionImage image, CancellationToken cancellationToken = default);
    Task<bool> DeleteAsync(Guid id, CancellationToken cancellationToken = default);
    Task<IEnumerable<UnitInSectionImage>> GetByUnitInSectionIdAsync(Guid unitInSectionId, CancellationToken cancellationToken = default);
    Task<bool> UpdateDisplayOrdersAsync(IEnumerable<(Guid imageId, int displayOrder)> assignments, CancellationToken cancellationToken = default);
    Task<bool> UpdateMainImageStatusAsync(Guid imageId, bool isMain, CancellationToken cancellationToken = default);
    Task<IEnumerable<UnitInSectionImage>> GetByTempKeyAsync(string tempKey, CancellationToken cancellationToken = default);
}

