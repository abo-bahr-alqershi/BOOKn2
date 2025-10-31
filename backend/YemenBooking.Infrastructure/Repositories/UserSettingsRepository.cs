using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Data.Context;

namespace YemenBooking.Infrastructure.Repositories
{
    public class UserSettingsRepository : BaseRepository<UserSettings>, IUserSettingsRepository
    {
        public UserSettingsRepository(YemenBookingDbContext context) : base(context) { }

        public async Task<UserSettings> CreateOrUpdateAsync(UserSettings userSettings, CancellationToken cancellationToken = default)
        {
            var existing = await _context.Set<UserSettings>().FirstOrDefaultAsync(s => s.UserId == userSettings.UserId, cancellationToken);
            if (existing == null)
            {
                await _context.Set<UserSettings>().AddAsync(userSettings, cancellationToken);
            }
            else
            {
                existing.PreferredLanguage = userSettings.PreferredLanguage;
                existing.PreferredCurrency = userSettings.PreferredCurrency;
                existing.TimeZone = userSettings.TimeZone;
                existing.DarkMode = userSettings.DarkMode;
                existing.BookingNotifications = userSettings.BookingNotifications;
                existing.PromotionalNotifications = userSettings.PromotionalNotifications;
                existing.EmailNotifications = userSettings.EmailNotifications;
                existing.SmsNotifications = userSettings.SmsNotifications;
                existing.PushNotifications = userSettings.PushNotifications;
                existing.AdditionalSettings = userSettings.AdditionalSettings;
                _context.Set<UserSettings>().Update(existing);
                userSettings = existing;
            }
            await _context.SaveChangesAsync(cancellationToken);
            return userSettings;
        }

        public async Task<bool> DeleteAsync(Guid id, CancellationToken cancellationToken = default)
        {
            var entity = await GetByIdAsync(id, cancellationToken);
            if (entity == null) return false;
            _context.Set<UserSettings>().Remove(entity);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

        public async Task<bool> DeleteByUserIdAsync(Guid userId, CancellationToken cancellationToken = default)
        {
            var entity = await _context.Set<UserSettings>().FirstOrDefaultAsync(s => s.UserId == userId, cancellationToken);
            if (entity == null) return false;
            _context.Set<UserSettings>().Remove(entity);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

        public async Task<UserSettings> CreateAsync(UserSettings userSettings, CancellationToken cancellationToken = default)
        {
            await _context.Set<UserSettings>().AddAsync(userSettings, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);
            return userSettings;
        }

        public async Task<bool> ExistsAsync(Guid userId, CancellationToken cancellationToken = default)
        {
            return await _context.Set<UserSettings>().AnyAsync(s => s.UserId == userId, cancellationToken);
        }

        public Task<UserSettings?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
        {
            return base.GetByIdAsync(id, cancellationToken);
        }

        public async Task<UserSettings?> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default)
        {
            return await _context.Set<UserSettings>().FirstOrDefaultAsync(s => s.UserId == userId, cancellationToken);
        }

        public async Task<UserSettings> UpdateAsync(UserSettings userSettings, CancellationToken cancellationToken = default)
        {
            _context.Set<UserSettings>().Update(userSettings);
            await _context.SaveChangesAsync(cancellationToken);
            return userSettings;
        }

        async Task<UserSettings> IUserSettingsRepository.CreateOrUpdateAsync(UserSettings userSettings, CancellationToken cancellationToken)
            => await CreateOrUpdateAsync(userSettings, cancellationToken);
    }
}
