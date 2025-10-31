using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations;

/// <summary>
/// تكوين كيان الدور
/// Role entity configuration
/// </summary>
public class RoleConfiguration : IEntityTypeConfiguration<Role>
{
    public void Configure(EntityTypeBuilder<Role> builder)
    {
        // تعيين اسم الجدول
        // Set table name
        builder.ToTable("Roles");

        // تعيين المفتاح الأساسي
        // Set primary key
        builder.HasKey(r => r.Id);

        // تكوين الخصائص الأساسية من BaseEntity
        builder.Property(b => b.Id).HasColumnName("RoleId").IsRequired();
        builder.Property(b => b.IsDeleted).HasDefaultValue(false);
        builder.Property(b => b.DeletedAt).HasColumnType("timestamp with time zone");
        
        // تكوين الخصائص الأخرى
        builder.Property(r => r.Name).IsRequired().HasMaxLength(50);
        
        // تكوين الفهرس
        builder.HasIndex(r => r.Name).IsUnique();

        // إعداد العلاقات
        // Configure relationships
        builder.HasMany(r => r.UserRoles)
            .WithOne(ur => ur.Role)
            .HasForeignKey(ur => ur.RoleId)
            .OnDelete(DeleteBehavior.Cascade);

        // Seed data moved to DataSeedingService
        // تم نقل البيانات الأولية إلى DataSeedingService

        // تطبيق مرشح الحذف الناعم
        // Apply soft delete filter
        builder.HasQueryFilter(r => !r.IsDeleted);
    }
}
