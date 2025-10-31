using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations;

/// <summary>
/// تكوين كيان العملة
/// Currency entity configuration
/// </summary>
public class CurrencyConfiguration : IEntityTypeConfiguration<Currency>
{
    public void Configure(EntityTypeBuilder<Currency> builder)
    {
        builder.ToTable("Currencies");

        builder.HasKey(c => c.Code);
        builder.Property(c => c.Code)
               .HasMaxLength(10)
               .IsRequired();
        builder.Property(c => c.ArabicCode)
               .HasMaxLength(10);
        builder.Property(c => c.Name)
               .HasMaxLength(100)
               .IsRequired();
        builder.Property(c => c.ArabicName)
               .HasMaxLength(100);
        builder.Property(c => c.IsDefault)
               .HasDefaultValue(false);
        builder.Property(c => c.ExchangeRate)
               .HasColumnType("decimal(18,6)");
        builder.Property(c => c.LastUpdated)
               .HasColumnType("timestamp with time zone");

        builder.HasIndex(c => c.IsDefault).HasDatabaseName("IX_Currencies_IsDefault");
    }
}

