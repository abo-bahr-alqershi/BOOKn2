using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Hosting;
using YemenBooking.Application.Infrastructure.Services;

namespace YemenBooking.Infrastructure.Services
{
    /// <summary>
    /// تنفيذ خدمة إدارة إعدادات النظام باستخدام ملف JSON محمي
    /// Implementation of system settings service using a protected JSON file
    /// </summary>
    public class SystemSettingsService : ISystemSettingsService
    {
        private readonly string _settingsFilePath;

        public SystemSettingsService(IHostEnvironment env)
        {
            var settingsDir = Path.Combine(env.ContentRootPath, "Settings");
            if (!Directory.Exists(settingsDir))
            {
                Directory.CreateDirectory(settingsDir);
            }
            _settingsFilePath = Path.Combine(settingsDir, "systemsettings.json");
        }

        public async Task<Dictionary<string, string>> GetSettingsAsync(CancellationToken cancellationToken = default)
        {
            if (!File.Exists(_settingsFilePath))
            {
                var defaultSettings = new Dictionary<string, string>();
                var defaultContent = JsonSerializer.Serialize(defaultSettings, new JsonSerializerOptions { WriteIndented = true });
                await File.WriteAllTextAsync(_settingsFilePath, defaultContent, cancellationToken);
                return defaultSettings;
            }

            var content = await File.ReadAllTextAsync(_settingsFilePath, cancellationToken);
            return JsonSerializer.Deserialize<Dictionary<string, string>>(content) ?? new Dictionary<string, string>();
        }

        public async Task SaveSettingsAsync(Dictionary<string, string> settings, CancellationToken cancellationToken = default)
        {
            var content = JsonSerializer.Serialize(settings, new JsonSerializerOptions { WriteIndented = true });
            await File.WriteAllTextAsync(_settingsFilePath, content, cancellationToken);
        }
    }
} 