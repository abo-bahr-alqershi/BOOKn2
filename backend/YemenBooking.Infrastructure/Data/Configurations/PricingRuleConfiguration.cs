using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations;

/// <summary>
/// تكوين كيان قواعد التسعير
/// Pricing rule entity configuration
/// </summary>
public class PricingRuleConfiguration : IEntityTypeConfiguration<PricingRule>
{
    public void Configure(EntityTypeBuilder<PricingRule> builder)
    {
        builder.ToTable("PricingRules");

        builder.HasKey(p => p.Id);

        builder.Property(p => p.Id)
            .HasColumnName("PricingRuleId")
            .IsRequired();
        builder.Property(p => p.IsDeleted)
            .HasDefaultValue(false);
        builder.Property(p => p.DeletedAt)
            .HasColumnType("timestamp with time zone");

        builder.Property(p => p.UnitId)
            .IsRequired();
        builder.Property(p => p.PriceType)
            .IsRequired()
            .HasMaxLength(50);
        builder.Property(p => p.StartDate)
            .HasColumnType("timestamp with time zone")
            .IsRequired();
        builder.Property(p => p.EndDate)
            .HasColumnType("timestamp with time zone")
            .IsRequired();
        builder.Property(p => p.StartTime)
            .HasColumnType("time");
        builder.Property(p => p.EndTime)
            .HasColumnType("time");
        builder.Property(p => p.PriceAmount)
            .HasColumnType("decimal(18,2)")
            .IsRequired();
        // Currency for price
        builder.Property(p => p.Currency)
            .IsRequired()
            .HasMaxLength(10); // Match Currency.Code length
        // Link to Currency entity by Code
        builder.HasOne(p => p.CurrencyRef)
            .WithMany()
            .HasForeignKey(p => p.Currency)
            .HasPrincipalKey(c => c.Code)
            .OnDelete(DeleteBehavior.Restrict);
        builder.Property(p => p.PricingTier)
            .IsRequired()
            .HasMaxLength(20);
        builder.Property(p => p.PercentageChange)
            .HasColumnType("decimal(5,2)");
        builder.Property(p => p.MinPrice)
            .HasColumnType("decimal(18,2)");
        builder.Property(p => p.MaxPrice)
            .HasColumnType("decimal(18,2)");
        builder.Property(p => p.Description)
            .HasMaxLength(500);

        builder.HasIndex(p => new { p.UnitId, p.StartDate, p.EndDate });

        // Map Unit navigation to UnitId to avoid EF creating shadow FK (UnitId1)
        builder.HasOne(p => p.Unit)
            .WithMany(u => u.PricingRules)
            .HasForeignKey(p => p.UnitId)
            .OnDelete(DeleteBehavior.Cascade);

        // Note: Avoid global filter in tests to allow asserting soft-deleted rows
        // builder.HasQueryFilter(p => !p.IsDeleted);
    }
} 