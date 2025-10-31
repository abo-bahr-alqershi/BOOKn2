using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations;

/// <summary>
/// تكوين كيان إجراء الإدارة
/// Admin Action entity configuration
/// </summary>
public class AdminActionConfiguration : IEntityTypeConfiguration<AdminAction>
{
    public void Configure(EntityTypeBuilder<AdminAction> builder)
    {
        builder.ToTable("AdminActions");

        builder.HasKey(aa => aa.Id);

        builder.Property(b => b.Id).HasColumnName("ActionId").IsRequired();
        builder.Property(b => b.IsDeleted).HasDefaultValue(false);
        builder.Property(b => b.DeletedAt).HasColumnType("timestamp with time zone");

        builder.Property(aa => aa.AdminId)
            .IsRequired()
            .HasComment("معرف المدير");

        builder.Property(aa => aa.TargetId)
            .IsRequired()
            .HasComment("معرف الهدف");

        builder.Property(aa => aa.TargetType)
            .IsRequired()
            .HasMaxLength(100)
            .HasComment("نوع الهدف");

        builder.Property(aa => aa.ActionType)
            .IsRequired()
            .HasMaxLength(50)
            .HasComment("نوع الإجراء");

        builder.Property(aa => aa.Changes)
            .HasColumnType("text")
            .HasComment("تغييرات الإجراء");

        builder.Property(aa => aa.Timestamp)
            .IsRequired()
            .HasColumnType("timestamp with time zone")
            .HasComment("وقت الإجراء");

        // Indexes
        builder.HasIndex(aa => aa.AdminId)
            .HasDatabaseName("IX_AdminActions_AdminId");

        builder.HasIndex(aa => aa.TargetType)
            .HasDatabaseName("IX_AdminActions_TargetType");

        builder.HasIndex(aa => aa.ActionType)
            .HasDatabaseName("IX_AdminActions_ActionType");

        builder.HasIndex(aa => new { aa.AdminId, aa.Timestamp })
            .HasDatabaseName("IX_AdminActions_AdminId_Timestamp");

        builder.HasIndex(aa => new { aa.TargetId, aa.TargetType })
            .HasDatabaseName("IX_AdminActions_TargetId_TargetType");

        // Relationships
        builder.HasOne<User>()
            .WithMany()
            .HasForeignKey(aa => aa.AdminId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
