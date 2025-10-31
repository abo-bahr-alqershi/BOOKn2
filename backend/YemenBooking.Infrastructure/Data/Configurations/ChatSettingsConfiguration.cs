using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations
{
    /// <summary>
    /// تكوين كيان إعدادات الشات
    /// Configuration for ChatSettings entity
    /// </summary>
    public class ChatSettingsConfiguration : IEntityTypeConfiguration<ChatSettings>
    {
        public void Configure(EntityTypeBuilder<ChatSettings> builder)
        {
            builder.ToTable("ChatSettings");

            builder.HasKey(s => s.Id);

            builder.Property(s => s.UserId)
                .IsRequired()
                .HasComment("معرف المستخدم");

            builder.Property(s => s.NotificationsEnabled)
                .IsRequired()
                .HasDefaultValue(true)
                .HasComment("تنبيهات مفعلة");

            builder.Property(s => s.SoundEnabled)
                .IsRequired()
                .HasDefaultValue(true)
                .HasComment("صوت مفعّل");

            builder.Property(s => s.ShowReadReceipts)
                .IsRequired()
                .HasDefaultValue(true)
                .HasComment("عرض إيصالات القراءة");

            builder.Property(s => s.ShowTypingIndicator)
                .IsRequired()
                .HasDefaultValue(true)
                .HasComment("عرض مؤشر الكتابة");

            builder.Property(s => s.Theme)
                .IsRequired()
                .HasMaxLength(20)
                .HasComment("المظهر: light, dark, auto");

            builder.Property(s => s.FontSize)
                .IsRequired()
                .HasMaxLength(10)
                .HasComment("حجم الخط: small, medium, large");

            builder.Property(s => s.AutoDownloadMedia)
                .IsRequired()
                .HasDefaultValue(false)
                .HasComment("التحميل التلقائي للوسائط");

            builder.Property(s => s.BackupMessages)
                .IsRequired()
                .HasDefaultValue(false)
                .HasComment("نسخ احتياطي للرسائل");

            builder.HasIndex(s => s.UserId)
                .IsUnique()
                .HasDatabaseName("IX_ChatSettings_UserId");
        }
    }
} 