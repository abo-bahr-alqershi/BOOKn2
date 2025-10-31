using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations;

/// <summary>
/// تكوين كيان دور المستخدم
/// User Role entity configuration
/// </summary>
public class UserRoleConfiguration : IEntityTypeConfiguration<UserRole>
{
    public void Configure(EntityTypeBuilder<UserRole> builder)
    {
        // تعيين اسم الجدول
        // Set table name
        builder.ToTable("UserRoles");

        // تكوين الخصائص الأساسية من BaseEntity
        builder.Property(b => b.Id).HasColumnName("UserRoleId").IsRequired();
        builder.Property(b => b.IsDeleted).HasDefaultValue(false);
        builder.Property(b => b.DeletedAt).HasColumnType("timestamp with time zone");
        
        // تكوين الخصائص الأخرى
        builder.Property(ur => ur.UserId).IsRequired();
        builder.Property(ur => ur.RoleId).IsRequired();
        builder.Property(ur => ur.AssignedAt).HasColumnType("timestamp with time zone").IsRequired();
        
        // تكوين المفتاح الأساسي المركب
        builder.HasKey(ur => new { ur.UserId, ur.RoleId });
        
        // تكوين العلاقات
        builder.HasOne(ur => ur.User)
               .WithMany(u => u.UserRoles)
               .HasForeignKey(ur => ur.UserId);
        
        builder.HasOne(ur => ur.Role)
               .WithMany(r => r.UserRoles)
               .HasForeignKey(ur => ur.RoleId);

        // الفهارس
        // Indexes
        builder.HasIndex(ur => ur.UserId)
            .HasDatabaseName("IX_UserRoles_UserId");

        builder.HasIndex(ur => ur.RoleId)
            .HasDatabaseName("IX_UserRoles_RoleId");

        builder.HasIndex(ur => ur.IsDeleted)
            .HasDatabaseName("IX_UserRoles_IsDeleted");

        // تطبيق مرشح الحذف الناعم
        // Apply soft delete filter
        builder.HasQueryFilter(ur => !ur.IsDeleted);
    }
}
