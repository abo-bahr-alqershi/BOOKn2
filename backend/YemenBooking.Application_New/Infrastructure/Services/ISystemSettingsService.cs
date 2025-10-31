using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

namespace YemenBooking.Application.Infrastructure.Services
{
    /// <summary>
    /// خدمة إدارة إعدادات النظام (قراءة وحفظ)
    /// Service for managing system settings (read and save)
    /// </summary>
    public interface ISystemSettingsService
    {
        Task<Dictionary<string, string>> GetSettingsAsync(CancellationToken cancellationToken = default);
        Task SaveSettingsAsync(Dictionary<string, string> settings, CancellationToken cancellationToken = default);
    }
} 