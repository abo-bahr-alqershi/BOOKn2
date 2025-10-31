using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Infrastructure.Data.Context;

namespace YemenBooking.Infrastructure.Services
{
    /// <summary>
    /// تنفيذ خدمة المدن باستخدام قاعدة البيانات بدلاً من الملفات
    /// EF-backed implementation for city settings
    /// </summary>
    public class CitySettingsService : ICitySettingsService
    {
        private readonly YemenBookingDbContext _db;

        public CitySettingsService(YemenBookingDbContext db) => _db = db;

        public async Task<List<CityDto>> GetCitiesAsync(CancellationToken cancellationToken = default)
        {
            var rows = await _db.Cities.AsNoTracking()
                .OrderBy(c => c.Country).ThenBy(c => c.Name)
                .Select(c => new { c.Name, c.Country, c.ImagesJson })
                .ToListAsync(cancellationToken);

            var result = new List<CityDto>(rows.Count);
            foreach (var r in rows)
            {
                // Prefer images from shared PropertyImages table to unify behavior with properties/units
                var imageUrls = await _db.PropertyImages.AsNoTracking()
                    .Where(pi => pi.CityName == r.Name && !pi.IsDeleted)
                    .OrderBy(pi => pi.DisplayOrder)
                    .ThenBy(pi => pi.UploadedAt)
                    .Select(pi => pi.Url)
                    .ToListAsync(cancellationToken);

                // Deduplicate and normalize URLs to avoid duplicates from encoding/casing/whitespace
                imageUrls = imageUrls
                    .Where(u => !string.IsNullOrWhiteSpace(u))
                    .Select(u => Uri.UnescapeDataString(u.Trim()))
                    .Select(u => u.StartsWith("/") ? u : "/" + u)
                    .Distinct(StringComparer.OrdinalIgnoreCase)
                    .ToList();

                if (imageUrls.Count == 0)
                {
                    try
                    {
                        imageUrls = System.Text.Json.JsonSerializer.Deserialize<List<string>>(r.ImagesJson) ?? new List<string>();
                    }
                    catch { imageUrls = new List<string>(); }
                }

                result.Add(new CityDto { Name = r.Name, Country = r.Country, Images = imageUrls });
            }
            return result;
        }

        public async Task SaveCitiesAsync(List<CityDto> cities, CancellationToken cancellationToken = default)
        {
            if (cities == null) throw new ArgumentNullException(nameof(cities));

            // Ensure city names are unique
            var duplicates = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            foreach (var city in cities)
            {
                if (!duplicates.Add(city.Name))
                    throw new InvalidOperationException($"Duplicate city name: {city.Name}");
            }

            var names = cities.Select(c => c.Name).ToHashSet(StringComparer.OrdinalIgnoreCase);
            var existing = await _db.Cities.Where(c => names.Contains(c.Name)).ToListAsync(cancellationToken);

            foreach (var dto in cities)
            {
                var entity = existing.FirstOrDefault(e => e.Name.Equals(dto.Name, StringComparison.OrdinalIgnoreCase));
                var imagesJson = System.Text.Json.JsonSerializer.Serialize(dto.Images ?? new List<string>());
                if (entity == null)
                {
                    _db.Cities.Add(new City
                    {
                        Name = dto.Name,
                        Country = dto.Country,
                        ImagesJson = imagesJson
                    });
                }
                else
                {
                    entity.Country = dto.Country;
                    entity.ImagesJson = imagesJson;
                    _db.Cities.Update(entity);
                }

                // مزامنة ترتيب الصور مع جدول الصور الموحد وربطها بالمدينة
                if (dto.Images != null && dto.Images.Count > 0)
                {
                    // اجلب كل صور المدينة الحالية
                    var cityImages = await _db.PropertyImages
                        .Where(pi => pi.CityName == dto.Name && !pi.IsDeleted)
                        .ToListAsync(cancellationToken);

                    // أنشئ فهرس URL -> صورة مع إلغاء الازدواجية والتوحيد
                    string Normalize(string? url)
                    {
                        if (string.IsNullOrWhiteSpace(url)) return string.Empty;
                        var unescaped = Uri.UnescapeDataString(url.Trim());
                        return unescaped.StartsWith("/") ? unescaped : "/" + unescaped;
                    }

                    var map = new Dictionary<string, PropertyImage>(StringComparer.OrdinalIgnoreCase);
                    foreach (var i in cityImages)
                    {
                        var key = Normalize(i.Url);
                        if (string.IsNullOrEmpty(key)) continue;
                        if (!map.TryAdd(key, i))
                        {
                            // Prefer main image, otherwise keep existing
                            var _existing = map[key];
                            if (i.IsMainImage  && !_existing.IsMainImage)
                            {
                                map[key] = i;
                            }
                        }
                    }

                    // نظّف الصور القادمة من DTO وأزل التكرارات قبل التحديث
                    var normalizedDtoImages = new List<string>(dto.Images.Count);
                    var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                    for (int i = 0; i < dto.Images.Count; i++)
                    {
                        var url = Normalize(dto.Images[i]);
                        if (string.IsNullOrWhiteSpace(url)) continue;
                        if (seen.Add(url))
                        {
                            normalizedDtoImages.Add(url);
                        }
                    }

                    for (int i = 0; i < normalizedDtoImages.Count; i++)
                    {
                        var url = normalizedDtoImages[i];
                        if (map.TryGetValue(url, out var img))
                        {
                            img.CityName = dto.Name; // تأكيد الربط
                            img.DisplayOrder = i + 1;
                            img.IsMainImage = i == 0;
                            img.IsMain = i == 0;
                            img.UpdatedAt = DateTime.UtcNow;
                            _db.PropertyImages.Update(img);
                        }
                    }
                }
            }

            await _db.SaveChangesAsync(cancellationToken);
        }

        /// <summary>
        /// Delete a city after ensuring there are no dependent entities (properties, users, bookings, etc.)
        /// Throws InvalidOperationException with a clear reason if deletion is not allowed
        /// </summary>
        public async Task DeleteCityAsync(string name, CancellationToken cancellationToken = default)
        {
            if (string.IsNullOrWhiteSpace(name)) throw new ArgumentException("City name is required", nameof(name));

            var city = await _db.Cities.FirstOrDefaultAsync(c => c.Name == name, cancellationToken);
            if (city == null)
                throw new ArgumentException("المدينة غير موجودة", nameof(name));

            // Check dependencies
            var propertiesCount = await _db.Properties.CountAsync(p => p.City == name, cancellationToken);
            if (propertiesCount > 0)
                throw new InvalidOperationException($"لا يمكن حذف المدينة لوجود {propertiesCount} عقار مرتبط بها");

            // If there are staff/users explicitly linked to city (not modeled directly), skip.
            // Example checks (commented as there is no direct FK on User):
            // var usersInCity = await _db.Users.CountAsync(u => u.City == name, cancellationToken);
            // if (usersInCity > 0) throw new InvalidOperationException($"لا يمكن حذف المدينة لوجود {usersInCity} مستخدم مرتبط بها");

            // Safe to delete
            _db.Cities.Remove(city);
            await _db.SaveChangesAsync(cancellationToken);
        }
    }
} 