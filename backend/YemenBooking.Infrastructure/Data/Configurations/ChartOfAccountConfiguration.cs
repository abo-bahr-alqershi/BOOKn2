using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations;

/// <summary>
/// تكوين جدول دليل الحسابات
/// Chart of Accounts table configuration
/// </summary>
public class ChartOfAccountConfiguration : IEntityTypeConfiguration<ChartOfAccount>
{
    public void Configure(EntityTypeBuilder<ChartOfAccount> builder)
    {
        // تكوين اسم الجدول
        builder.ToTable("ChartOfAccounts");

        // المفتاح الأساسي
        builder.HasKey(a => a.Id);

        // الخصائص الأساسية
        builder.Property(a => a.AccountNumber)
            .IsRequired()
            .HasMaxLength(20);

        builder.HasIndex(a => a.AccountNumber)
            .IsUnique()
            .HasDatabaseName("IX_ChartOfAccounts_AccountNumber");

        builder.Property(a => a.NameAr)
            .IsRequired()
            .HasMaxLength(200);

        builder.Property(a => a.NameEn)
            .IsRequired()
            .HasMaxLength(200);

        builder.Property(a => a.AccountType)
            .IsRequired();

        builder.Property(a => a.Category)
            .IsRequired();

        builder.Property(a => a.NormalBalance)
            .IsRequired();

        builder.Property(a => a.Level)
            .HasDefaultValue(1);

        builder.Property(a => a.Description)
            .HasMaxLength(500);

        builder.Property(a => a.Balance)
            .HasPrecision(18, 2)
            .HasDefaultValue(0);

        builder.Property(a => a.Currency)
            .HasMaxLength(3)
            .HasDefaultValue("YER");

        builder.Property(a => a.IsActive)
            .HasDefaultValue(true);

        builder.Property(a => a.IsSystemAccount)
            .HasDefaultValue(false);

        builder.Property(a => a.CanPost)
            .HasDefaultValue(false);

        builder.Property(a => a.CreatedAt)
            .HasDefaultValueSql("NOW()");

        // العلاقات
        // العلاقة مع الحساب الأصل
        builder.HasOne(a => a.ParentAccount)
            .WithMany(p => p.SubAccounts)
            .HasForeignKey(a => a.ParentAccountId)
            .OnDelete(DeleteBehavior.Restrict);

        // العلاقة مع المستخدم
        builder.HasOne(a => a.User)
            .WithMany()
            .HasForeignKey(a => a.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        // العلاقة مع العقار
        builder.HasOne(a => a.Property)
            .WithMany()
            .HasForeignKey(a => a.PropertyId)
            .OnDelete(DeleteBehavior.Restrict);

        // الفهارس
        builder.HasIndex(a => a.AccountType)
            .HasDatabaseName("IX_ChartOfAccounts_AccountType");

        builder.HasIndex(a => a.Category)
            .HasDatabaseName("IX_ChartOfAccounts_Category");

        builder.HasIndex(a => a.ParentAccountId)
            .HasDatabaseName("IX_ChartOfAccounts_ParentAccountId");

        builder.HasIndex(a => a.UserId)
            .HasDatabaseName("IX_ChartOfAccounts_UserId");

        builder.HasIndex(a => a.PropertyId)
            .HasDatabaseName("IX_ChartOfAccounts_PropertyId");

        builder.HasIndex(a => a.IsActive)
            .HasDatabaseName("IX_ChartOfAccounts_IsActive");

        builder.HasIndex(a => new { a.AccountType, a.IsActive })
            .HasDatabaseName("IX_ChartOfAccounts_AccountType_IsActive");

        // فهرس مركب للبحث السريع
        builder.HasIndex(a => new { a.AccountNumber, a.NameAr, a.NameEn })
            .HasDatabaseName("IX_ChartOfAccounts_Search");

        // ========== فهارس محسنة لأداء عالي ==========
        // PostgreSQL supports both partial indexes and included columns
        
        // فهرس covering للاستعلامات الأكثر شيوعاً في دليل الحسابات
        builder.HasIndex(a => new { a.IsActive, a.ParentAccountId })
            .HasDatabaseName("IX_ChartOfAccounts_TreeQuery")
            .IncludeProperties(a => new { 
                a.AccountNumber, 
                a.NameAr, 
                a.NameEn,
                a.AccountType,
                a.Category,
                a.Balance,
                a.Level,
                a.CanPost
            })
            .HasFilter("\"IsActive\" = true");

        // فهرس محسن لاستعلامات حساب الأرصدة
        builder.HasIndex(a => new { a.Id, a.AccountType, a.IsActive })
            .HasDatabaseName("IX_ChartOfAccounts_BalanceCalculation")
            .IncludeProperties(a => new { 
                a.AccountNumber,
                a.NameAr,
                a.Balance,
                a.NormalBalance
            })
            .HasFilter("\"IsActive\" = true");

        // فهرس للحصول على حسابات بنوع معين
        builder.HasIndex(a => new { a.AccountType, a.IsActive, a.CanPost })
            .HasDatabaseName("IX_ChartOfAccounts_TypeFilter")
            .IncludeProperties(a => new {
                a.AccountNumber,
                a.NameAr,
                a.NameEn,
                a.Balance,
                a.ParentAccountId,
                a.Level
            })
            .HasFilter("\"IsActive\" = true");

        // فهرس للحسابات الفرعية
        builder.HasIndex(a => new { a.ParentAccountId, a.IsActive, a.Level })
            .HasDatabaseName("IX_ChartOfAccounts_SubAccounts")
            .IncludeProperties(a => new {
                a.AccountNumber,
                a.NameAr,
                a.NameEn,
                a.AccountType,
                a.Balance,
                a.CanPost
            })
            .HasFilter("\"ParentAccountId\" IS NOT NULL AND \"IsActive\" = true");

        // فهرس للحسابات الرئيسية فقط
        builder.HasIndex(a => new { a.Level, a.IsActive })
            .HasDatabaseName("IX_ChartOfAccounts_MainAccounts")
            .IncludeProperties(a => new {
                a.AccountNumber,
                a.NameAr,
                a.NameEn,
                a.AccountType,
                a.Balance
            })
            .HasFilter("\"ParentAccountId\" IS NULL AND \"IsActive\" = true");

        // فهرس للحسابات القابلة للترحيل
        builder.HasIndex(a => new { a.CanPost, a.IsActive })
            .HasDatabaseName("IX_ChartOfAccounts_PostableAccounts")
            .IncludeProperties(a => new {
                a.AccountNumber,
                a.NameAr,
                a.AccountType,
                a.Balance,
                a.ParentAccountId
            })
            .HasFilter("\"CanPost\" = true AND \"IsActive\" = true");

        // فهرس للحسابات النظامية
        builder.HasIndex(a => new { a.IsSystemAccount, a.IsActive })
            .HasDatabaseName("IX_ChartOfAccounts_SystemAccounts")
            .IncludeProperties(a => new {
                a.AccountNumber,
                a.NameAr,
                a.AccountType
            })
            .HasFilter("\"IsSystemAccount\" = true AND \"IsActive\" = true");

        // فهرس للبحث السريع بالاسم
        builder.HasIndex(a => a.NameAr)
            .HasDatabaseName("IX_ChartOfAccounts_NameAr")
            .IncludeProperties(a => new { 
                a.AccountNumber,
                a.AccountType,
                a.IsActive 
            })
            .HasFilter("\"IsActive\" = true");

        // فهرس للبحث السريع بالاسم الانجليزي
        builder.HasIndex(a => a.NameEn)
            .HasDatabaseName("IX_ChartOfAccounts_NameEn")
            .IncludeProperties(a => new { 
                a.AccountNumber,
                a.AccountType,
                a.IsActive 
            })
            .HasFilter("\"IsActive\" = true");
    }
}
