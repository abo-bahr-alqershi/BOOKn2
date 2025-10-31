using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations;

/// <summary>
/// تكوين كيان سياسة الكيان
/// Property Policy entity configuration
/// </summary>
public class PropertyPolicyConfiguration : IEntityTypeConfiguration<PropertyPolicy>
{
    public void Configure(EntityTypeBuilder<PropertyPolicy> builder)
    {
        builder.ToTable("PropertyPolicies");

        builder.HasKey(pp => pp.Id);

        builder.Property(b => b.Id).HasColumnName("PolicyId").IsRequired();
        builder.Property(b => b.IsActive).HasDefaultValue(true).IsRequired();
        builder.Property(b => b.IsDeleted).HasDefaultValue(false).IsRequired();
        builder.Property(b => b.DeletedAt).HasColumnType("timestamp with time zone");

        builder.Property(pp => pp.PropertyId)
            .IsRequired()
            .HasComment("معرف الكيان");

        builder.Property(pp => pp.Type)
            .IsRequired()
            .HasMaxLength(50)
            .HasComment("نوع السياسة");

        builder.Property(pp => pp.Description)
            .IsRequired()
            .HasMaxLength(1000)
            .HasComment("وصف السياسة");

        builder.Property(pp => pp.Rules)
            .HasColumnType("text")
            .HasComment("قواعد السياسة (JSON)");

        // Indexes
        builder.HasIndex(pp => pp.PropertyId)
            .HasDatabaseName("IX_PropertyPolicies_PropertyId");

        builder.HasIndex(pp => pp.Type)
            .HasDatabaseName("IX_PropertyPolicies_PolicyType");

        builder.HasIndex(pp => new { pp.PropertyId, pp.Type })
            .HasDatabaseName("IX_PropertyPolicies_PropertyId_PolicyType");

        builder.HasIndex(pp => pp.IsDeleted)
            .HasDatabaseName("IX_PropertyPolicies_IsDeleted");

        // Relationships
        builder.HasOne(pp => pp.Property)
            .WithMany(p => p.Policies)
            .HasForeignKey(pp => pp.PropertyId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasQueryFilter(pp => !pp.IsDeleted);
    }
}
