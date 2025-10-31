using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;
using Npgsql.EntityFrameworkCore.PostgreSQL;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

namespace YemenBooking.Infrastructure.Data.Configurations;

/// <summary>
/// تكوين كيان المستخدم
/// User entity configuration
/// </summary>
public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        // تعيين اسم الجدول
        // Set table name
        builder.ToTable("Users");

        // تعيين المفتاح الأساسي
        // Set primary key
        builder.HasKey(u => u.Id);

        // تكوين الخصائص الأساسية من BaseEntity
        builder.Property(b => b.Id).HasColumnName("UserId").IsRequired();
        builder.Property(b => b.IsDeleted).HasDefaultValue(false);
        builder.Property(b => b.DeletedAt).HasColumnType("timestamp with time zone");
        
        // تكوين الخصائص الأخرى
        builder.Property(u => u.Name).IsRequired().HasMaxLength(100);
        builder.Property(u => u.Email).IsRequired().HasMaxLength(255);
        builder.Property(u => u.Password).IsRequired();
        builder.Property(u => u.Phone).HasMaxLength(20);
        // Profile image path or URL
        builder.Property(u => u.ProfileImage)
            .HasMaxLength(500)
            .HasComment("رابط صورة الملف الشخصي (اختياري)");
        // Last updated date for the user
        builder.Property(b => b.UpdatedAt).HasColumnType("timestamp with time zone").IsRequired();
        builder.Property(u => u.CreatedAt).HasColumnType("timestamp with time zone").IsRequired();
        builder.Property(u => u.IsActive).HasDefaultValue(false);

        builder.Property(u => u.LastLoginDate)
            .HasColumnType("timestamp with time zone")
            .HasComment("تاريخ آخر تسجيل دخول");

        builder.Property(u => u.EmailConfirmed)
            .IsRequired()
            .HasDefaultValue(false)
            .HasComment("حالة تأكيد البريد الإلكتروني");

        builder.Property(u => u.EmailConfirmationToken)
            .HasMaxLength(500)
            .HasComment("رمز تأكيد البريد الإلكتروني");

        builder.Property(u => u.EmailConfirmationTokenExpires)
            .HasColumnType("timestamp with time zone")
            .HasComment("انتهاء صلاحية رمز تأكيد البريد الإلكتروني");

        builder.Property(u => u.PasswordResetToken)
            .HasMaxLength(500)
            .HasComment("رمز إعادة تعيين كلمة المرور");

        builder.Property(u => u.PasswordResetTokenExpires)
            .HasColumnType("timestamp with time zone")
            .HasComment("انتهاء صلاحية رمز إعادة تعيين كلمة المرور");

        builder.Property(u => u.SettingsJson)
            .IsRequired()
            .HasColumnType("text")
            .HasDefaultValue("{}")
            .HasComment("إعدادات المستخدم بصيغة JSON");

        builder.Property(u => u.FavoritesJson)
            .IsRequired()
            .HasColumnType("text")
            .HasDefaultValue("[]")
            .HasComment("قائمة مفضلة المستخدم بصيغة JSON");

        // TimeZoneId, Country, City - optional fields
        builder.Property(u => u.TimeZoneId)
            .HasMaxLength(100)
            .IsRequired(false)
            .HasComment("معرف المنطقة الزمنية للمستخدم (اختياري)");

        builder.Property(u => u.Country)
            .HasMaxLength(100)
            .IsRequired(false)
            .HasComment("الدولة (اختياري)");

        builder.Property(u => u.City)
            .HasMaxLength(100)
            .IsRequired(false)
            .HasComment("المدينة (اختياري)");

        builder.Property(u => u.TotalSpent)
            .HasPrecision(18, 2)
            .HasDefaultValue(0)
            .HasComment("إجمالي المبلغ المنفق");

        builder.Property(u => u.LoyaltyTier)
            .HasMaxLength(50)
            .IsRequired(false)
            .HasComment("فئة الولاء (اختياري)");

        builder.Property(u => u.IsEmailVerified)
            .IsRequired()
            .HasDefaultValue(false)
            .HasComment("هل تم التحقق من البريد الإلكتروني");

        builder.Property(u => u.EmailVerifiedAt)
            .HasColumnType("timestamp with time zone")
            .IsRequired(false)
            .HasComment("تاريخ التحقق من البريد الإلكتروني");

        builder.Property(u => u.LastSeen)
            .HasColumnType("timestamp with time zone")
            .IsRequired(false)
            .HasComment("تاريخ آخر ظهور");

        // الفهارس
        // Indexes
        builder.HasIndex(u => u.Email)
            .IsUnique()
            .HasDatabaseName("IX_Users_Email");

        builder.HasIndex(u => u.Phone)
            .HasDatabaseName("IX_Users_Phone");

        builder.HasIndex(u => u.IsDeleted)
            .HasDatabaseName("IX_Users_IsDeleted");

        builder.HasIndex(u => u.Name)
            .HasDatabaseName("IX_Users_Name_trgm")
            .HasMethod("gin")
            .HasOperators("gin_trgm_ops");

        // إعداد العلاقات
        // Configure relationships
        builder.HasMany(u => u.UserRoles)
            .WithOne(ur => ur.User)
            .HasForeignKey(ur => ur.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(u => u.Properties)
            .WithOne(p => p.Owner)
            .HasForeignKey(p => p.OwnerId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasMany(u => u.Bookings)
            .WithOne(b => b.User)
            .HasForeignKey(b => b.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasMany(u => u.StaffPositions)
            .WithOne(s => s.User)
            .HasForeignKey(s => s.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // البلاغات التي قام بها المستخدم
        builder.HasMany(u => u.ReportsMade)
            .WithOne(r => r.ReporterUser)
            .HasForeignKey(r => r.ReporterUserId)
            .OnDelete(DeleteBehavior.Restrict);

        // البلاغات المقدمة ضد المستخدم
        builder.HasMany(u => u.ReportsAgainstUser)
            .WithOne(r => r.ReportedUser)
            .HasForeignKey(r => r.ReportedUserId)
            .OnDelete(DeleteBehavior.SetNull);

        // تطبيق مرشح الحذف الناعم
        builder.HasQueryFilter(u => !u.IsDeleted);
    }
}
