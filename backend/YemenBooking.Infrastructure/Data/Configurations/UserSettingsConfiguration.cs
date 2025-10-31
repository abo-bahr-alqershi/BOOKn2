using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using System.Collections.Generic;
using System.Text.Json;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations
{
    /// <summary>
    /// تكوين كيان إعدادات المستخدم
    /// UserSettings EF configuration
    /// </summary>
    public class UserSettingsConfiguration : IEntityTypeConfiguration<UserSettings>
    {
        public void Configure(EntityTypeBuilder<UserSettings> builder)
        {
            builder.ToTable("UserSettings");
            builder.HasKey(us => us.Id);

            builder.Property(us => us.UserId)
                .IsRequired();

            builder.HasIndex(us => us.UserId)
                .IsUnique();

            builder.Property(us => us.PreferredLanguage)
                .HasMaxLength(10);

            builder.Property(us => us.PreferredCurrency)
                .HasMaxLength(3);

            builder.Property(us => us.TimeZone)
                .HasMaxLength(50);

            var jsonOptions = new JsonSerializerOptions
            {
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                WriteIndented = false
            };

            var dictionaryComparer = new ValueComparer<Dictionary<string, object>>(
                (left, right) => JsonSerializer.Serialize(left, jsonOptions) == JsonSerializer.Serialize(right, jsonOptions),
                value => value == null ? 0 : JsonSerializer.Serialize(value, jsonOptions).GetHashCode(),
                value => value == null
                    ? new Dictionary<string, object>()
                    : JsonSerializer.Deserialize<Dictionary<string, object>>(JsonSerializer.Serialize(value, jsonOptions), jsonOptions)
                        ?? new Dictionary<string, object>());

            builder.Property(us => us.AdditionalSettings)
                .HasColumnType("text")
                .HasConversion(
                    value => value == null ? null : JsonSerializer.Serialize(value, jsonOptions),
                    value => string.IsNullOrWhiteSpace(value)
                        ? new Dictionary<string, object>()
                        : JsonSerializer.Deserialize<Dictionary<string, object>>(value!, jsonOptions) ?? new Dictionary<string, object>())
                .Metadata.SetValueComparer(dictionaryComparer);
        }
    }
}
