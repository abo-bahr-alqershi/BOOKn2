using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Data.Context;

namespace YemenBooking.Infrastructure.Repositories
{
    public class AppVersionRepository : BaseRepository<AppVersion>, IAppVersionRepository
    {
        public AppVersionRepository(YemenBookingDbContext context) : base(context) { }

        public async Task<AppVersion?> GetLatestVersionAsync(string platform)
            => await _dbSet.Where(v => v.Platform == platform && v.IsActive)
                .OrderByDescending(v => v.ReleaseDate)
                .FirstOrDefaultAsync();

        public async Task<AppVersion?> GetVersionAsync(string version, string platform)
            => await _dbSet.FirstOrDefaultAsync(v => v.Version == version && v.Platform == platform);

        public async Task<UpdateInfo> CheckUpdateAsync(string currentVersion, string platform)
        {
            var latest = await GetLatestVersionAsync(platform);
            return new UpdateInfo
            {
                IsUpdateAvailable = latest != null && latest.Version != currentVersion,
                IsForceUpdate = latest?.IsForceUpdate ?? false,
                LatestVersion = latest?.Version,
                UpdateUrl = latest?.UpdateUrl,
                UpdateMessage = latest?.UpdateMessage
            };
        }

        public async Task<string?> GetMinSupportedVersionAsync(string platform)
            => await _dbSet.Where(v => v.Platform == platform && v.IsActive)
                .OrderBy(v => v.ReleaseDate)
                .Select(v => v.Version)
                .FirstOrDefaultAsync();

        public async Task<bool> UpdateVersionAsync(AppVersion appVersion)
        {
            _dbSet.Update(appVersion);
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> DisableVersionAsync(string version, string platform)
        {
            var entity = await _dbSet.FirstOrDefaultAsync(v => v.Version == version && v.Platform == platform);
            if (entity != null)
            {
                entity.IsActive = false;
                await _context.SaveChangesAsync();
                return true;
            }
            return false;
        }
    }
}
