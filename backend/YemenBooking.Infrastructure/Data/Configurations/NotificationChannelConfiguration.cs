using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations;

/// <summary>
/// تكوين جدول قنوات الإشعارات
/// Notification channels table configuration
/// </summary>
public class NotificationChannelConfiguration : IEntityTypeConfiguration<NotificationChannel>
{
    public void Configure(EntityTypeBuilder<NotificationChannel> builder)
    {
        // تكوين الجدول
        builder.ToTable("NotificationChannels");
        
        // تكوين المفتاح الأساسي
        builder.HasKey(nc => nc.Id);
        
        // تكوين الخصائص
        builder.Property(nc => nc.Name)
            .IsRequired()
            .HasMaxLength(100);
            
        builder.Property(nc => nc.Identifier)
            .IsRequired()
            .HasMaxLength(50);
            
        // إنشاء فهرس فريد على المعرف
        builder.HasIndex(nc => nc.Identifier)
            .IsUnique()
            .HasDatabaseName("IX_NotificationChannels_Identifier");
            
        builder.Property(nc => nc.Description)
            .HasMaxLength(500);
            
        builder.Property(nc => nc.Icon)
            .HasMaxLength(50);
            
        builder.Property(nc => nc.Color)
            .HasMaxLength(20);
            
        builder.Property(nc => nc.Type)
            .IsRequired()
            .HasMaxLength(20)
            .HasDefaultValue("CUSTOM");
            
        builder.Property(nc => nc.IsActive)
            .HasDefaultValue(true);
            
        builder.Property(nc => nc.IsPrivate)
            .HasDefaultValue(false);
            
        builder.Property(nc => nc.IsDeletable)
            .HasDefaultValue(true);
            
        builder.Property(nc => nc.Settings)
            .HasColumnType("text");
            
        // تكوين قوائم JSON
        builder.Property(nc => nc.AllowedRoles)
            .HasConversion(
                v => string.Join(',', v),
                v => v.Split(',', StringSplitOptions.RemoveEmptyEntries).ToList()
            )
            .HasMaxLength(500);
            
        // الفهارس
        builder.HasIndex(nc => nc.Type)
            .HasDatabaseName("IX_NotificationChannels_Type");
            
        builder.HasIndex(nc => nc.IsActive)
            .HasDatabaseName("IX_NotificationChannels_IsActive");
            
        builder.HasIndex(nc => new { nc.CreatedBy, nc.IsActive })
            .HasDatabaseName("IX_NotificationChannels_CreatedBy_IsActive");
            
        // العلاقات
        builder.HasOne(nc => nc.Creator)
            .WithMany()
            .HasForeignKey(nc => nc.CreatedBy)
            .OnDelete(DeleteBehavior.SetNull);
            
        builder.HasMany(nc => nc.UserChannels)
            .WithOne(uc => uc.Channel)
            .HasForeignKey(uc => uc.ChannelId)
            .OnDelete(DeleteBehavior.Cascade);
            
        builder.HasMany(nc => nc.NotificationHistories)
            .WithOne(nh => nh.Channel)
            .HasForeignKey(nh => nh.ChannelId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

/// <summary>
/// تكوين جدول اشتراكات المستخدمين في القنوات
/// User channel subscriptions table configuration
/// </summary>
public class UserChannelConfiguration : IEntityTypeConfiguration<UserChannel>
{
    public void Configure(EntityTypeBuilder<UserChannel> builder)
    {
        // تكوين الجدول
        builder.ToTable("UserChannels");
        
        // تكوين المفتاح الأساسي
        builder.HasKey(uc => uc.Id);
        
        // تكوين الخصائص
        builder.Property(uc => uc.IsActive)
            .HasDefaultValue(true);
            
        builder.Property(uc => uc.IsMuted)
            .HasDefaultValue(false);
            
        builder.Property(uc => uc.SubscribedAt)
            .HasDefaultValueSql("NOW()");
            
        builder.Property(uc => uc.Notes)
            .HasMaxLength(500);
            
        // الفهارس
        builder.HasIndex(uc => new { uc.UserId, uc.ChannelId })
            .IsUnique()
            .HasDatabaseName("IX_UserChannels_UserId_ChannelId");
            
        builder.HasIndex(uc => new { uc.ChannelId, uc.IsActive })
            .HasDatabaseName("IX_UserChannels_ChannelId_IsActive");
            
        builder.HasIndex(uc => uc.IsActive)
            .HasDatabaseName("IX_UserChannels_IsActive");
            
        // العلاقات
        builder.HasOne(uc => uc.User)
            .WithMany()
            .HasForeignKey(uc => uc.UserId)
            .OnDelete(DeleteBehavior.Cascade);
            
        builder.HasOne(uc => uc.Channel)
            .WithMany(c => c.UserChannels)
            .HasForeignKey(uc => uc.ChannelId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

/// <summary>
/// تكوين جدول سجل إشعارات القنوات
/// Notification channel history table configuration
/// </summary>
public class NotificationChannelHistoryConfiguration : IEntityTypeConfiguration<NotificationChannelHistory>
{
    public void Configure(EntityTypeBuilder<NotificationChannelHistory> builder)
    {
        // تكوين الجدول
        builder.ToTable("NotificationChannelHistories");
        
        // تكوين المفتاح الأساسي
        builder.HasKey(nh => nh.Id);
        
        // تكوين الخصائص
        builder.Property(nh => nh.Title)
            .IsRequired()
            .HasMaxLength(200);
            
        builder.Property(nh => nh.Content)
            .IsRequired()
            .HasMaxLength(1000);
            
        builder.Property(nh => nh.Type)
            .IsRequired()
            .HasMaxLength(20)
            .HasDefaultValue("INFO");
            
        builder.Property(nh => nh.SentAt)
            .HasDefaultValueSql("NOW()");
            
        // الفهارس
        builder.HasIndex(nh => nh.ChannelId)
            .HasDatabaseName("IX_NotificationChannelHistories_ChannelId");
            
        builder.HasIndex(nh => nh.SentAt)
            .HasDatabaseName("IX_NotificationChannelHistories_SentAt");
            
        builder.HasIndex(nh => new { nh.ChannelId, nh.SentAt })
            .HasDatabaseName("IX_NotificationChannelHistories_ChannelId_SentAt");
            
        // العلاقات
        builder.HasOne(nh => nh.Channel)
            .WithMany(c => c.NotificationHistories)
            .HasForeignKey(nh => nh.ChannelId)
            .OnDelete(DeleteBehavior.Cascade);
            
        builder.HasOne(nh => nh.Sender)
            .WithMany()
            .HasForeignKey(nh => nh.SenderId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}
