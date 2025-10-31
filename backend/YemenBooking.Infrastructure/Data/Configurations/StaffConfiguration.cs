using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations;

/// <summary>
/// تكوين كيان الموظف
/// Staff entity configuration
/// </summary>
public class StaffConfiguration : IEntityTypeConfiguration<Staff>
{
    public void Configure(EntityTypeBuilder<Staff> builder)
    {
        builder.ToTable("Staff");

        builder.HasKey(s => s.Id);

        builder.Property(b => b.Id).HasColumnName("StaffId").IsRequired();
        builder.Property(b => b.IsDeleted).HasDefaultValue(false);
        builder.Property(b => b.DeletedAt).HasColumnType("timestamp with time zone");

        builder.Property(s => s.UserId).IsRequired();
        builder.Property(s => s.PropertyId).IsRequired();
        builder.Property(s => s.Position).IsRequired();
        builder.Property(s => s.Permissions).HasColumnType("text");

        builder.Property(s => s.Position)
            .IsRequired()
            .HasMaxLength(100)
            .HasComment("منصب الموظف");

        // Indexes
        builder.HasIndex(s => s.UserId)
            .HasDatabaseName("IX_Staff_UserId");

        builder.HasIndex(s => s.PropertyId)
            .HasDatabaseName("IX_Staff_PropertyId");

        builder.HasIndex(s => new { s.UserId, s.PropertyId })
            .IsUnique()
            .HasDatabaseName("IX_Staff_UserId_PropertyId");

        builder.HasIndex(s => s.IsDeleted)
            .HasDatabaseName("IX_Staff_IsDeleted");

        // Relationships
        builder.HasOne(s => s.User)
            .WithMany(u => u.StaffPositions)
            .HasForeignKey(s => s.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(s => s.Property)
            .WithMany(p => p.Staff)
            .HasForeignKey(s => s.PropertyId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasQueryFilter(s => !s.IsDeleted);
    }
}
