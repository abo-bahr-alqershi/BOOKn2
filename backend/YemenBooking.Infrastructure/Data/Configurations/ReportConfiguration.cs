using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations;

/// <summary>
/// إعدادات كيان البلاغات
/// Configuration for Report entity
/// </summary>
public class ReportConfiguration : IEntityTypeConfiguration<Report>
{
    public void Configure(EntityTypeBuilder<Report> builder)
    {
        builder.ToTable("Reports");
        builder.HasKey(r => r.Id);

        builder.Property(r => r.Reason)
            .IsRequired()
            .HasMaxLength(250);

        builder.Property(r => r.Description)
            .IsRequired()
            .HasMaxLength(1000);

        // إعداد حقل حالة البلاغ
        builder.Property(r => r.Status)
            .IsRequired()
            .HasMaxLength(50);

        // إعداد حقل ملاحظات الإجراء من الإدارة
        builder.Property(r => r.ActionNote)
            .HasMaxLength(1000);

        // إعداد معرف مسؤول الإدارة الذي اتخذ الإجراء
        builder.Property(r => r.AdminId)
            .IsRequired(false);

        builder.Property(r => r.CreatedAt)
            .IsRequired();

        builder.HasOne(r => r.ReporterUser)
            .WithMany(u => u.ReportsMade)
            .HasForeignKey(r => r.ReporterUserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(r => r.ReportedUser)
            .WithMany(u => u.ReportsAgainstUser)
            .HasForeignKey(r => r.ReportedUserId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasOne(r => r.ReportedProperty)
            .WithMany(p => p.Reports)
            .HasForeignKey(r => r.ReportedPropertyId)
            .OnDelete(DeleteBehavior.SetNull);
    }
} 