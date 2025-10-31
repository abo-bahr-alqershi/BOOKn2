using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations;

/// <summary>
/// تكوين جدول القيود المحاسبية
/// Financial Transactions table configuration
/// </summary>
public class FinancialTransactionConfiguration : IEntityTypeConfiguration<FinancialTransaction>
{
    public void Configure(EntityTypeBuilder<FinancialTransaction> builder)
    {
        // تكوين اسم الجدول
        builder.ToTable("FinancialTransactions");

        // المفتاح الأساسي
        builder.HasKey(t => t.Id);

        // الخصائص الأساسية
        builder.Property(t => t.TransactionNumber)
            .IsRequired()
            .HasMaxLength(50);

        builder.HasIndex(t => t.TransactionNumber)
            .IsUnique()
            .HasDatabaseName("IX_FinancialTransactions_TransactionNumber");

        builder.Property(t => t.TransactionDate)
            .IsRequired();

        builder.Property(t => t.EntryType)
            .IsRequired();

        builder.Property(t => t.TransactionType)
            .IsRequired();

        builder.Property(t => t.Amount)
            .HasPrecision(18, 2)
            .IsRequired();

        builder.Property(t => t.Currency)
            .HasMaxLength(3)
            .HasDefaultValue("YER");

        builder.Property(t => t.ExchangeRate)
            .HasPrecision(18, 4)
            .HasDefaultValue(1);

        builder.Property(t => t.BaseAmount)
            .HasPrecision(18, 2);

        builder.Property(t => t.Description)
            .IsRequired()
            .HasMaxLength(500);

        builder.Property(t => t.Narration)
            .HasMaxLength(1000)
            .IsRequired(false);

        builder.Property(t => t.ReferenceNumber)
            .HasMaxLength(100)
            .IsRequired(false);

        builder.Property(t => t.DocumentType)
            .HasMaxLength(50)
            .IsRequired(false);

        builder.Property(t => t.Status)
            .IsRequired()
            .HasDefaultValue(TransactionStatus.Draft);

        builder.Property(t => t.IsPosted)
            .HasDefaultValue(false);

        builder.Property(t => t.IsReversed)
            .HasDefaultValue(false);

        builder.Property(t => t.FiscalYear)
            .IsRequired();

        builder.Property(t => t.FiscalPeriod)
            .IsRequired();

        builder.Property(t => t.BatchNumber)
            .HasMaxLength(50)
            .IsRequired(false);

        builder.Property(t => t.AttachmentsJson)
            .HasColumnType("text")
            .IsRequired(false);

        builder.Property(t => t.Notes)
            .HasMaxLength(1000)
            .IsRequired(false);

        builder.Property(t => t.Commission)
            .HasPrecision(18, 2);

        builder.Property(t => t.CommissionPercentage)
            .HasPrecision(5, 2);

        builder.Property(t => t.Tax)
            .HasPrecision(18, 2);

        builder.Property(t => t.TaxPercentage)
            .HasPrecision(5, 2);

        builder.Property(t => t.Discount)
            .HasPrecision(18, 2);

        builder.Property(t => t.DiscountPercentage)
            .HasPrecision(5, 2);

        builder.Property(t => t.NetAmount)
            .HasPrecision(18, 2);

        builder.Property(t => t.CreatedAt)
            .HasDefaultValueSql("NOW()");

        builder.Property(t => t.CancellationReason)
            .HasMaxLength(500)
            .IsRequired(false);

        builder.Property(t => t.IsAutomatic)
            .HasDefaultValue(false);

        builder.Property(t => t.AutomaticSource)
            .HasMaxLength(100)
            .IsRequired(false);

        builder.Property(t => t.Tags)
            .HasMaxLength(500)
            .IsRequired(false);

        // العلاقات
        // العلاقة مع الحساب المدين
        builder.HasOne(t => t.DebitAccount)
            .WithMany(a => a.DebitTransactions)
            .HasForeignKey(t => t.DebitAccountId)
            .OnDelete(DeleteBehavior.Restrict);

        // العلاقة مع الحساب الدائن
        builder.HasOne(t => t.CreditAccount)
            .WithMany(a => a.CreditTransactions)
            .HasForeignKey(t => t.CreditAccountId)
            .OnDelete(DeleteBehavior.Restrict);

        // العلاقة مع الحجز
        builder.HasOne(t => t.Booking)
            .WithMany()
            .HasForeignKey(t => t.BookingId)
            .OnDelete(DeleteBehavior.Restrict);

        // العلاقة مع الدفعة
        builder.HasOne(t => t.Payment)
            .WithMany()
            .HasForeignKey(t => t.PaymentId)
            .OnDelete(DeleteBehavior.Restrict);

        // العلاقة مع المستخدم الطرف الأول
        builder.HasOne(t => t.FirstPartyUser)
            .WithMany()
            .HasForeignKey(t => t.FirstPartyUserId)
            .OnDelete(DeleteBehavior.Restrict);

        // العلاقة مع المستخدم الطرف الثاني
        builder.HasOne(t => t.SecondPartyUser)
            .WithMany()
            .HasForeignKey(t => t.SecondPartyUserId)
            .OnDelete(DeleteBehavior.Restrict);

        // العلاقة مع العقار
        builder.HasOne(t => t.Property)
            .WithMany()
            .HasForeignKey(t => t.PropertyId)
            .OnDelete(DeleteBehavior.Restrict);

        // العلاقة مع الوحدة
        builder.HasOne(t => t.Unit)
            .WithMany()
            .HasForeignKey(t => t.UnitId)
            .OnDelete(DeleteBehavior.Restrict);

        // العلاقة مع القيد العكسي
        builder.HasOne(t => t.ReverseTransaction)
            .WithMany()
            .HasForeignKey(t => t.ReverseTransactionId)
            .OnDelete(DeleteBehavior.Restrict);

        // العلاقات مع المستخدمين (الإنشاء، التعديل، الموافقة، الإلغاء)
        builder.HasOne(t => t.CreatedByUser)
            .WithMany()
            .HasForeignKey(t => t.CreatedBy)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(t => t.UpdatedByUser)
            .WithMany()
            .HasForeignKey(t => t.UpdatedBy)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(t => t.ApprovedByUser)
            .WithMany()
            .HasForeignKey(t => t.ApprovedBy)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(t => t.CancelledByUser)
            .WithMany()
            .HasForeignKey(t => t.CancelledBy)
            .OnDelete(DeleteBehavior.Restrict);

        // الفهارس
        builder.HasIndex(t => t.TransactionDate)
            .HasDatabaseName("IX_FinancialTransactions_TransactionDate");

        builder.HasIndex(t => t.EntryType)
            .HasDatabaseName("IX_FinancialTransactions_EntryType");

        builder.HasIndex(t => t.TransactionType)
            .HasDatabaseName("IX_FinancialTransactions_TransactionType");

        builder.HasIndex(t => t.Status)
            .HasDatabaseName("IX_FinancialTransactions_Status");

        builder.HasIndex(t => t.BookingId)
            .HasDatabaseName("IX_FinancialTransactions_BookingId");

        builder.HasIndex(t => t.PaymentId)
            .HasDatabaseName("IX_FinancialTransactions_PaymentId");

        builder.HasIndex(t => t.FirstPartyUserId)
            .HasDatabaseName("IX_FinancialTransactions_FirstPartyUserId");

        builder.HasIndex(t => t.SecondPartyUserId)
            .HasDatabaseName("IX_FinancialTransactions_SecondPartyUserId");

        builder.HasIndex(t => t.PropertyId)
            .HasDatabaseName("IX_FinancialTransactions_PropertyId");

        builder.HasIndex(t => t.UnitId)
            .HasDatabaseName("IX_FinancialTransactions_UnitId");

        builder.HasIndex(t => t.FiscalYear)
            .HasDatabaseName("IX_FinancialTransactions_FiscalYear");

        builder.HasIndex(t => new { t.FiscalYear, t.FiscalPeriod })
            .HasDatabaseName("IX_FinancialTransactions_FiscalYear_Period");

        builder.HasIndex(t => t.IsPosted)
            .HasDatabaseName("IX_FinancialTransactions_IsPosted");

        builder.HasIndex(t => t.IsReversed)
            .HasDatabaseName("IX_FinancialTransactions_IsReversed");

        builder.HasIndex(t => t.BatchNumber)
            .HasDatabaseName("IX_FinancialTransactions_BatchNumber");

        builder.HasIndex(t => t.ReferenceNumber)
            .HasDatabaseName("IX_FinancialTransactions_ReferenceNumber");

        builder.HasIndex(t => t.DebitAccountId)
            .HasDatabaseName("IX_FinancialTransactions_DebitAccountId");

        builder.HasIndex(t => t.CreditAccountId)
            .HasDatabaseName("IX_FinancialTransactions_CreditAccountId");

        // فهرس مركب للبحث السريع
        builder.HasIndex(t => new { t.TransactionDate, t.Status, t.IsPosted })
            .HasDatabaseName("IX_FinancialTransactions_Search");

        // فهرس مركب للتقارير المالية
        builder.HasIndex(t => new { t.FiscalYear, t.FiscalPeriod, t.Status, t.IsPosted })
            .HasDatabaseName("IX_FinancialTransactions_Reporting");

        // ========== فهارس محسنة لحساب الأرصدة بشكل سريع ==========
        // PostgreSQL supports partial indexes and included columns
        
        // فهرس محسن لحساب أرصدة الحسابات المدينة
        builder.HasIndex(t => new { t.DebitAccountId, t.TransactionDate })
            .HasDatabaseName("IX_FinancialTransactions_DebitBalance")
            .IncludeProperties(t => t.Amount)
            .HasFilter("\"DebitAccountId\" IS NOT NULL AND \"Status\" = 3 AND \"IsPosted\" = true"); // 3 = Posted

        // فهرس محسن لحساب أرصدة الحسابات الدائنة
        builder.HasIndex(t => new { t.CreditAccountId, t.TransactionDate })
            .HasDatabaseName("IX_FinancialTransactions_CreditBalance")
            .IncludeProperties(t => t.Amount)
            .HasFilter("\"CreditAccountId\" IS NOT NULL AND \"Status\" = 3 AND \"IsPosted\" = true");

        // فهرس مركب لحساب الأرصدة بتاريخ معين
        builder.HasIndex(t => new { t.TransactionDate, t.DebitAccountId, t.CreditAccountId })
            .HasDatabaseName("IX_FinancialTransactions_BalanceQuery")
            .IncludeProperties(t => new { t.Amount, t.Currency, t.BaseAmount })
            .HasFilter("\"Status\" = 3 AND \"IsPosted\" = true");

        // فهرس لتحسين أداء حساب مجموع المبالغ حسب النوع
        builder.HasIndex(t => new { t.TransactionType, t.TransactionDate })
            .HasDatabaseName("IX_FinancialTransactions_TypeSummary")
            .IncludeProperties(t => t.Amount)
            .HasFilter("\"Status\" = 3 AND \"IsPosted\" = true");

        // فهرس covering للاستعلامات الأكثر شيوعاً
        builder.HasIndex(t => new { t.TransactionDate })
            .HasDatabaseName("IX_FinancialTransactions_CoveringIndex")
            .IncludeProperties(t => new { 
                t.Amount, 
                t.DebitAccountId, 
                t.CreditAccountId,
                t.TransactionType,
                t.Currency 
            })
            .HasFilter("\"Status\" = 3 AND \"IsPosted\" = true");

        // فهرس لتحسين أداء كشف الحساب
        builder.HasIndex(t => new { t.DebitAccountId, t.TransactionDate })
            .HasDatabaseName("IX_FinancialTransactions_AccountStatement_Debit")
            .IncludeProperties(t => new { 
                t.Amount, 
                t.Description,
                t.TransactionNumber,
                t.ReferenceNumber,
                t.CreditAccountId 
            })
            .HasFilter("\"Status\" = 3 AND \"IsPosted\" = true");

        // فهرس مماثل للحسابات الدائنة
        builder.HasIndex(t => new { t.CreditAccountId, t.TransactionDate })
            .HasDatabaseName("IX_FinancialTransactions_AccountStatement_Credit")
            .IncludeProperties(t => new { 
                t.Amount,
                t.Description,
                t.TransactionNumber,
                t.ReferenceNumber,
                t.DebitAccountId
            })
            .HasFilter("\"Status\" = 3 AND \"IsPosted\" = true");

        // فهرس للتقارير الشهرية والسنوية
        builder.HasIndex(t => new { t.FiscalYear, t.FiscalPeriod, t.TransactionType })
            .HasDatabaseName("IX_FinancialTransactions_MonthlyReporting")
            .IncludeProperties(t => new { t.Amount, t.BaseAmount })
            .HasFilter("\"Status\" = 3 AND \"IsPosted\" = true");

        builder.HasIndex(t => new { t.BookingId, t.TransactionDate })
            .HasDatabaseName("IX_FinancialTransactions_Booking_Date");

        builder.HasIndex(t => new { t.PaymentId, t.TransactionDate })
            .HasDatabaseName("IX_FinancialTransactions_Payment_Date");

        builder.HasIndex(t => new { t.PropertyId, t.TransactionDate })
            .HasDatabaseName("IX_FinancialTransactions_Property_Date");

        builder.HasIndex(t => new { t.FirstPartyUserId, t.TransactionDate })
            .HasDatabaseName("IX_FinancialTransactions_FirstUser_Date");

        builder.HasIndex(t => new { t.SecondPartyUserId, t.TransactionDate })
            .HasDatabaseName("IX_FinancialTransactions_SecondUser_Date");

        builder.HasIndex(t => new { t.DebitAccountId, t.TransactionDate })
            .HasDatabaseName("IX_FinancialTransactions_Debit_Date");

        builder.HasIndex(t => new { t.CreditAccountId, t.TransactionDate })
            .HasDatabaseName("IX_FinancialTransactions_Credit_Date");
    }
}
