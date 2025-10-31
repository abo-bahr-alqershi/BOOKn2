using Microsoft.EntityFrameworkCore;
using YemenBooking.Core.Entities;
using YemenBooking.Infrastructure.Data.Configurations;
using YemenBooking.Core.Seeds;
// usings for automatic audit logging
using Microsoft.AspNetCore.Http;
using System.Diagnostics;
using System.Text.Json;
using System.Linq;
using System.Security.Claims;
using YemenBooking.Core.Enums;
using EntityUserRole = YemenBooking.Core.Entities.UserRole;
using System.Reflection;
using System.ComponentModel.DataAnnotations;
using YemenBooking.Application.Common.Interfaces;
using Npgsql.EntityFrameworkCore.PostgreSQL;

namespace YemenBooking.Infrastructure.Data.Context;

/// <summary>
/// سياق قاعدة البيانات الرئيسي لنظام حجوزات اليمن
/// Main database context for Yemen Booking system
/// </summary>
public class YemenBookingDbContext : DbContext
{
    // حقول المستخدم الحالي وسياق HTTP للوصول إلى بيانات الطلب
    private readonly IHttpContextAccessor _httpContextAccessor;

    /// <summary>
    /// تهيئة سياق قاعدة البيانات مع خدمات المستخدم الحالي وسياق HTTP
    /// </summary>
    public YemenBookingDbContext(
        DbContextOptions<YemenBookingDbContext> options,
        IHttpContextAccessor httpContextAccessor
    ) : base(options)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    #region DbSets

    /// <summary>
    /// جدول المستخدمين
    /// Users table
    /// </summary>
    public DbSet<User> Users { get; set; }

    /// <summary>
    /// جدول الأدوار
    /// Roles table
    /// </summary>
    public DbSet<Role> Roles { get; set; }

    /// <summary>
    /// جدول أدوار المستخدمين
    /// User roles table
    /// </summary>
    public DbSet<EntityUserRole> UserRoles { get; set; }

    /// <summary>
    /// جدول أنواع الكيانات
    /// Property types table
    /// </summary>
    public DbSet<PropertyType> PropertyTypes { get; set; }

    /// <summary>
    /// جدول الكيانات
    /// Properties table
    /// </summary>
    public DbSet<Property> Properties { get; set; }

    /// <summary>
    /// جدول صور الكيانات
    /// Property images table
    /// </summary>
    public DbSet<PropertyImage> PropertyImages { get; set; }

    /// <summary>
    /// جدول صور الأقسام المخصص
    /// </summary>
    public DbSet<SectionImage> SectionImages { get; set; }

    /// <summary>
    /// جدول صور "عقار في قسم" المخصص
    /// </summary>
    public DbSet<PropertyInSectionImage> PropertyInSectionImages { get; set; }

    /// <summary>
    /// جدول صور "وحدة في قسم" المخصص
    /// </summary>
    public DbSet<UnitInSectionImage> UnitInSectionImages { get; set; }

    /// <summary>
    /// جدول أنواع الوحدات
    /// Unit types table
    /// </summary>
    public DbSet<UnitType> UnitTypes { get; set; }

    /// <summary>
    /// جدول الوحدات
    /// Units table
    /// </summary>
    public DbSet<Unit> Units { get; set; }

    /// <summary>
    /// جدول الأقسام
    /// Sections table
    /// </summary>
    public DbSet<Section> Sections { get; set; }

    // Legacy SectionItems table removed in favor of rich entities PropertyInSections and UnitInSections
    
    /// <summary>
    /// جدول عقارات الأقسام (سجل غني)
    /// </summary>
    public DbSet<PropertyInSection> PropertyInSections { get; set; }

    /// <summary>
    /// جدول وحدات الأقسام (سجل غني)
    /// </summary>
    public DbSet<UnitInSection> UnitInSections { get; set; }

    /// <summary>
    /// جدول الحجوزات
    /// Bookings table
    /// </summary>
    public DbSet<Booking> Bookings { get; set; }

    /// <summary>
    /// جدول المدفوعات
    /// Payments table
    /// </summary>
    public DbSet<Payment> Payments { get; set; }

    /// <summary>
    /// جدول خدمات الكيانات
    /// Property services table
    /// </summary>
    public DbSet<PropertyService> PropertyServices { get; set; }

    /// <summary>
    /// جدول خدمات الحجوزات
    /// Booking services table
    /// </summary>
    public DbSet<BookingService> BookingServices { get; set; }

    /// <summary>
    /// جدول المرافق
    /// Amenities table
    /// </summary>
    public DbSet<Amenity> Amenities { get; set; }

    /// <summary>
    /// جدول مرافق أنواع الكيانات
    /// Property type amenities table
    /// </summary>
    public DbSet<PropertyTypeAmenity> PropertyTypeAmenities { get; set; }

    /// <summary>
    /// جدول مرافق الكيانات
    /// Property amenities table
    /// </summary>
    public DbSet<PropertyAmenity> PropertyAmenities { get; set; }

    /// <summary>
    /// جدول التقييمات
    /// Reviews table
    /// </summary>
    public DbSet<Review> Reviews { get; set; }

    /// <summary>
    /// جدول سياسات الكيانات
    /// Property policies table
    /// </summary>
    public DbSet<PropertyPolicy> PropertyPolicies { get; set; }

    /// <summary>
    /// جدول الموظفين
    /// Staff table
    /// </summary>
    public DbSet<Staff> Staff { get; set; }

    /// <summary>
    /// جدول إجراءات الإدارة
    /// Admin actions table
    /// </summary>
    public DbSet<AdminAction> AdminActions { get; set; }

    /// <summary>
    /// جدول الإشعارات
    /// Notifications table
    /// </summary>
    public DbSet<Notification> Notifications { get; set; }

    /// <summary>
    /// جدول قنوات الإشعارات
    /// Notification channels table
    /// </summary>
    public DbSet<NotificationChannel> NotificationChannels { get; set; }

    /// <summary>
    /// جدول اشتراكات المستخدمين في القنوات
    /// User channel subscriptions table
    /// </summary>
    public DbSet<UserChannel> UserChannels { get; set; }

    /// <summary>
    /// جدول سجل إشعارات القنوات
    /// Notification channel history table
    /// </summary>
    public DbSet<NotificationChannelHistory> NotificationChannelHistories { get; set; }

    /// <summary>
    /// جدول سجلات التدقيق
    /// Audit logs table
    /// </summary>
    public DbSet<AuditLog> AuditLogs { get; set; }

    /// <summary>
    /// جدول إعدادات المستخدم
    /// User settings table
    /// </summary>
    public DbSet<UserSettings> UserSettings { get; set; }

    /// <summary>
    /// جدول صور التقييمات
    /// Review images table
    /// </summary>
    public DbSet<ReviewImage> ReviewImages { get; set; }

    /// <summary>
    /// جدول ردود التقييمات
    /// Review responses table
    /// </summary>
    public DbSet<ReviewResponse> ReviewResponses { get; set; }

    /// <summary>
    /// جدول البلاغات
    /// Reports table
    /// </summary>
    public DbSet<Report> Reports { get; set; }

    /// <summary>
    /// جدول حقول أنواع الكيانات
    /// Property type fields table
    /// </summary>
    public DbSet<UnitTypeField> UnitTypeFields { get; set; }

    /// <summary>
    /// جدول مجموعات الحقول
    /// Field groups table
    /// </summary>
    public DbSet<FieldGroup> FieldGroups { get; set; }

    /// <summary>
    /// جدول ارتباط الحقول بالمجموعات
    /// Field group fields table
    /// </summary>
    public DbSet<FieldGroupField> FieldGroupFields { get; set; }

    /// <summary>
    /// جدول الفلاتر
    /// Search filters table
    /// </summary>
    public DbSet<SearchFilter> SearchFilters { get; set; }

    /// <summary>
    /// جدول قيم الحقول للوحدات
    /// Unit field values table
    /// </summary>
    public DbSet<UnitFieldValue> UnitFieldValues { get; set; }

    /// <summary>
    /// جدول سجلات البحث
    /// Search logs table
    /// </summary>
    public DbSet<SearchLog> SearchLogs { get; set; }

    /// <summary>
    /// جدول المحادثات
    /// Chat conversations table
    /// </summary>
    public DbSet<YemenBooking.Core.Entities.ChatConversation> ChatConversations { get; set; }

    /// <summary>
    /// جدول الرسائل
    /// Chat messages table
    /// </summary>
    public DbSet<YemenBooking.Core.Entities.ChatMessage> ChatMessages { get; set; }

    /// <summary>
    /// جدول التفاعلات على الرسائل
    /// Message reactions table
    /// </summary>
    public DbSet<YemenBooking.Core.Entities.MessageReaction> MessageReactions { get; set; }

    /// <summary>
    /// جدول مرفقات المحادثات
    /// Chat attachments table
    /// </summary>
    public DbSet<YemenBooking.Core.Entities.ChatAttachment> ChatAttachments { get; set; }

    /// <summary>
    /// جدول إعدادات الشات لكل مستخدم
    /// Chat settings table
    /// </summary>
    public DbSet<YemenBooking.Core.Entities.ChatSettings> ChatSettings { get; set; }

    /// <summary>
    /// جدول بيانات تعريف الفهارس للتحديث التدريجي
    /// Index metadata table for incremental indexing
    /// </summary>
    public DbSet<IndexMetadata> IndexMetadata { get; set; }

    /// <summary>
    /// جدول العملات
    /// Currencies table
    /// </summary>
    public DbSet<Currency> Currencies { get; set; }

    /// <summary>
    /// جدول المدن
    /// Cities table
    /// </summary>
    public DbSet<City> Cities { get; set; }


    /// <summary>
    /// جدول التسعير
    /// Pricing table
    /// </summary>
    public DbSet<PricingRule> PricingRules { get; set; }

    /// <summary>
    /// جدول المفضلات للمستخدمين
    /// Favorites table
    /// </summary>
    public DbSet<Favorite> Favorites { get; set; }


    /// <summary>
    /// جدول الأقسام الديناميكية للصفحة الرئيسية
    /// Dynamic home sections table
    /// </summary>

    /// <summary>
    /// جدول محتوى الأقسام الديناميكية
    /// Dynamic section content table
    /// </summary>



    /// <summary>
    /// جدول وجهات المدن
    /// City destinations table
    /// </summary>

    /// <summary>
    /// جدول إعدادات الصفحة الرئيسية الديناميكية
    /// Dynamic home config table
    /// </summary>

    /// <summary>
    /// جدول دليل الحسابات المحاسبية
    /// Chart of Accounts table
    /// </summary>
    public DbSet<ChartOfAccount> ChartOfAccounts { get; set; }

    /// <summary>
    /// جدول القيود المحاسبية
    /// Financial Transactions table
    /// </summary>
    public DbSet<FinancialTransaction> FinancialTransactions { get; set; }

    #endregion

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.HasPostgresExtension("pg_trgm");
        modelBuilder.HasPostgresExtension("btree_gist");

        // تطبيق جميع إعدادات الكيانات
        // Apply all entity configurations
        modelBuilder.ApplyConfiguration(new UserConfiguration());
        modelBuilder.ApplyConfiguration(new RoleConfiguration());
        modelBuilder.ApplyConfiguration(new UserRoleConfiguration());
        modelBuilder.ApplyConfiguration(new PropertyTypeConfiguration());
        modelBuilder.ApplyConfiguration(new PropertyConfiguration());
        modelBuilder.ApplyConfiguration(new PropertyImageConfiguration());
        modelBuilder.ApplyConfiguration(new SectionImageConfiguration());
        modelBuilder.ApplyConfiguration(new PropertyInSectionImageConfiguration());
        modelBuilder.ApplyConfiguration(new UnitInSectionImageConfiguration());
        modelBuilder.ApplyConfiguration(new UnitTypeConfiguration());
        modelBuilder.ApplyConfiguration(new UnitConfiguration());
        modelBuilder.ApplyConfiguration(new BookingConfiguration());
        modelBuilder.ApplyConfiguration(new PaymentConfiguration());
        modelBuilder.ApplyConfiguration(new PropertyServiceConfiguration());
        modelBuilder.ApplyConfiguration(new BookingServiceConfiguration());
        modelBuilder.ApplyConfiguration(new AmenityConfiguration());
        modelBuilder.ApplyConfiguration(new PropertyTypeAmenityConfiguration());
        modelBuilder.ApplyConfiguration(new PropertyAmenityConfiguration());
        modelBuilder.ApplyConfiguration(new UnitTypeFieldConfiguration());
        modelBuilder.ApplyConfiguration(new FieldGroupConfiguration());
        modelBuilder.ApplyConfiguration(new FieldGroupFieldConfiguration());
        modelBuilder.ApplyConfiguration(new SearchFilterConfiguration());
        modelBuilder.ApplyConfiguration(new UnitFieldValueConfiguration());
        modelBuilder.ApplyConfiguration(new ReviewConfiguration());
        modelBuilder.ApplyConfiguration(new PropertyPolicyConfiguration());
        modelBuilder.ApplyConfiguration(new StaffConfiguration());
        modelBuilder.ApplyConfiguration(new UserSettingsConfiguration());
        modelBuilder.ApplyConfiguration(new AdminActionConfiguration());
        modelBuilder.ApplyConfiguration(new SectionConfiguration());
        // SectionItem configuration removed
        modelBuilder.ApplyConfiguration(new PropertyInSectionConfiguration());
        modelBuilder.ApplyConfiguration(new UnitInSectionConfiguration());

        // تكوين سجل البحث
        modelBuilder.ApplyConfiguration(new SearchLogConfiguration());

        // Configurations for new entities
        modelBuilder.ApplyConfiguration(new NotificationConfiguration());
        modelBuilder.ApplyConfiguration(new NotificationChannelConfiguration());
        modelBuilder.ApplyConfiguration(new UserChannelConfiguration());
        modelBuilder.ApplyConfiguration(new NotificationChannelHistoryConfiguration());
        modelBuilder.ApplyConfiguration(new AuditLogConfiguration());
        modelBuilder.ApplyConfiguration(new ReviewImageConfiguration());
        modelBuilder.ApplyConfiguration(new ReviewResponseConfiguration());
        modelBuilder.ApplyConfiguration(new ReportConfiguration());

        // تكوين شات المحادثات والرسائل والتفاعلات والمرفقات والإعدادات
        modelBuilder.ApplyConfiguration(new ChatConversationConfiguration());
        modelBuilder.ApplyConfiguration(new ChatMessageConfiguration());
        modelBuilder.ApplyConfiguration(new MessageReactionConfiguration());
        modelBuilder.ApplyConfiguration(new ChatAttachmentConfiguration());
        modelBuilder.ApplyConfiguration(new ChatSettingsConfiguration());

        // Configurations for pricing availability and rules
        modelBuilder.ApplyConfiguration(new PricingRuleConfiguration());
        modelBuilder.ApplyConfiguration(new UnitAvailabilityConfiguration());

        // تكوين بيانات تعريف الفهارس للتحديث التدريجي
        modelBuilder.ApplyConfiguration(new IndexMetadataConfiguration());

        // Currency and City configurations
        modelBuilder.ApplyConfiguration(new CurrencyConfiguration());
        modelBuilder.ApplyConfiguration(new CityConfiguration());
        modelBuilder.ApplyConfiguration(new FavoriteConfiguration());

        // Financial Accounting configurations
        modelBuilder.ApplyConfiguration(new ChartOfAccountConfiguration());
        modelBuilder.ApplyConfiguration(new FinancialTransactionConfiguration());

        // Seed data moved to DataSeedingService (runtime seeding)
        // تم نقل البيانات الأولية إلى DataSeedingService (runtime)
        // DatabaseSeeder.Seed(modelBuilder); // COMMENTED OUT - causes duplicate data in migrations
    }
   
    /// <summary>
    /// تنفيذ الحفظ المتزامن بدون تسجيل تدقيق تلقائي
    /// Disable automatic audit logging; manual logging is handled explicitly in handlers
    /// </summary>
    public override int SaveChanges()
    {
        return base.SaveChanges();
    }

    /// <summary>
    /// تنفيذ الحفظ غير المتزامن بدون تسجيل تدقيق تلقائي
    /// Disable automatic audit logging; manual logging is handled explicitly in handlers
    /// </summary>
    public override Task<int> SaveChangesAsync(bool acceptAllChangesOnSuccess, CancellationToken cancellationToken = default)
    {
        return base.SaveChangesAsync(acceptAllChangesOnSuccess, cancellationToken);
    }
}
