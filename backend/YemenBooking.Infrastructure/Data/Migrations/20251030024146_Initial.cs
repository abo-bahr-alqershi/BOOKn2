using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace YemenBooking.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class Initial : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterDatabase()
                .Annotation("Npgsql:PostgresExtension:btree_gist", ",,")
                .Annotation("Npgsql:PostgresExtension:pg_trgm", ",,");

            migrationBuilder.CreateTable(
                name: "Amenities",
                columns: table => new
                {
                    AmenityId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Description = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Icon = table.Column<string>(type: "text", nullable: false),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Amenities", x => x.AmenityId);
                });

            migrationBuilder.CreateTable(
                name: "ChatSettings",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false, comment: "معرف المستخدم"),
                    NotificationsEnabled = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true, comment: "تنبيهات مفعلة"),
                    SoundEnabled = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true, comment: "صوت مفعّل"),
                    ShowReadReceipts = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true, comment: "عرض إيصالات القراءة"),
                    ShowTypingIndicator = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true, comment: "عرض مؤشر الكتابة"),
                    Theme = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, comment: "المظهر: light, dark, auto"),
                    FontSize = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false, comment: "حجم الخط: small, medium, large"),
                    AutoDownloadMedia = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false, comment: "التحميل التلقائي للوسائط"),
                    BackupMessages = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false, comment: "نسخ احتياطي للرسائل"),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ChatSettings", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Cities",
                columns: table => new
                {
                    Name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Country = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    ImagesJson = table.Column<string>(type: "text", nullable: false, defaultValue: "[]")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Cities", x => x.Name);
                });

            migrationBuilder.CreateTable(
                name: "Currencies",
                columns: table => new
                {
                    Code = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false),
                    ArabicCode = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false),
                    Name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    ArabicName = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    IsDefault = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    ExchangeRate = table.Column<decimal>(type: "numeric(18,6)", nullable: true),
                    LastUpdated = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Currencies", x => x.Code);
                });

            migrationBuilder.CreateTable(
                name: "IndexMetadata",
                columns: table => new
                {
                    IndexType = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false, comment: "نوع الفهرس - Index type identifier"),
                    LastUpdateTime = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "NOW()", comment: "آخر وقت تحديث للفهرس - Last index update time"),
                    TotalRecords = table.Column<int>(type: "integer", nullable: false, defaultValue: 0, comment: "عدد السجلات في الفهرس - Total records in index"),
                    LastProcessedId = table.Column<Guid>(type: "uuid", nullable: true, comment: "آخر معرف تم معالجته - Last processed entity ID"),
                    Status = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false, defaultValue: "Active", comment: "حالة الفهرس - Index status"),
                    Version = table.Column<long>(type: "bigint", nullable: false, defaultValue: 1L, comment: "رقم الإصدار للتحكم في التزامن - Version for concurrency control"),
                    FileSizeBytes = table.Column<long>(type: "bigint", nullable: false, defaultValue: 0L, comment: "حجم ملف الفهرس بالبايت - Index file size in bytes"),
                    OperationsSinceOptimization = table.Column<int>(type: "integer", nullable: false, defaultValue: 0, comment: "عدد العمليات منذ آخر تحسين - Operations since last optimization"),
                    LastOptimizationTime = table.Column<DateTime>(type: "timestamp with time zone", nullable: true, comment: "آخر وقت تحسين - Last optimization time"),
                    Metadata = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: true, comment: "معلومات إضافية بصيغة JSON - Additional metadata in JSON"),
                    LastErrorMessage = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true, comment: "رسالة الخطأ الأخيرة - Last error message"),
                    RebuildAttempts = table.Column<int>(type: "integer", nullable: false, defaultValue: 0, comment: "عدد محاولات إعادة البناء - Rebuild attempts count"),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "NOW()", comment: "تاريخ الإنشاء - Creation timestamp"),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "NOW()", comment: "تاريخ آخر تعديل - Last update timestamp")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_IndexMetadata", x => x.IndexType);
                });

            migrationBuilder.CreateTable(
                name: "PropertyTypes",
                columns: table => new
                {
                    TypeId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Description = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    DefaultAmenities = table.Column<string>(type: "text", nullable: false),
                    Icon = table.Column<string>(type: "text", nullable: false),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PropertyTypes", x => x.TypeId);
                });

            migrationBuilder.CreateTable(
                name: "Roles",
                columns: table => new
                {
                    RoleId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Roles", x => x.RoleId);
                });

            migrationBuilder.CreateTable(
                name: "SearchLogs",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    SearchType = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    CriteriaJson = table.Column<string>(type: "text", nullable: false),
                    ResultCount = table.Column<int>(type: "integer", nullable: false),
                    PageNumber = table.Column<int>(type: "integer", nullable: false),
                    PageSize = table.Column<int>(type: "integer", nullable: false),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SearchLogs", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Users",
                columns: table => new
                {
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Email = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    Password = table.Column<string>(type: "text", nullable: false),
                    Phone = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    ProfileImage = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true, comment: "رابط صورة الملف الشخصي (اختياري)"),
                    ProfileImageUrl = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    LastLoginDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true, comment: "تاريخ آخر تسجيل دخول"),
                    LastSeen = table.Column<DateTime>(type: "timestamp with time zone", nullable: true, comment: "تاريخ آخر ظهور"),
                    TotalSpent = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false, defaultValue: 0m, comment: "إجمالي المبلغ المنفق"),
                    LoyaltyTier = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true, comment: "فئة الولاء (اختياري)"),
                    EmailConfirmed = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false, comment: "حالة تأكيد البريد الإلكتروني"),
                    IsEmailVerified = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false, comment: "هل تم التحقق من البريد الإلكتروني"),
                    EmailVerifiedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true, comment: "تاريخ التحقق من البريد الإلكتروني"),
                    EmailConfirmationToken = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true, comment: "رمز تأكيد البريد الإلكتروني"),
                    EmailConfirmationTokenExpires = table.Column<DateTime>(type: "timestamp with time zone", nullable: true, comment: "انتهاء صلاحية رمز تأكيد البريد الإلكتروني"),
                    PasswordResetToken = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true, comment: "رمز إعادة تعيين كلمة المرور"),
                    PasswordResetTokenExpires = table.Column<DateTime>(type: "timestamp with time zone", nullable: true, comment: "انتهاء صلاحية رمز إعادة تعيين كلمة المرور"),
                    PhoneNumberConfirmed = table.Column<bool>(type: "boolean", nullable: false),
                    IsPhoneNumberVerified = table.Column<bool>(type: "boolean", nullable: false),
                    PhoneNumberVerifiedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    PhoneNumberConfirmationCode = table.Column<string>(type: "text", nullable: true),
                    PhoneNumberConfirmationCodeExpires = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    SettingsJson = table.Column<string>(type: "text", nullable: false, defaultValue: "{}", comment: "إعدادات المستخدم بصيغة JSON"),
                    FavoritesJson = table.Column<string>(type: "text", nullable: false, defaultValue: "[]", comment: "قائمة مفضلة المستخدم بصيغة JSON"),
                    TimeZoneId = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true, comment: "معرف المنطقة الزمنية للمستخدم (اختياري)"),
                    Country = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true, comment: "الدولة (اختياري)"),
                    City = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true, comment: "المدينة (اختياري)"),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Users", x => x.UserId);
                });

            migrationBuilder.CreateTable(
                name: "PropertyTypeAmenities",
                columns: table => new
                {
                    PtaId = table.Column<Guid>(type: "uuid", nullable: false),
                    PropertyTypeId = table.Column<Guid>(type: "uuid", nullable: false),
                    AmenityId = table.Column<Guid>(type: "uuid", nullable: false),
                    IsDefault = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PropertyTypeAmenities", x => x.PtaId);
                    table.ForeignKey(
                        name: "FK_PropertyTypeAmenities_Amenities_AmenityId",
                        column: x => x.AmenityId,
                        principalTable: "Amenities",
                        principalColumn: "AmenityId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_PropertyTypeAmenities_PropertyTypes_PropertyTypeId",
                        column: x => x.PropertyTypeId,
                        principalTable: "PropertyTypes",
                        principalColumn: "TypeId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UnitTypes",
                columns: table => new
                {
                    UnitTypeId = table.Column<Guid>(type: "uuid", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false),
                    DefaultPricingRules = table.Column<string>(type: "text", nullable: false),
                    PropertyTypeId = table.Column<Guid>(type: "uuid", nullable: false, comment: "معرف نوع الكيان"),
                    Name = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false, comment: "اسم نوع الوحدة"),
                    MaxCapacity = table.Column<int>(type: "integer", nullable: false, comment: "الحد الأقصى للسعة"),
                    Icon = table.Column<string>(type: "text", nullable: false),
                    IsHasAdults = table.Column<bool>(type: "boolean", nullable: false),
                    IsHasChildren = table.Column<bool>(type: "boolean", nullable: false),
                    IsMultiDays = table.Column<bool>(type: "boolean", nullable: false),
                    IsRequiredToDetermineTheHour = table.Column<bool>(type: "boolean", nullable: false),
                    SystemCommissionRate = table.Column<decimal>(type: "numeric(5,2)", precision: 5, scale: 2, nullable: true, comment: "نسبة عمولة النظام لبوكن لهذا النوع"),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UnitTypes", x => x.UnitTypeId);
                    table.ForeignKey(
                        name: "FK_UnitTypes_PropertyTypes_PropertyTypeId",
                        column: x => x.PropertyTypeId,
                        principalTable: "PropertyTypes",
                        principalColumn: "TypeId",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "AdminActions",
                columns: table => new
                {
                    ActionId = table.Column<Guid>(type: "uuid", nullable: false),
                    AdminId = table.Column<Guid>(type: "uuid", nullable: false, comment: "معرف المدير"),
                    TargetId = table.Column<Guid>(type: "uuid", nullable: false, comment: "معرف الهدف"),
                    TargetType = table.Column<int>(type: "integer", maxLength: 100, nullable: false, comment: "نوع الهدف"),
                    ActionType = table.Column<int>(type: "integer", maxLength: 50, nullable: false, comment: "نوع الإجراء"),
                    Timestamp = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, comment: "وقت الإجراء"),
                    Changes = table.Column<string>(type: "text", nullable: false, comment: "تغييرات الإجراء"),
                    AdminId1 = table.Column<Guid>(type: "uuid", nullable: false),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AdminActions", x => x.ActionId);
                    table.ForeignKey(
                        name: "FK_AdminActions_Users_AdminId",
                        column: x => x.AdminId,
                        principalTable: "Users",
                        principalColumn: "UserId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_AdminActions_Users_AdminId1",
                        column: x => x.AdminId1,
                        principalTable: "Users",
                        principalColumn: "UserId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AuditLogs",
                columns: table => new
                {
                    AuditLogId = table.Column<Guid>(type: "uuid", nullable: false),
                    EntityType = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    EntityId = table.Column<Guid>(type: "uuid", nullable: true),
                    Action = table.Column<int>(type: "integer", nullable: false),
                    OldValues = table.Column<string>(type: "text", nullable: true),
                    NewValues = table.Column<string>(type: "text", nullable: true),
                    PerformedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    Username = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    IpAddress = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    UserAgent = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    Notes = table.Column<string>(type: "text", nullable: true),
                    Metadata = table.Column<string>(type: "text", nullable: true),
                    IsSuccessful = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    ErrorMessage = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    DurationMs = table.Column<long>(type: "bigint", nullable: true),
                    SessionId = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    RequestId = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    Source = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AuditLogs", x => x.AuditLogId);
                    table.ForeignKey(
                        name: "FK_AuditLogs_Users_PerformedBy",
                        column: x => x.PerformedBy,
                        principalTable: "Users",
                        principalColumn: "UserId",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "NotificationChannels",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Identifier = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Description = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    Icon = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    Color = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    IsPrivate = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    IsDeletable = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    Type = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, defaultValue: "CUSTOM"),
                    AllowedRoles = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    Settings = table.Column<string>(type: "text", nullable: true),
                    SubscribersCount = table.Column<int>(type: "integer", nullable: false),
                    NotificationsSentCount = table.Column<int>(type: "integer", nullable: false),
                    LastNotificationAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_NotificationChannels", x => x.Id);
                    table.ForeignKey(
                        name: "FK_NotificationChannels_Users_CreatedBy",
                        column: x => x.CreatedBy,
                        principalTable: "Users",
                        principalColumn: "UserId",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "Notifications",
                columns: table => new
                {
                    NotificationId = table.Column<Guid>(type: "uuid", nullable: false),
                    Type = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Title = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Message = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    TitleAr = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    MessageAr = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    Priority = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    Status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    RecipientId = table.Column<Guid>(type: "uuid", nullable: false),
                    SenderId = table.Column<Guid>(type: "uuid", nullable: true),
                    Data = table.Column<string>(type: "text", nullable: true),
                    Channels = table.Column<string>(type: "text", nullable: false),
                    SentChannels = table.Column<string>(type: "text", nullable: false),
                    IsRead = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    IsDismissed = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    RequiresAction = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    CanDismiss = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    ReadAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    DismissedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ScheduledFor = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ExpiresAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    DeliveredAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    GroupId = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    BatchId = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    Icon = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    Color = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    ActionUrl = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    ActionText = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Notifications", x => x.NotificationId);
                    table.ForeignKey(
                        name: "FK_Notifications_Users_RecipientId",
                        column: x => x.RecipientId,
                        principalTable: "Users",
                        principalColumn: "UserId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Notifications_Users_SenderId",
                        column: x => x.SenderId,
                        principalTable: "Users",
                        principalColumn: "UserId",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "Properties",
                columns: table => new
                {
                    PropertyId = table.Column<Guid>(type: "uuid", nullable: false),
                    OwnerId = table.Column<Guid>(type: "uuid", nullable: false),
                    TypeId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    ShortDescription = table.Column<string>(type: "text", nullable: true),
                    Address = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    City = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Latitude = table.Column<decimal>(type: "numeric(9,6)", nullable: false),
                    Longitude = table.Column<decimal>(type: "numeric(9,6)", nullable: false),
                    StarRating = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    Description = table.Column<string>(type: "text", nullable: false),
                    IsApproved = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ViewCount = table.Column<int>(type: "integer", nullable: false),
                    BookingCount = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    AverageRating = table.Column<decimal>(type: "numeric(5,2)", nullable: false, defaultValue: 0m),
                    Currency = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false),
                    IsFeatured = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Properties", x => x.PropertyId);
                    table.ForeignKey(
                        name: "FK_Properties_Cities_City",
                        column: x => x.City,
                        principalTable: "Cities",
                        principalColumn: "Name",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Properties_Currencies_Currency",
                        column: x => x.Currency,
                        principalTable: "Currencies",
                        principalColumn: "Code",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Properties_PropertyTypes_TypeId",
                        column: x => x.TypeId,
                        principalTable: "PropertyTypes",
                        principalColumn: "TypeId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Properties_Users_OwnerId",
                        column: x => x.OwnerId,
                        principalTable: "Users",
                        principalColumn: "UserId",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "UserRoles",
                columns: table => new
                {
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    RoleId = table.Column<Guid>(type: "uuid", nullable: false),
                    AssignedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UserRoleId = table.Column<Guid>(type: "uuid", nullable: false),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserRoles", x => new { x.UserId, x.RoleId });
                    table.ForeignKey(
                        name: "FK_UserRoles_Roles_RoleId",
                        column: x => x.RoleId,
                        principalTable: "Roles",
                        principalColumn: "RoleId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UserRoles_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "UserId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UserSettings",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    PreferredLanguage = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: true),
                    PreferredCurrency = table.Column<string>(type: "character varying(3)", maxLength: 3, nullable: true),
                    TimeZone = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    DarkMode = table.Column<bool>(type: "boolean", nullable: false),
                    BookingNotifications = table.Column<bool>(type: "boolean", nullable: false),
                    PromotionalNotifications = table.Column<bool>(type: "boolean", nullable: false),
                    EmailNotifications = table.Column<bool>(type: "boolean", nullable: false),
                    SmsNotifications = table.Column<bool>(type: "boolean", nullable: false),
                    PushNotifications = table.Column<bool>(type: "boolean", nullable: false),
                    AdditionalSettings = table.Column<string>(type: "text", nullable: true),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserSettings", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserSettings_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "UserId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "FieldGroups",
                columns: table => new
                {
                    GroupId = table.Column<Guid>(type: "uuid", nullable: false),
                    UnitTypeId = table.Column<Guid>(type: "uuid", nullable: false),
                    GroupName = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    DisplayName = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Description = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    SortOrder = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    IsCollapsible = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    IsExpandedByDefault = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_FieldGroups", x => x.GroupId);
                    table.ForeignKey(
                        name: "FK_FieldGroups_UnitTypes_UnitTypeId",
                        column: x => x.UnitTypeId,
                        principalTable: "UnitTypes",
                        principalColumn: "UnitTypeId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UnitTypeFields",
                columns: table => new
                {
                    FieldId = table.Column<Guid>(type: "uuid", nullable: false),
                    UnitTypeId = table.Column<Guid>(type: "uuid", nullable: false),
                    FieldTypeId = table.Column<string>(type: "text", nullable: false),
                    FieldName = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    DisplayName = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Description = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    FieldOptions = table.Column<string>(type: "text", nullable: false),
                    ValidationRules = table.Column<string>(type: "text", nullable: false),
                    IsRequired = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    IsSearchable = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    IsPublic = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    SortOrder = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    Category = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    IsForUnits = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    ShowInCards = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    IsPrimaryFilter = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    Priority = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UnitTypeFields", x => x.FieldId);
                    table.ForeignKey(
                        name: "FK_UnitTypeFields_UnitTypes_UnitTypeId",
                        column: x => x.UnitTypeId,
                        principalTable: "UnitTypes",
                        principalColumn: "UnitTypeId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "NotificationChannelHistories",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ChannelId = table.Column<Guid>(type: "uuid", nullable: false),
                    NotificationId = table.Column<Guid>(type: "uuid", nullable: true),
                    Title = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Content = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    Type = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, defaultValue: "INFO"),
                    RecipientsCount = table.Column<int>(type: "integer", nullable: false),
                    SuccessfulDeliveries = table.Column<int>(type: "integer", nullable: false),
                    FailedDeliveries = table.Column<int>(type: "integer", nullable: false),
                    SenderId = table.Column<Guid>(type: "uuid", nullable: true),
                    SentAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "NOW()"),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_NotificationChannelHistories", x => x.Id);
                    table.ForeignKey(
                        name: "FK_NotificationChannelHistories_NotificationChannels_ChannelId",
                        column: x => x.ChannelId,
                        principalTable: "NotificationChannels",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_NotificationChannelHistories_Users_SenderId",
                        column: x => x.SenderId,
                        principalTable: "Users",
                        principalColumn: "UserId",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "UserChannels",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    ChannelId = table.Column<Guid>(type: "uuid", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    IsMuted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    SubscribedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "NOW()"),
                    UnsubscribedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    NotificationsReceivedCount = table.Column<int>(type: "integer", nullable: false),
                    LastNotificationReceivedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Notes = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UserChannels", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UserChannels_NotificationChannels_ChannelId",
                        column: x => x.ChannelId,
                        principalTable: "NotificationChannels",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UserChannels_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "UserId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ChartOfAccounts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    AccountNumber = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    NameAr = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    NameEn = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    AccountType = table.Column<int>(type: "integer", nullable: false),
                    Category = table.Column<int>(type: "integer", nullable: false),
                    ParentAccountId = table.Column<Guid>(type: "uuid", nullable: true),
                    NormalBalance = table.Column<int>(type: "integer", nullable: false),
                    Level = table.Column<int>(type: "integer", nullable: false, defaultValue: 1),
                    Description = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    Balance = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false, defaultValue: 0m),
                    Currency = table.Column<string>(type: "character varying(3)", maxLength: 3, nullable: false, defaultValue: "YER"),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    IsSystemAccount = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    CanPost = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: true),
                    PropertyId = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "NOW()"),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ChartOfAccounts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ChartOfAccounts_ChartOfAccounts_ParentAccountId",
                        column: x => x.ParentAccountId,
                        principalTable: "ChartOfAccounts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ChartOfAccounts_Properties_PropertyId",
                        column: x => x.PropertyId,
                        principalTable: "Properties",
                        principalColumn: "PropertyId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ChartOfAccounts_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "UserId",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "ChatConversations",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ConversationType = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, comment: "نوع المحادثة: direct أو group"),
                    Title = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true, comment: "عنوان المحادثة للمجموعات"),
                    Description = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true, comment: "وصف المحادثة"),
                    Avatar = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true, comment: "مسار الصورة الرمزية"),
                    IsArchived = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false, comment: "هل المحادثة مؤرشفة"),
                    IsMuted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false, comment: "هل المحادثة صامتة"),
                    PropertyId = table.Column<Guid>(type: "uuid", nullable: true, comment: "معرف الفندق المرتبط بالمحادثة"),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ChatConversations", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ChatConversations_Properties_PropertyId",
                        column: x => x.PropertyId,
                        principalTable: "Properties",
                        principalColumn: "PropertyId",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "Favorites",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false, comment: "معرف المستخدم"),
                    PropertyId = table.Column<Guid>(type: "uuid", nullable: false, comment: "معرف العقار"),
                    DateAdded = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, comment: "تاريخ الإضافة إلى المفضلة"),
                    Notes = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    Priority = table.Column<int>(type: "integer", nullable: false),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Favorites", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Favorites_Properties_PropertyId",
                        column: x => x.PropertyId,
                        principalTable: "Properties",
                        principalColumn: "PropertyId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Favorites_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "UserId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PropertyAmenities",
                columns: table => new
                {
                    PaId = table.Column<Guid>(type: "uuid", nullable: false),
                    PropertyId = table.Column<Guid>(type: "uuid", nullable: false, comment: "معرف الكيان"),
                    PtaId = table.Column<Guid>(type: "uuid", nullable: false, comment: "معرف مرفق نوع الكيان"),
                    IsAvailable = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true, comment: "هل المرفق متاح"),
                    ExtraCost_Amount = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false, comment: "مبلغ التكلفة الإضافية"),
                    ExtraCost_Currency = table.Column<string>(type: "character varying(3)", maxLength: 3, nullable: false, comment: "عملة التكلفة الإضافية"),
                    ExtraCost_ExchangeRate = table.Column<decimal>(type: "numeric", nullable: false),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PropertyAmenities", x => x.PaId);
                    table.ForeignKey(
                        name: "FK_PropertyAmenities_Properties_PropertyId",
                        column: x => x.PropertyId,
                        principalTable: "Properties",
                        principalColumn: "PropertyId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_PropertyAmenities_PropertyTypeAmenities_PtaId",
                        column: x => x.PtaId,
                        principalTable: "PropertyTypeAmenities",
                        principalColumn: "PtaId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PropertyPolicies",
                columns: table => new
                {
                    PolicyId = table.Column<Guid>(type: "uuid", nullable: false),
                    PropertyId = table.Column<Guid>(type: "uuid", nullable: false, comment: "معرف الكيان"),
                    Type = table.Column<int>(type: "integer", maxLength: 50, nullable: false, comment: "نوع السياسة"),
                    CancellationWindowDays = table.Column<int>(type: "integer", nullable: false),
                    RequireFullPaymentBeforeConfirmation = table.Column<bool>(type: "boolean", nullable: false),
                    MinimumDepositPercentage = table.Column<decimal>(type: "numeric", nullable: false),
                    MinHoursBeforeCheckIn = table.Column<int>(type: "integer", nullable: false),
                    Description = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false, comment: "وصف السياسة"),
                    Rules = table.Column<string>(type: "text", nullable: false, comment: "قواعد السياسة (JSON)"),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PropertyPolicies", x => x.PolicyId);
                    table.ForeignKey(
                        name: "FK_PropertyPolicies_Properties_PropertyId",
                        column: x => x.PropertyId,
                        principalTable: "Properties",
                        principalColumn: "PropertyId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PropertyServices",
                columns: table => new
                {
                    ServiceId = table.Column<Guid>(type: "uuid", nullable: false, comment: "معرف الخدمة الفريد"),
                    PropertyId = table.Column<Guid>(type: "uuid", nullable: false, comment: "معرف الكيان"),
                    Name = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false, comment: "اسم الخدمة"),
                    Price_Amount = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false, comment: "مبلغ سعر الخدمة"),
                    Price_Currency = table.Column<string>(type: "character varying(3)", maxLength: 3, nullable: false, comment: "عملة سعر الخدمة"),
                    Price_ExchangeRate = table.Column<decimal>(type: "numeric", nullable: false),
                    Description = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true, comment: "وصف الخدمة"),
                    Icon = table.Column<string>(type: "text", nullable: false),
                    PricingModel = table.Column<int>(type: "integer", nullable: false, comment: "نموذج التسعير"),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PropertyServices", x => x.ServiceId);
                    table.ForeignKey(
                        name: "FK_PropertyServices_Properties_PropertyId",
                        column: x => x.PropertyId,
                        principalTable: "Properties",
                        principalColumn: "PropertyId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Reports",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ReporterUserId = table.Column<Guid>(type: "uuid", nullable: false),
                    ReportedUserId = table.Column<Guid>(type: "uuid", nullable: true),
                    ReportedPropertyId = table.Column<Guid>(type: "uuid", nullable: true),
                    Reason = table.Column<string>(type: "character varying(250)", maxLength: 250, nullable: false),
                    Description = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    Status = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    ActionNote = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    AdminId = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Reports", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Reports_Properties_ReportedPropertyId",
                        column: x => x.ReportedPropertyId,
                        principalTable: "Properties",
                        principalColumn: "PropertyId",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_Reports_Users_ReportedUserId",
                        column: x => x.ReportedUserId,
                        principalTable: "Users",
                        principalColumn: "UserId",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_Reports_Users_ReporterUserId",
                        column: x => x.ReporterUserId,
                        principalTable: "Users",
                        principalColumn: "UserId",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "Staff",
                columns: table => new
                {
                    StaffId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    PropertyId = table.Column<Guid>(type: "uuid", nullable: false),
                    Position = table.Column<int>(type: "integer", maxLength: 100, nullable: false, comment: "منصب الموظف"),
                    Permissions = table.Column<string>(type: "text", nullable: false),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Staff", x => x.StaffId);
                    table.ForeignKey(
                        name: "FK_Staff_Properties_PropertyId",
                        column: x => x.PropertyId,
                        principalTable: "Properties",
                        principalColumn: "PropertyId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Staff_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "UserId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Units",
                columns: table => new
                {
                    UnitId = table.Column<Guid>(type: "uuid", nullable: false),
                    PropertyId = table.Column<Guid>(type: "uuid", nullable: false),
                    UnitTypeId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    BasePrice_Amount = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false, comment: "مبلغ السعر الأساسي"),
                    BasePrice_Currency = table.Column<string>(type: "character varying(3)", maxLength: 3, nullable: false, comment: "عملة السعر الأساسي"),
                    BasePrice_ExchangeRate = table.Column<decimal>(type: "numeric", nullable: false),
                    MaxCapacity = table.Column<int>(type: "integer", nullable: false),
                    DiscountPercentage = table.Column<decimal>(type: "numeric", nullable: false),
                    CustomFeatures = table.Column<string>(type: "text", nullable: false),
                    IsAvailable = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    ViewCount = table.Column<int>(type: "integer", nullable: false),
                    BookingCount = table.Column<int>(type: "integer", nullable: false),
                    AllowsCancellation = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true, comment: "هل تقبل الوحدة إلغاء الحجز"),
                    CancellationWindowDays = table.Column<int>(type: "integer", nullable: true, comment: "عدد أيام نافذة الإلغاء قبل الوصول"),
                    AdultsCapacity = table.Column<int>(type: "integer", nullable: true),
                    ChildrenCapacity = table.Column<int>(type: "integer", nullable: true),
                    PricingMethod = table.Column<int>(type: "integer", nullable: false, comment: "طريقة حساب السعر"),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Units", x => x.UnitId);
                    table.ForeignKey(
                        name: "FK_Units_Properties_PropertyId",
                        column: x => x.PropertyId,
                        principalTable: "Properties",
                        principalColumn: "PropertyId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Units_UnitTypes_UnitTypeId",
                        column: x => x.UnitTypeId,
                        principalTable: "UnitTypes",
                        principalColumn: "UnitTypeId",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "FieldGroupFields",
                columns: table => new
                {
                    FieldId = table.Column<Guid>(type: "uuid", nullable: false),
                    GroupId = table.Column<Guid>(type: "uuid", nullable: false),
                    SortOrder = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_FieldGroupFields", x => new { x.FieldId, x.GroupId });
                    table.ForeignKey(
                        name: "FK_FieldGroupFields_FieldGroups_GroupId",
                        column: x => x.GroupId,
                        principalTable: "FieldGroups",
                        principalColumn: "GroupId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_FieldGroupFields_UnitTypeFields_FieldId",
                        column: x => x.FieldId,
                        principalTable: "UnitTypeFields",
                        principalColumn: "FieldId",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "SearchFilters",
                columns: table => new
                {
                    FilterId = table.Column<Guid>(type: "uuid", nullable: false),
                    FieldId = table.Column<Guid>(type: "uuid", nullable: false),
                    FilterType = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    DisplayName = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    FilterOptions = table.Column<string>(type: "text", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    SortOrder = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    UnitTypeId = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SearchFilters", x => x.FilterId);
                    table.ForeignKey(
                        name: "FK_SearchFilters_UnitTypeFields_FieldId",
                        column: x => x.FieldId,
                        principalTable: "UnitTypeFields",
                        principalColumn: "FieldId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_SearchFilters_UnitTypes_UnitTypeId",
                        column: x => x.UnitTypeId,
                        principalTable: "UnitTypes",
                        principalColumn: "UnitTypeId");
                });

            migrationBuilder.CreateTable(
                name: "ChatConversationParticipant",
                columns: table => new
                {
                    ConversationId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ChatConversationParticipant", x => new { x.ConversationId, x.UserId });
                    table.ForeignKey(
                        name: "FK_ChatConversationParticipant_ChatConversations_ConversationId",
                        column: x => x.ConversationId,
                        principalTable: "ChatConversations",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ChatConversationParticipant_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "UserId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ChatMessages",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ConversationId = table.Column<Guid>(type: "uuid", nullable: false, comment: "معرف المحادثة"),
                    SenderId = table.Column<Guid>(type: "uuid", nullable: false, comment: "معرف المستخدم المرسل"),
                    ConversationId1 = table.Column<Guid>(type: "uuid", nullable: true),
                    MessageType = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, comment: "نوع الرسالة"),
                    Content = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: true, comment: "محتوى الرسالة"),
                    Location = table.Column<string>(type: "text", nullable: true, comment: "بيانات الموقع بصيغة JSON"),
                    ReplyToMessageId = table.Column<Guid>(type: "uuid", nullable: true, comment: "معرف الرسالة المرد عليها"),
                    Status = table.Column<string>(type: "text", nullable: false),
                    IsEdited = table.Column<bool>(type: "boolean", nullable: false),
                    EditedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    DeliveredAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ReadAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ChatConversationId = table.Column<Guid>(type: "uuid", nullable: false),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ChatMessages", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ChatMessages_ChatConversations_ConversationId",
                        column: x => x.ConversationId,
                        principalTable: "ChatConversations",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ChatMessages_ChatConversations_ConversationId1",
                        column: x => x.ConversationId1,
                        principalTable: "ChatConversations",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_ChatMessages_ChatMessages_ReplyToMessageId",
                        column: x => x.ReplyToMessageId,
                        principalTable: "ChatMessages",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_ChatMessages_Users_SenderId",
                        column: x => x.SenderId,
                        principalTable: "Users",
                        principalColumn: "UserId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Bookings",
                columns: table => new
                {
                    BookingId = table.Column<Guid>(type: "uuid", nullable: false, comment: "معرف الحجز الفريد"),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false, comment: "معرف المستخدم"),
                    UnitId = table.Column<Guid>(type: "uuid", nullable: false, comment: "معرف الوحدة"),
                    CheckIn = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, comment: "تاريخ الوصول"),
                    CheckOut = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, comment: "تاريخ المغادرة"),
                    GuestsCount = table.Column<int>(type: "integer", nullable: false, comment: "عدد الضيوف"),
                    TotalPrice_Amount = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false, comment: "مبلغ السعر الإجمالي"),
                    TotalPrice_Currency = table.Column<string>(type: "character varying(3)", maxLength: 3, nullable: false, comment: "عملة السعر الإجمالي"),
                    TotalPrice_ExchangeRate = table.Column<decimal>(type: "numeric", nullable: false),
                    Status = table.Column<int>(type: "integer", maxLength: 50, nullable: false, comment: "حالة الحجز"),
                    BookedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP", comment: "تاريخ الحجز"),
                    BookingSource = table.Column<string>(type: "text", nullable: true),
                    CancellationReason = table.Column<string>(type: "text", nullable: true),
                    IsWalkIn = table.Column<bool>(type: "boolean", nullable: false),
                    PlatformCommissionAmount = table.Column<decimal>(type: "numeric", nullable: false),
                    ActualCheckInDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ActualCheckOutDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    FinalAmount = table.Column<decimal>(type: "numeric", nullable: false),
                    CustomerRating = table.Column<decimal>(type: "numeric", nullable: true),
                    CompletionNotes = table.Column<string>(type: "text", nullable: true),
                    PolicySnapshot = table.Column<string>(type: "text", nullable: true, comment: "لقطة السياسات وقت إنشاء الحجز (JSON)"),
                    PolicySnapshotAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true, comment: "تاريخ حفظ لقطة السياسات"),
                    Booking_TotalPrice_Currency = table.Column<string>(type: "character varying(10)", nullable: true),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false, comment: "حالة الحذف الناعم"),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true, comment: "تاريخ الحذف")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Bookings", x => x.BookingId);
                    table.ForeignKey(
                        name: "FK_Bookings_Currencies_Booking_TotalPrice_Currency",
                        column: x => x.Booking_TotalPrice_Currency,
                        principalTable: "Currencies",
                        principalColumn: "Code",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Bookings_Units_UnitId",
                        column: x => x.UnitId,
                        principalTable: "Units",
                        principalColumn: "UnitId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Bookings_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "UserId",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "PricingRules",
                columns: table => new
                {
                    PricingRuleId = table.Column<Guid>(type: "uuid", nullable: false),
                    UnitId = table.Column<Guid>(type: "uuid", nullable: false),
                    PriceType = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    StartDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    EndDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    StartTime = table.Column<TimeSpan>(type: "time", nullable: true),
                    EndTime = table.Column<TimeSpan>(type: "time", nullable: true),
                    PriceAmount = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    PricingTier = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    PercentageChange = table.Column<decimal>(type: "numeric(5,2)", nullable: true),
                    MinPrice = table.Column<decimal>(type: "numeric(18,2)", nullable: true),
                    MaxPrice = table.Column<decimal>(type: "numeric(18,2)", nullable: true),
                    Description = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    Currency = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PricingRules", x => x.PricingRuleId);
                    table.ForeignKey(
                        name: "FK_PricingRules_Currencies_Currency",
                        column: x => x.Currency,
                        principalTable: "Currencies",
                        principalColumn: "Code",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_PricingRules_Units_UnitId",
                        column: x => x.UnitId,
                        principalTable: "Units",
                        principalColumn: "UnitId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UnitFieldValues",
                columns: table => new
                {
                    ValueId = table.Column<Guid>(type: "uuid", nullable: false),
                    UnitId = table.Column<Guid>(type: "uuid", nullable: false),
                    UnitTypeFieldId = table.Column<Guid>(type: "uuid", nullable: false),
                    FieldValue = table.Column<string>(type: "text", nullable: false),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UnitFieldValues", x => x.ValueId);
                    table.ForeignKey(
                        name: "FK_UnitFieldValues_UnitTypeFields_UnitTypeFieldId",
                        column: x => x.UnitTypeFieldId,
                        principalTable: "UnitTypeFields",
                        principalColumn: "FieldId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UnitFieldValues_Units_UnitId",
                        column: x => x.UnitId,
                        principalTable: "Units",
                        principalColumn: "UnitId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ChatAttachments",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ConversationId = table.Column<Guid>(type: "uuid", nullable: false, comment: "معرف المحادثة"),
                    FileName = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false, comment: "اسم الملف الأصلي"),
                    ContentType = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false, comment: "نوع المحتوى"),
                    FileSize = table.Column<long>(type: "bigint", nullable: false, comment: "حجم الملف بالبايت"),
                    FilePath = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false, comment: "مسار الملف على الخادم"),
                    ThumbnailUrl = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true, comment: "URL of the thumbnail image (optional)"),
                    Metadata = table.Column<string>(type: "text", nullable: true, comment: "Additional metadata as JSON string (optional)"),
                    MessageId = table.Column<Guid>(type: "uuid", nullable: true),
                    DurationSeconds = table.Column<int>(type: "integer", nullable: true, comment: "Attachment duration in seconds (audio/video)"),
                    UploadedBy = table.Column<Guid>(type: "uuid", nullable: false, comment: "المستخدم الذي رفع الملف"),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ChatAttachments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ChatAttachments_ChatConversations_ConversationId",
                        column: x => x.ConversationId,
                        principalTable: "ChatConversations",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ChatAttachments_ChatMessages_MessageId",
                        column: x => x.MessageId,
                        principalTable: "ChatMessages",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "MessageReactions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    MessageId = table.Column<Guid>(type: "uuid", nullable: false, comment: "معرف الرسالة"),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false, comment: "معرف المستخدم"),
                    ReactionType = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, comment: "نوع التفاعل"),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MessageReactions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MessageReactions_ChatMessages_MessageId",
                        column: x => x.MessageId,
                        principalTable: "ChatMessages",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "BookingServices",
                columns: table => new
                {
                    BookingId = table.Column<Guid>(type: "uuid", nullable: false, comment: "معرف الحجز"),
                    ServiceId = table.Column<Guid>(type: "uuid", nullable: false, comment: "معرف الخدمة"),
                    Quantity = table.Column<int>(type: "integer", nullable: false, comment: "الكمية"),
                    TotalPrice_Amount = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false, comment: "مبلغ السعر الإجمالي للخدمة"),
                    TotalPrice_Currency = table.Column<string>(type: "character varying(3)", maxLength: 3, nullable: false, comment: "عملة السعر الإجمالي للخدمة"),
                    TotalPrice_ExchangeRate = table.Column<decimal>(type: "numeric", nullable: false),
                    BookingServiceId = table.Column<Guid>(type: "uuid", nullable: false),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BookingServices", x => new { x.BookingId, x.ServiceId });
                    table.ForeignKey(
                        name: "FK_BookingServices_Bookings_BookingId",
                        column: x => x.BookingId,
                        principalTable: "Bookings",
                        principalColumn: "BookingId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_BookingServices_PropertyServices_ServiceId",
                        column: x => x.ServiceId,
                        principalTable: "PropertyServices",
                        principalColumn: "ServiceId",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "Payments",
                columns: table => new
                {
                    PaymentId = table.Column<Guid>(type: "uuid", nullable: false, comment: "معرف الدفع الفريد"),
                    BookingId = table.Column<Guid>(type: "uuid", nullable: false, comment: "معرف الحجز"),
                    Amount_Amount = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false, comment: "مبلغ الدفع"),
                    Amount_Currency = table.Column<string>(type: "character varying(3)", maxLength: 3, nullable: false, comment: "عملة الدفع"),
                    Amount_ExchangeRate = table.Column<decimal>(type: "numeric", nullable: false),
                    PaymentMethod = table.Column<int>(type: "integer", nullable: false, comment: "طريقة الدفع"),
                    TransactionId = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false, comment: "معرف المعاملة"),
                    Status = table.Column<int>(type: "integer", maxLength: 50, nullable: false, comment: "حالة الدفع"),
                    PaymentDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, comment: "تاريخ الدفع"),
                    GatewayTransactionId = table.Column<string>(type: "text", nullable: false),
                    ProcessedBy = table.Column<Guid>(type: "uuid", nullable: false),
                    ProcessedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Payment_Amount_Currency = table.Column<string>(type: "character varying(10)", nullable: true),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false, comment: "حالة الحذف الناعم"),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true, comment: "تاريخ الحذف")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Payments", x => x.PaymentId);
                    table.ForeignKey(
                        name: "FK_Payments_Bookings_BookingId",
                        column: x => x.BookingId,
                        principalTable: "Bookings",
                        principalColumn: "BookingId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Payments_Currencies_Payment_Amount_Currency",
                        column: x => x.Payment_Amount_Currency,
                        principalTable: "Currencies",
                        principalColumn: "Code",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "Reviews",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false, comment: "معرف التقييم الفريد"),
                    BookingId = table.Column<Guid>(type: "uuid", nullable: false, comment: "معرف الحجز"),
                    PropertyId = table.Column<Guid>(type: "uuid", nullable: false, comment: "معرف الكيان"),
                    Cleanliness = table.Column<int>(type: "integer", nullable: false, comment: "تقييم النظافة"),
                    Service = table.Column<int>(type: "integer", nullable: false, comment: "تقييم الخدمة"),
                    Location = table.Column<int>(type: "integer", nullable: false, comment: "تقييم الموقع"),
                    Value = table.Column<int>(type: "integer", nullable: false, comment: "تقييم القيمة"),
                    AverageRating = table.Column<decimal>(type: "numeric(5,2)", nullable: false, defaultValue: 0m, comment: "متوسط التقييم"),
                    Comment = table.Column<string>(type: "text", nullable: false, comment: "تعليق التقييم"),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, comment: "تاريخ إنشاء التقييم"),
                    ResponseText = table.Column<string>(type: "text", nullable: true, comment: "نص رد التقييم"),
                    ResponseDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsPendingApproval = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false, comment: "حالة الحذف الناعم"),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true, comment: "تاريخ الحذف")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Reviews", x => x.Id);
                    table.CheckConstraint("CK_Reviews_Cleanliness", "\"Cleanliness\" >= 1 AND \"Cleanliness\" <= 5");
                    table.CheckConstraint("CK_Reviews_Location", "\"Location\" >= 1 AND \"Location\" <= 5");
                    table.CheckConstraint("CK_Reviews_Service", "\"Service\" >= 1 AND \"Service\" <= 5");
                    table.CheckConstraint("CK_Reviews_Value", "\"Value\" >= 1 AND \"Value\" <= 5");
                    table.ForeignKey(
                        name: "FK_Reviews_Bookings_BookingId",
                        column: x => x.BookingId,
                        principalTable: "Bookings",
                        principalColumn: "BookingId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Reviews_Properties_PropertyId",
                        column: x => x.PropertyId,
                        principalTable: "Properties",
                        principalColumn: "PropertyId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "UnitAvailability",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UnitId = table.Column<Guid>(type: "uuid", nullable: false),
                    StartDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    EndDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    Reason = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    Notes = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    BookingId = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UnitAvailability", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UnitAvailability_Bookings_BookingId",
                        column: x => x.BookingId,
                        principalTable: "Bookings",
                        principalColumn: "BookingId",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_UnitAvailability_Units_UnitId",
                        column: x => x.UnitId,
                        principalTable: "Units",
                        principalColumn: "UnitId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "FinancialTransactions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TransactionNumber = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    TransactionDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    EntryType = table.Column<int>(type: "integer", nullable: false),
                    TransactionType = table.Column<int>(type: "integer", nullable: false),
                    DebitAccountId = table.Column<Guid>(type: "uuid", nullable: false),
                    CreditAccountId = table.Column<Guid>(type: "uuid", nullable: false),
                    Amount = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    Currency = table.Column<string>(type: "character varying(3)", maxLength: 3, nullable: false, defaultValue: "YER"),
                    ExchangeRate = table.Column<decimal>(type: "numeric(18,4)", precision: 18, scale: 4, nullable: false, defaultValue: 1m),
                    BaseAmount = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    Description = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    Narration = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    ReferenceNumber = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    DocumentType = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    BookingId = table.Column<Guid>(type: "uuid", nullable: true),
                    PaymentId = table.Column<Guid>(type: "uuid", nullable: true),
                    FirstPartyUserId = table.Column<Guid>(type: "uuid", nullable: true),
                    SecondPartyUserId = table.Column<Guid>(type: "uuid", nullable: true),
                    PropertyId = table.Column<Guid>(type: "uuid", nullable: true),
                    UnitId = table.Column<Guid>(type: "uuid", nullable: true),
                    Status = table.Column<int>(type: "integer", nullable: false, defaultValue: 1),
                    PostingDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsPosted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    IsReversed = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    ReverseTransactionId = table.Column<Guid>(type: "uuid", nullable: true),
                    FiscalYear = table.Column<int>(type: "integer", nullable: false),
                    FiscalPeriod = table.Column<int>(type: "integer", nullable: false),
                    JournalId = table.Column<Guid>(type: "uuid", nullable: true),
                    BatchNumber = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    AttachmentsJson = table.Column<string>(type: "text", nullable: true),
                    Notes = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    Commission = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: true),
                    CommissionPercentage = table.Column<decimal>(type: "numeric(5,2)", precision: 5, scale: 2, nullable: true),
                    Tax = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: true),
                    TaxPercentage = table.Column<decimal>(type: "numeric(5,2)", precision: 5, scale: 2, nullable: true),
                    Discount = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: true),
                    DiscountPercentage = table.Column<decimal>(type: "numeric(5,2)", precision: 5, scale: 2, nullable: true),
                    NetAmount = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "NOW()"),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    ApprovedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ApprovedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CancellationReason = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    CancelledAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CancelledBy = table.Column<Guid>(type: "uuid", nullable: true),
                    IsAutomatic = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    AutomaticSource = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    Tags = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_FinancialTransactions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_FinancialTransactions_Bookings_BookingId",
                        column: x => x.BookingId,
                        principalTable: "Bookings",
                        principalColumn: "BookingId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_FinancialTransactions_ChartOfAccounts_CreditAccountId",
                        column: x => x.CreditAccountId,
                        principalTable: "ChartOfAccounts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_FinancialTransactions_ChartOfAccounts_DebitAccountId",
                        column: x => x.DebitAccountId,
                        principalTable: "ChartOfAccounts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_FinancialTransactions_FinancialTransactions_ReverseTransact~",
                        column: x => x.ReverseTransactionId,
                        principalTable: "FinancialTransactions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_FinancialTransactions_Payments_PaymentId",
                        column: x => x.PaymentId,
                        principalTable: "Payments",
                        principalColumn: "PaymentId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_FinancialTransactions_Properties_PropertyId",
                        column: x => x.PropertyId,
                        principalTable: "Properties",
                        principalColumn: "PropertyId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_FinancialTransactions_Units_UnitId",
                        column: x => x.UnitId,
                        principalTable: "Units",
                        principalColumn: "UnitId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_FinancialTransactions_Users_ApprovedBy",
                        column: x => x.ApprovedBy,
                        principalTable: "Users",
                        principalColumn: "UserId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_FinancialTransactions_Users_CancelledBy",
                        column: x => x.CancelledBy,
                        principalTable: "Users",
                        principalColumn: "UserId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_FinancialTransactions_Users_CreatedBy",
                        column: x => x.CreatedBy,
                        principalTable: "Users",
                        principalColumn: "UserId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_FinancialTransactions_Users_FirstPartyUserId",
                        column: x => x.FirstPartyUserId,
                        principalTable: "Users",
                        principalColumn: "UserId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_FinancialTransactions_Users_SecondPartyUserId",
                        column: x => x.SecondPartyUserId,
                        principalTable: "Users",
                        principalColumn: "UserId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_FinancialTransactions_Users_UpdatedBy",
                        column: x => x.UpdatedBy,
                        principalTable: "Users",
                        principalColumn: "UserId",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "ReviewImages",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false, comment: "معرف الصورة الفريدة"),
                    ReviewId = table.Column<Guid>(type: "uuid", nullable: false, comment: "معرف التقييم المرتبط"),
                    Name = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false, comment: "اسم الملف"),
                    Url = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false, comment: "مسار الصورة"),
                    SizeBytes = table.Column<long>(type: "bigint", nullable: false, comment: "حجم الملف بالبايت"),
                    Type = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false, comment: "نوع المحتوى"),
                    Category = table.Column<int>(type: "integer", nullable: false, comment: "فئة الصورة"),
                    Caption = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false, comment: "تعليق توضيحي للصورة"),
                    AltText = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false, comment: "نص بديل للصورة"),
                    Tags = table.Column<string>(type: "text", nullable: false, comment: "وسوم الصورة"),
                    IsMain = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false, comment: "هل هي الصورة الرئيسية"),
                    DisplayOrder = table.Column<int>(type: "integer", nullable: false, defaultValue: 0, comment: "ترتيب العرض"),
                    UploadedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, comment: "تاريخ الرفع"),
                    Status = table.Column<int>(type: "integer", nullable: false, comment: "حالة الموافقة للصورة"),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false, comment: "حالة الحذف الناعم"),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true, comment: "تاريخ الحذف")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ReviewImages", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ReviewImages_Reviews_ReviewId",
                        column: x => x.ReviewId,
                        principalTable: "Reviews",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ReviewResponses",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ReviewId = table.Column<Guid>(type: "uuid", nullable: false),
                    Text = table.Column<string>(type: "text", nullable: false, comment: "نص الرد على التقييم"),
                    RespondedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, comment: "تاريخ إنشاء الرد"),
                    RespondedBy = table.Column<Guid>(type: "uuid", nullable: false, comment: "المستخدم الذي قام بالرد"),
                    RespondedByName = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false, comment: "اسم المجيب (منسوخ)"),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ReviewResponses", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ReviewResponses_Reviews_ReviewId",
                        column: x => x.ReviewId,
                        principalTable: "Reviews",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PropertyImages",
                columns: table => new
                {
                    ImageId = table.Column<Guid>(type: "uuid", nullable: false, comment: "معرف الصورة الفريد"),
                    TempKey = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true, comment: "مفتاح مؤقت لرفع الصور قبل الربط"),
                    PropertyId = table.Column<Guid>(type: "uuid", nullable: true, comment: "معرف الكيان"),
                    UnitId = table.Column<Guid>(type: "uuid", nullable: true),
                    SectionId = table.Column<Guid>(type: "uuid", nullable: true),
                    PropertyInSectionId = table.Column<Guid>(type: "uuid", nullable: true),
                    UnitInSectionId = table.Column<Guid>(type: "uuid", nullable: true),
                    CityName = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true, comment: "اسم المدينة المرتبطة بالصورة"),
                    Name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Url = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false, comment: "مسار الصورة"),
                    SizeBytes = table.Column<long>(type: "bigint", nullable: false),
                    Type = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Category = table.Column<int>(type: "integer", nullable: false),
                    Caption = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    AltText = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false, comment: "وصف الصورة"),
                    Tags = table.Column<string>(type: "text", nullable: false),
                    Sizes = table.Column<string>(type: "text", nullable: false),
                    IsMain = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false, comment: "هل هي الصورة الرئيسية"),
                    SortOrder = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    Views = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    Downloads = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    UploadedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    DisplayOrder = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    IsMainImage = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    MediaType = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, defaultValue: "image", comment: "نوع الوسائط image/video"),
                    DurationSeconds = table.Column<int>(type: "integer", nullable: true, comment: "مدة الفيديو بالثواني"),
                    VideoThumbnailUrl = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true, comment: "رابط المصغرة للفيديو"),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false, comment: "حالة الحذف الناعم"),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true, comment: "تاريخ الحذف")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PropertyImages", x => x.ImageId);
                    table.ForeignKey(
                        name: "FK_PropertyImages_Cities_CityName",
                        column: x => x.CityName,
                        principalTable: "Cities",
                        principalColumn: "Name",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_PropertyImages_Properties_PropertyId",
                        column: x => x.PropertyId,
                        principalTable: "Properties",
                        principalColumn: "PropertyId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_PropertyImages_Units_UnitId",
                        column: x => x.UnitId,
                        principalTable: "Units",
                        principalColumn: "UnitId",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "PropertyInSectionImages",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TempKey = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    PropertyInSectionId = table.Column<Guid>(type: "uuid", nullable: true),
                    Name = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Url = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    SizeBytes = table.Column<long>(type: "bigint", nullable: false),
                    Type = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Category = table.Column<int>(type: "integer", nullable: false),
                    Caption = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    AltText = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    Sizes = table.Column<string>(type: "text", nullable: true),
                    IsMainImage = table.Column<bool>(type: "boolean", nullable: false),
                    DisplayOrder = table.Column<int>(type: "integer", nullable: false),
                    UploadedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    MediaType = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, defaultValue: "image"),
                    DurationSeconds = table.Column<int>(type: "integer", nullable: true),
                    VideoThumbnailUrl = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    Tags = table.Column<string>(type: "text", nullable: false),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PropertyInSectionImages", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "PropertyInSections",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    SectionId = table.Column<Guid>(type: "uuid", nullable: false),
                    PropertyId = table.Column<Guid>(type: "uuid", nullable: false),
                    PropertyName = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Address = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    City = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Latitude = table.Column<decimal>(type: "numeric", nullable: false),
                    Longitude = table.Column<decimal>(type: "numeric", nullable: false),
                    PropertyType = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    StarRating = table.Column<int>(type: "integer", nullable: false),
                    AverageRating = table.Column<decimal>(type: "numeric(5,2)", nullable: false),
                    ReviewsCount = table.Column<int>(type: "integer", nullable: false),
                    BasePrice = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    Currency = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false),
                    MainImage = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    ShortDescription = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    DisplayOrder = table.Column<int>(type: "integer", nullable: false),
                    IsFeatured = table.Column<bool>(type: "boolean", nullable: false),
                    DiscountPercentage = table.Column<decimal>(type: "numeric", nullable: true),
                    PromotionalText = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: true),
                    Badge = table.Column<int>(type: "integer", nullable: true),
                    BadgeColor = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    DisplayFrom = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    DisplayUntil = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Priority = table.Column<int>(type: "integer", nullable: false),
                    ViewsFromSection = table.Column<int>(type: "integer", nullable: false),
                    ClickCount = table.Column<int>(type: "integer", nullable: false),
                    ConversionRate = table.Column<decimal>(type: "numeric(5,2)", nullable: true),
                    Metadata = table.Column<string>(type: "text", nullable: true),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PropertyInSections", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PropertyInSections_Properties_PropertyId",
                        column: x => x.PropertyId,
                        principalTable: "Properties",
                        principalColumn: "PropertyId",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "SectionImages",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TempKey = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    SectionId = table.Column<Guid>(type: "uuid", nullable: true),
                    Name = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Url = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    SizeBytes = table.Column<long>(type: "bigint", nullable: false),
                    Type = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Category = table.Column<int>(type: "integer", nullable: false),
                    Caption = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    AltText = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    Sizes = table.Column<string>(type: "text", nullable: true),
                    IsMainImage = table.Column<bool>(type: "boolean", nullable: false),
                    DisplayOrder = table.Column<int>(type: "integer", nullable: false),
                    UploadedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    MediaType = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, defaultValue: "image"),
                    DurationSeconds = table.Column<int>(type: "integer", nullable: true),
                    VideoThumbnailUrl = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    Tags = table.Column<string>(type: "text", nullable: false),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SectionImages", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Sections",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: true),
                    Title = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    Subtitle = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: true),
                    Description = table.Column<string>(type: "text", nullable: true),
                    ShortDescription = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    Type = table.Column<int>(type: "integer", nullable: false),
                    ContentType = table.Column<int>(type: "integer", nullable: false),
                    DisplayStyle = table.Column<int>(type: "integer", nullable: false),
                    ColumnsCount = table.Column<int>(type: "integer", nullable: false),
                    ItemsToShow = table.Column<int>(type: "integer", nullable: false),
                    DisplayOrder = table.Column<int>(type: "integer", nullable: false),
                    Target = table.Column<int>(type: "integer", nullable: false),
                    Icon = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    ColorTheme = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    BackgroundImage = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    BackgroundImageId = table.Column<Guid>(type: "uuid", nullable: true),
                    FilterCriteria = table.Column<string>(type: "text", nullable: true),
                    SortCriteria = table.Column<string>(type: "text", nullable: true),
                    CityName = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    PropertyTypeId = table.Column<Guid>(type: "uuid", nullable: true),
                    UnitTypeId = table.Column<Guid>(type: "uuid", nullable: true),
                    MinPrice = table.Column<decimal>(type: "numeric(18,2)", nullable: true),
                    MaxPrice = table.Column<decimal>(type: "numeric(18,2)", nullable: true),
                    MinRating = table.Column<decimal>(type: "numeric(5,2)", nullable: true),
                    IsVisibleToGuests = table.Column<bool>(type: "boolean", nullable: false),
                    IsVisibleToRegistered = table.Column<bool>(type: "boolean", nullable: false),
                    RequiresPermission = table.Column<string>(type: "text", nullable: true),
                    StartDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    EndDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Metadata = table.Column<string>(type: "text", nullable: true),
                    CategoryClass = table.Column<int>(type: "integer", nullable: true),
                    HomeItemsCount = table.Column<int>(type: "integer", nullable: true),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Sections", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Sections_Cities_CityName",
                        column: x => x.CityName,
                        principalTable: "Cities",
                        principalColumn: "Name",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_Sections_SectionImages_BackgroundImageId",
                        column: x => x.BackgroundImageId,
                        principalTable: "SectionImages",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "UnitInSections",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    SectionId = table.Column<Guid>(type: "uuid", nullable: false),
                    UnitId = table.Column<Guid>(type: "uuid", nullable: false),
                    PropertyId = table.Column<Guid>(type: "uuid", nullable: false),
                    UnitName = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    PropertyName = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    UnitTypeId = table.Column<Guid>(type: "uuid", nullable: false),
                    UnitTypeName = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    UnitTypeIcon = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    MaxCapacity = table.Column<int>(type: "integer", nullable: false),
                    BasePrice = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    Currency = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false),
                    PricingMethod = table.Column<int>(type: "integer", nullable: false),
                    AdultsCapacity = table.Column<int>(type: "integer", nullable: true),
                    ChildrenCapacity = table.Column<int>(type: "integer", nullable: true),
                    MainImage = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    PrimaryFieldValues = table.Column<string>(type: "text", nullable: true),
                    PropertyAddress = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    PropertyCity = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Latitude = table.Column<decimal>(type: "numeric", nullable: false),
                    Longitude = table.Column<decimal>(type: "numeric", nullable: false),
                    PropertyStarRating = table.Column<int>(type: "integer", nullable: false),
                    PropertyAverageRating = table.Column<decimal>(type: "numeric(5,2)", nullable: false),
                    MainAmenities = table.Column<string>(type: "text", nullable: true),
                    CustomFeatures = table.Column<string>(type: "text", nullable: true),
                    DisplayOrder = table.Column<int>(type: "integer", nullable: false),
                    IsFeatured = table.Column<bool>(type: "boolean", nullable: false),
                    DiscountPercentage = table.Column<decimal>(type: "numeric", nullable: true),
                    DiscountedPrice = table.Column<decimal>(type: "numeric(18,2)", nullable: true),
                    PromotionalText = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: true),
                    Badge = table.Column<int>(type: "integer", nullable: true),
                    BadgeColor = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    IsAvailable = table.Column<bool>(type: "boolean", nullable: false),
                    NextAvailableDates = table.Column<string>(type: "text", nullable: true),
                    AvailabilityMessage = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: true),
                    DisplayFrom = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    DisplayUntil = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Priority = table.Column<int>(type: "integer", nullable: false),
                    AllowsCancellation = table.Column<bool>(type: "boolean", nullable: false),
                    CancellationWindowDays = table.Column<int>(type: "integer", nullable: true),
                    MinStayDays = table.Column<int>(type: "integer", nullable: true),
                    MaxStayDays = table.Column<int>(type: "integer", nullable: true),
                    ViewsFromSection = table.Column<int>(type: "integer", nullable: false),
                    ClickCount = table.Column<int>(type: "integer", nullable: false),
                    ConversionRate = table.Column<decimal>(type: "numeric(5,2)", nullable: true),
                    RecentBookingsCount = table.Column<int>(type: "integer", nullable: false),
                    Metadata = table.Column<string>(type: "text", nullable: true),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UnitInSections", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UnitInSections_Properties_PropertyId",
                        column: x => x.PropertyId,
                        principalTable: "Properties",
                        principalColumn: "PropertyId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UnitInSections_Sections_SectionId",
                        column: x => x.SectionId,
                        principalTable: "Sections",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_UnitInSections_Units_UnitId",
                        column: x => x.UnitId,
                        principalTable: "Units",
                        principalColumn: "UnitId",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "UnitInSectionImages",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TempKey = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    UnitInSectionId = table.Column<Guid>(type: "uuid", nullable: true),
                    Name = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Url = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    SizeBytes = table.Column<long>(type: "bigint", nullable: false),
                    Type = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Category = table.Column<int>(type: "integer", nullable: false),
                    Caption = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    AltText = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    Sizes = table.Column<string>(type: "text", nullable: true),
                    IsMainImage = table.Column<bool>(type: "boolean", nullable: false),
                    DisplayOrder = table.Column<int>(type: "integer", nullable: false),
                    UploadedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    MediaType = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, defaultValue: "image"),
                    DurationSeconds = table.Column<int>(type: "integer", nullable: true),
                    VideoThumbnailUrl = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    Tags = table.Column<string>(type: "text", nullable: false),
                    CreatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    DeletedBy = table.Column<Guid>(type: "uuid", nullable: true),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_UnitInSectionImages", x => x.Id);
                    table.ForeignKey(
                        name: "FK_UnitInSectionImages_UnitInSections_UnitInSectionId",
                        column: x => x.UnitInSectionId,
                        principalTable: "UnitInSections",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateIndex(
                name: "IX_AdminActions_ActionType",
                table: "AdminActions",
                column: "ActionType");

            migrationBuilder.CreateIndex(
                name: "IX_AdminActions_AdminId",
                table: "AdminActions",
                column: "AdminId");

            migrationBuilder.CreateIndex(
                name: "IX_AdminActions_AdminId_Timestamp",
                table: "AdminActions",
                columns: new[] { "AdminId", "Timestamp" });

            migrationBuilder.CreateIndex(
                name: "IX_AdminActions_AdminId1",
                table: "AdminActions",
                column: "AdminId1");

            migrationBuilder.CreateIndex(
                name: "IX_AdminActions_TargetId_TargetType",
                table: "AdminActions",
                columns: new[] { "TargetId", "TargetType" });

            migrationBuilder.CreateIndex(
                name: "IX_AdminActions_TargetType",
                table: "AdminActions",
                column: "TargetType");

            migrationBuilder.CreateIndex(
                name: "IX_Amenities_Name",
                table: "Amenities",
                column: "Name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_AuditLogs_Action",
                table: "AuditLogs",
                column: "Action");

            migrationBuilder.CreateIndex(
                name: "IX_AuditLogs_CreatedAt",
                table: "AuditLogs",
                column: "CreatedAt");

            migrationBuilder.CreateIndex(
                name: "IX_AuditLogs_EntityType_CreatedAt",
                table: "AuditLogs",
                columns: new[] { "EntityType", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_AuditLogs_EntityType_EntityId",
                table: "AuditLogs",
                columns: new[] { "EntityType", "EntityId" });

            migrationBuilder.CreateIndex(
                name: "IX_AuditLogs_PerformedBy",
                table: "AuditLogs",
                column: "PerformedBy");

            migrationBuilder.CreateIndex(
                name: "IX_Bookings_BookedAt",
                table: "Bookings",
                column: "BookedAt");

            migrationBuilder.CreateIndex(
                name: "IX_Bookings_Booking_TotalPrice_Currency",
                table: "Bookings",
                column: "Booking_TotalPrice_Currency");

            migrationBuilder.CreateIndex(
                name: "IX_Bookings_CheckInOut",
                table: "Bookings",
                columns: new[] { "CheckIn", "CheckOut" });

            migrationBuilder.CreateIndex(
                name: "IX_Bookings_IsDeleted",
                table: "Bookings",
                column: "IsDeleted");

            migrationBuilder.CreateIndex(
                name: "IX_Bookings_Status",
                table: "Bookings",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_Bookings_Unit_CheckIn_CheckOut_gist",
                table: "Bookings",
                columns: new[] { "UnitId", "CheckIn", "CheckOut" })
                .Annotation("Npgsql:IndexMethod", "gist");

            migrationBuilder.CreateIndex(
                name: "IX_Bookings_Unit_Confirmed",
                table: "Bookings",
                column: "UnitId",
                filter: "\"Status\" = 0");

            migrationBuilder.CreateIndex(
                name: "IX_Bookings_UserId",
                table: "Bookings",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Bookings_UserId_BookedAt",
                table: "Bookings",
                columns: new[] { "UserId", "BookedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_BookingServices_BookingId",
                table: "BookingServices",
                column: "BookingId");

            migrationBuilder.CreateIndex(
                name: "IX_BookingServices_IsDeleted",
                table: "BookingServices",
                column: "IsDeleted");

            migrationBuilder.CreateIndex(
                name: "IX_BookingServices_ServiceId",
                table: "BookingServices",
                column: "ServiceId");

            migrationBuilder.CreateIndex(
                name: "IX_ChartOfAccounts_AccountNumber",
                table: "ChartOfAccounts",
                column: "AccountNumber",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ChartOfAccounts_AccountType",
                table: "ChartOfAccounts",
                column: "AccountType");

            migrationBuilder.CreateIndex(
                name: "IX_ChartOfAccounts_AccountType_IsActive",
                table: "ChartOfAccounts",
                columns: new[] { "AccountType", "IsActive" });

            migrationBuilder.CreateIndex(
                name: "IX_ChartOfAccounts_BalanceCalculation",
                table: "ChartOfAccounts",
                columns: new[] { "Id", "AccountType", "IsActive" },
                filter: "\"IsActive\" = true")
                .Annotation("Npgsql:IndexInclude", new[] { "AccountNumber", "NameAr", "Balance", "NormalBalance" });

            migrationBuilder.CreateIndex(
                name: "IX_ChartOfAccounts_Category",
                table: "ChartOfAccounts",
                column: "Category");

            migrationBuilder.CreateIndex(
                name: "IX_ChartOfAccounts_IsActive",
                table: "ChartOfAccounts",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_ChartOfAccounts_MainAccounts",
                table: "ChartOfAccounts",
                columns: new[] { "Level", "IsActive" },
                filter: "\"ParentAccountId\" IS NULL AND \"IsActive\" = true")
                .Annotation("Npgsql:IndexInclude", new[] { "AccountNumber", "NameAr", "NameEn", "AccountType", "Balance" });

            migrationBuilder.CreateIndex(
                name: "IX_ChartOfAccounts_NameAr",
                table: "ChartOfAccounts",
                column: "NameAr",
                filter: "\"IsActive\" = true")
                .Annotation("Npgsql:IndexInclude", new[] { "AccountNumber", "AccountType", "IsActive" });

            migrationBuilder.CreateIndex(
                name: "IX_ChartOfAccounts_NameEn",
                table: "ChartOfAccounts",
                column: "NameEn",
                filter: "\"IsActive\" = true")
                .Annotation("Npgsql:IndexInclude", new[] { "AccountNumber", "AccountType", "IsActive" });

            migrationBuilder.CreateIndex(
                name: "IX_ChartOfAccounts_ParentAccountId",
                table: "ChartOfAccounts",
                column: "ParentAccountId");

            migrationBuilder.CreateIndex(
                name: "IX_ChartOfAccounts_PostableAccounts",
                table: "ChartOfAccounts",
                columns: new[] { "CanPost", "IsActive" },
                filter: "\"CanPost\" = true AND \"IsActive\" = true")
                .Annotation("Npgsql:IndexInclude", new[] { "AccountNumber", "NameAr", "AccountType", "Balance", "ParentAccountId" });

            migrationBuilder.CreateIndex(
                name: "IX_ChartOfAccounts_PropertyId",
                table: "ChartOfAccounts",
                column: "PropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_ChartOfAccounts_Search",
                table: "ChartOfAccounts",
                columns: new[] { "AccountNumber", "NameAr", "NameEn" });

            migrationBuilder.CreateIndex(
                name: "IX_ChartOfAccounts_SubAccounts",
                table: "ChartOfAccounts",
                columns: new[] { "ParentAccountId", "IsActive", "Level" },
                filter: "\"ParentAccountId\" IS NOT NULL AND \"IsActive\" = true")
                .Annotation("Npgsql:IndexInclude", new[] { "AccountNumber", "NameAr", "NameEn", "AccountType", "Balance", "CanPost" });

            migrationBuilder.CreateIndex(
                name: "IX_ChartOfAccounts_SystemAccounts",
                table: "ChartOfAccounts",
                columns: new[] { "IsSystemAccount", "IsActive" },
                filter: "\"IsSystemAccount\" = true AND \"IsActive\" = true")
                .Annotation("Npgsql:IndexInclude", new[] { "AccountNumber", "NameAr", "AccountType" });

            migrationBuilder.CreateIndex(
                name: "IX_ChartOfAccounts_TreeQuery",
                table: "ChartOfAccounts",
                columns: new[] { "IsActive", "ParentAccountId" },
                filter: "\"IsActive\" = true")
                .Annotation("Npgsql:IndexInclude", new[] { "AccountNumber", "NameAr", "NameEn", "AccountType", "Category", "Balance", "Level", "CanPost" });

            migrationBuilder.CreateIndex(
                name: "IX_ChartOfAccounts_TypeFilter",
                table: "ChartOfAccounts",
                columns: new[] { "AccountType", "IsActive", "CanPost" },
                filter: "\"IsActive\" = true")
                .Annotation("Npgsql:IndexInclude", new[] { "AccountNumber", "NameAr", "NameEn", "Balance", "ParentAccountId", "Level" });

            migrationBuilder.CreateIndex(
                name: "IX_ChartOfAccounts_UserId",
                table: "ChartOfAccounts",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_ChatAttachments_ConversationId",
                table: "ChatAttachments",
                column: "ConversationId");

            migrationBuilder.CreateIndex(
                name: "IX_ChatAttachments_MessageId",
                table: "ChatAttachments",
                column: "MessageId");

            migrationBuilder.CreateIndex(
                name: "IX_ChatConversationParticipant_UserId",
                table: "ChatConversationParticipant",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_ChatConversations_PropertyId",
                table: "ChatConversations",
                column: "PropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_ChatMessages_ConversationId",
                table: "ChatMessages",
                column: "ConversationId");

            migrationBuilder.CreateIndex(
                name: "IX_ChatMessages_ConversationId1",
                table: "ChatMessages",
                column: "ConversationId1");

            migrationBuilder.CreateIndex(
                name: "IX_ChatMessages_ReplyToMessageId",
                table: "ChatMessages",
                column: "ReplyToMessageId");

            migrationBuilder.CreateIndex(
                name: "IX_ChatMessages_SenderId",
                table: "ChatMessages",
                column: "SenderId");

            migrationBuilder.CreateIndex(
                name: "IX_ChatSettings_UserId",
                table: "ChatSettings",
                column: "UserId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Cities_Name_Country",
                table: "Cities",
                columns: new[] { "Name", "Country" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Currencies_IsDefault",
                table: "Currencies",
                column: "IsDefault");

            migrationBuilder.CreateIndex(
                name: "IX_Favorites_PropertyId",
                table: "Favorites",
                column: "PropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_Favorites_User_Property",
                table: "Favorites",
                columns: new[] { "UserId", "PropertyId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Favorites_UserId",
                table: "Favorites",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_FieldGroupFields_FieldId",
                table: "FieldGroupFields",
                column: "FieldId");

            migrationBuilder.CreateIndex(
                name: "IX_FieldGroupFields_GroupId",
                table: "FieldGroupFields",
                column: "GroupId");

            migrationBuilder.CreateIndex(
                name: "IX_FieldGroups_PropertyTypeId_SortOrder",
                table: "FieldGroups",
                columns: new[] { "UnitTypeId", "SortOrder" });

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_ApprovedBy",
                table: "FinancialTransactions",
                column: "ApprovedBy");

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_BalanceQuery",
                table: "FinancialTransactions",
                columns: new[] { "TransactionDate", "DebitAccountId", "CreditAccountId" },
                filter: "\"Status\" = 3 AND \"IsPosted\" = true")
                .Annotation("Npgsql:IndexInclude", new[] { "Amount", "Currency", "BaseAmount" });

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_BatchNumber",
                table: "FinancialTransactions",
                column: "BatchNumber");

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_Booking_Date",
                table: "FinancialTransactions",
                columns: new[] { "BookingId", "TransactionDate" });

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_BookingId",
                table: "FinancialTransactions",
                column: "BookingId");

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_CancelledBy",
                table: "FinancialTransactions",
                column: "CancelledBy");

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_CoveringIndex",
                table: "FinancialTransactions",
                column: "TransactionDate",
                filter: "\"Status\" = 3 AND \"IsPosted\" = true")
                .Annotation("Npgsql:IndexInclude", new[] { "Amount", "DebitAccountId", "CreditAccountId", "TransactionType", "Currency" });

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_CreatedBy",
                table: "FinancialTransactions",
                column: "CreatedBy");

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_Credit_Date",
                table: "FinancialTransactions",
                columns: new[] { "CreditAccountId", "TransactionDate" },
                filter: "\"Status\" = 3 AND \"IsPosted\" = true")
                .Annotation("Npgsql:IndexInclude", new[] { "Amount", "Description", "TransactionNumber", "ReferenceNumber", "DebitAccountId" });

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_CreditAccountId",
                table: "FinancialTransactions",
                column: "CreditAccountId");

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_Debit_Date",
                table: "FinancialTransactions",
                columns: new[] { "DebitAccountId", "TransactionDate" },
                filter: "\"Status\" = 3 AND \"IsPosted\" = true")
                .Annotation("Npgsql:IndexInclude", new[] { "Amount", "Description", "TransactionNumber", "ReferenceNumber", "CreditAccountId" });

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_DebitAccountId",
                table: "FinancialTransactions",
                column: "DebitAccountId");

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_EntryType",
                table: "FinancialTransactions",
                column: "EntryType");

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_FirstPartyUserId",
                table: "FinancialTransactions",
                column: "FirstPartyUserId");

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_FirstUser_Date",
                table: "FinancialTransactions",
                columns: new[] { "FirstPartyUserId", "TransactionDate" });

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_FiscalYear",
                table: "FinancialTransactions",
                column: "FiscalYear");

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_FiscalYear_Period",
                table: "FinancialTransactions",
                columns: new[] { "FiscalYear", "FiscalPeriod" });

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_IsPosted",
                table: "FinancialTransactions",
                column: "IsPosted");

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_IsReversed",
                table: "FinancialTransactions",
                column: "IsReversed");

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_MonthlyReporting",
                table: "FinancialTransactions",
                columns: new[] { "FiscalYear", "FiscalPeriod", "TransactionType" },
                filter: "\"Status\" = 3 AND \"IsPosted\" = true")
                .Annotation("Npgsql:IndexInclude", new[] { "Amount", "BaseAmount" });

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_Payment_Date",
                table: "FinancialTransactions",
                columns: new[] { "PaymentId", "TransactionDate" });

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_PaymentId",
                table: "FinancialTransactions",
                column: "PaymentId");

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_Property_Date",
                table: "FinancialTransactions",
                columns: new[] { "PropertyId", "TransactionDate" });

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_PropertyId",
                table: "FinancialTransactions",
                column: "PropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_ReferenceNumber",
                table: "FinancialTransactions",
                column: "ReferenceNumber");

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_Reporting",
                table: "FinancialTransactions",
                columns: new[] { "FiscalYear", "FiscalPeriod", "Status", "IsPosted" });

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_ReverseTransactionId",
                table: "FinancialTransactions",
                column: "ReverseTransactionId");

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_Search",
                table: "FinancialTransactions",
                columns: new[] { "TransactionDate", "Status", "IsPosted" });

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_SecondPartyUserId",
                table: "FinancialTransactions",
                column: "SecondPartyUserId");

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_SecondUser_Date",
                table: "FinancialTransactions",
                columns: new[] { "SecondPartyUserId", "TransactionDate" });

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_Status",
                table: "FinancialTransactions",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_TransactionNumber",
                table: "FinancialTransactions",
                column: "TransactionNumber",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_TransactionType",
                table: "FinancialTransactions",
                column: "TransactionType");

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_TypeSummary",
                table: "FinancialTransactions",
                columns: new[] { "TransactionType", "TransactionDate" },
                filter: "\"Status\" = 3 AND \"IsPosted\" = true")
                .Annotation("Npgsql:IndexInclude", new[] { "Amount" });

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_UnitId",
                table: "FinancialTransactions",
                column: "UnitId");

            migrationBuilder.CreateIndex(
                name: "IX_FinancialTransactions_UpdatedBy",
                table: "FinancialTransactions",
                column: "UpdatedBy");

            migrationBuilder.CreateIndex(
                name: "IX_IndexMetadata_LastUpdateTime",
                table: "IndexMetadata",
                column: "LastUpdateTime");

            migrationBuilder.CreateIndex(
                name: "IX_IndexMetadata_Status",
                table: "IndexMetadata",
                column: "Status",
                filter: "\"Status\" = 'Active'");

            migrationBuilder.CreateIndex(
                name: "IX_IndexMetadata_Status_LastUpdate",
                table: "IndexMetadata",
                columns: new[] { "Status", "LastUpdateTime" },
                filter: "\"Status\" = 'Active'");

            migrationBuilder.CreateIndex(
                name: "IX_MessageReactions_MessageId",
                table: "MessageReactions",
                column: "MessageId");

            migrationBuilder.CreateIndex(
                name: "IX_NotificationChannelHistories_ChannelId",
                table: "NotificationChannelHistories",
                column: "ChannelId");

            migrationBuilder.CreateIndex(
                name: "IX_NotificationChannelHistories_ChannelId_SentAt",
                table: "NotificationChannelHistories",
                columns: new[] { "ChannelId", "SentAt" });

            migrationBuilder.CreateIndex(
                name: "IX_NotificationChannelHistories_SenderId",
                table: "NotificationChannelHistories",
                column: "SenderId");

            migrationBuilder.CreateIndex(
                name: "IX_NotificationChannelHistories_SentAt",
                table: "NotificationChannelHistories",
                column: "SentAt");

            migrationBuilder.CreateIndex(
                name: "IX_NotificationChannels_CreatedBy_IsActive",
                table: "NotificationChannels",
                columns: new[] { "CreatedBy", "IsActive" });

            migrationBuilder.CreateIndex(
                name: "IX_NotificationChannels_Identifier",
                table: "NotificationChannels",
                column: "Identifier",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_NotificationChannels_IsActive",
                table: "NotificationChannels",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_NotificationChannels_Type",
                table: "NotificationChannels",
                column: "Type");

            migrationBuilder.CreateIndex(
                name: "IX_Notifications_RecipientId",
                table: "Notifications",
                column: "RecipientId");

            migrationBuilder.CreateIndex(
                name: "IX_Notifications_SenderId",
                table: "Notifications",
                column: "SenderId");

            migrationBuilder.CreateIndex(
                name: "IX_Payments_Amount_Amount",
                table: "Payments",
                column: "Amount_Amount");

            migrationBuilder.CreateIndex(
                name: "IX_Payments_Booking_PaymentDate",
                table: "Payments",
                columns: new[] { "BookingId", "PaymentDate" });

            migrationBuilder.CreateIndex(
                name: "IX_Payments_BookingId",
                table: "Payments",
                column: "BookingId");

            migrationBuilder.CreateIndex(
                name: "IX_Payments_IsDeleted",
                table: "Payments",
                column: "IsDeleted");

            migrationBuilder.CreateIndex(
                name: "IX_Payments_Method_PaymentDate",
                table: "Payments",
                columns: new[] { "PaymentMethod", "PaymentDate" });

            migrationBuilder.CreateIndex(
                name: "IX_Payments_Payment_Amount_Currency",
                table: "Payments",
                column: "Payment_Amount_Currency");

            migrationBuilder.CreateIndex(
                name: "IX_Payments_PaymentDate",
                table: "Payments",
                column: "PaymentDate");

            migrationBuilder.CreateIndex(
                name: "IX_Payments_Status",
                table: "Payments",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_Payments_Status_PaymentDate",
                table: "Payments",
                columns: new[] { "Status", "PaymentDate" });

            migrationBuilder.CreateIndex(
                name: "IX_Payments_TransactionId",
                table: "Payments",
                column: "TransactionId",
                unique: true,
                filter: "\"TransactionId\" IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_PricingRules_Currency",
                table: "PricingRules",
                column: "Currency");

            migrationBuilder.CreateIndex(
                name: "IX_PricingRules_UnitId_StartDate_EndDate",
                table: "PricingRules",
                columns: new[] { "UnitId", "StartDate", "EndDate" });

            migrationBuilder.CreateIndex(
                name: "IX_Properties_City",
                table: "Properties",
                column: "City");

            migrationBuilder.CreateIndex(
                name: "IX_Properties_Currency",
                table: "Properties",
                column: "Currency");

            migrationBuilder.CreateIndex(
                name: "IX_Properties_Name_City",
                table: "Properties",
                columns: new[] { "Name", "City" });

            migrationBuilder.CreateIndex(
                name: "IX_Properties_OwnerId",
                table: "Properties",
                column: "OwnerId");

            migrationBuilder.CreateIndex(
                name: "IX_Properties_TypeId",
                table: "Properties",
                column: "TypeId");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyAmenities_IsDeleted",
                table: "PropertyAmenities",
                column: "IsDeleted");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyAmenities_PropertyId",
                table: "PropertyAmenities",
                column: "PropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyAmenities_PropertyId_PtaId",
                table: "PropertyAmenities",
                columns: new[] { "PropertyId", "PtaId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_PropertyAmenities_PtaId",
                table: "PropertyAmenities",
                column: "PtaId");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyImages_CityName",
                table: "PropertyImages",
                column: "CityName");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyImages_PropertyId",
                table: "PropertyImages",
                column: "PropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyImages_PropertyInSectionId",
                table: "PropertyImages",
                column: "PropertyInSectionId");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyImages_SectionId",
                table: "PropertyImages",
                column: "SectionId");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyImages_TempKey",
                table: "PropertyImages",
                column: "TempKey");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyImages_UnitId",
                table: "PropertyImages",
                column: "UnitId");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyImages_UnitInSectionId",
                table: "PropertyImages",
                column: "UnitInSectionId");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyInSectionImages_PropertyInSectionId",
                table: "PropertyInSectionImages",
                column: "PropertyInSectionId");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyInSectionImages_TempKey",
                table: "PropertyInSectionImages",
                column: "TempKey");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyInSections_PropertyId",
                table: "PropertyInSections",
                column: "PropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyInSections_SectionId_PropertyId",
                table: "PropertyInSections",
                columns: new[] { "SectionId", "PropertyId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_PropertyPolicies_IsDeleted",
                table: "PropertyPolicies",
                column: "IsDeleted");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyPolicies_PolicyType",
                table: "PropertyPolicies",
                column: "Type");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyPolicies_PropertyId",
                table: "PropertyPolicies",
                column: "PropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyPolicies_PropertyId_PolicyType",
                table: "PropertyPolicies",
                columns: new[] { "PropertyId", "Type" });

            migrationBuilder.CreateIndex(
                name: "IX_PropertyServices_IsDeleted",
                table: "PropertyServices",
                column: "IsDeleted");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyServices_Name",
                table: "PropertyServices",
                column: "Name");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyServices_PropertyId",
                table: "PropertyServices",
                column: "PropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyTypeAmenities_AmenityId",
                table: "PropertyTypeAmenities",
                column: "AmenityId");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyTypeAmenities_IsDeleted",
                table: "PropertyTypeAmenities",
                column: "IsDeleted");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyTypeAmenities_PropertyTypeId",
                table: "PropertyTypeAmenities",
                column: "PropertyTypeId");

            migrationBuilder.CreateIndex(
                name: "IX_PropertyTypeAmenities_PropertyTypeId_AmenityId",
                table: "PropertyTypeAmenities",
                columns: new[] { "PropertyTypeId", "AmenityId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_PropertyTypes_Name",
                table: "PropertyTypes",
                column: "Name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Reports_ReportedPropertyId",
                table: "Reports",
                column: "ReportedPropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_Reports_ReportedUserId",
                table: "Reports",
                column: "ReportedUserId");

            migrationBuilder.CreateIndex(
                name: "IX_Reports_ReporterUserId",
                table: "Reports",
                column: "ReporterUserId");

            migrationBuilder.CreateIndex(
                name: "IX_ReviewImages_ReviewId",
                table: "ReviewImages",
                column: "ReviewId");

            migrationBuilder.CreateIndex(
                name: "IX_ReviewResponses_ReviewId",
                table: "ReviewResponses",
                column: "ReviewId");

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_BookingId",
                table: "Reviews",
                column: "BookingId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_IsDeleted",
                table: "Reviews",
                column: "IsDeleted");

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_PropertyId",
                table: "Reviews",
                column: "PropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_Roles_Name",
                table: "Roles",
                column: "Name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_SearchFilters_FieldId",
                table: "SearchFilters",
                column: "FieldId");

            migrationBuilder.CreateIndex(
                name: "IX_SearchFilters_UnitTypeId",
                table: "SearchFilters",
                column: "UnitTypeId");

            migrationBuilder.CreateIndex(
                name: "IX_SectionImages_SectionId",
                table: "SectionImages",
                column: "SectionId");

            migrationBuilder.CreateIndex(
                name: "IX_SectionImages_TempKey",
                table: "SectionImages",
                column: "TempKey");

            migrationBuilder.CreateIndex(
                name: "IX_Sections_BackgroundImageId",
                table: "Sections",
                column: "BackgroundImageId");

            migrationBuilder.CreateIndex(
                name: "IX_Sections_CityName",
                table: "Sections",
                column: "CityName");

            migrationBuilder.CreateIndex(
                name: "IX_Staff_IsDeleted",
                table: "Staff",
                column: "IsDeleted");

            migrationBuilder.CreateIndex(
                name: "IX_Staff_PropertyId",
                table: "Staff",
                column: "PropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_Staff_UserId",
                table: "Staff",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Staff_UserId_PropertyId",
                table: "Staff",
                columns: new[] { "UserId", "PropertyId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_UnitAvailability_BookingId",
                table: "UnitAvailability",
                column: "BookingId");

            migrationBuilder.CreateIndex(
                name: "IX_UnitAvailability_UnitId_StartDate_EndDate",
                table: "UnitAvailability",
                columns: new[] { "UnitId", "StartDate", "EndDate" });

            migrationBuilder.CreateIndex(
                name: "IX_UnitFieldValues_FieldId",
                table: "UnitFieldValues",
                column: "UnitTypeFieldId");

            migrationBuilder.CreateIndex(
                name: "IX_UnitFieldValues_UnitId",
                table: "UnitFieldValues",
                column: "UnitId");

            migrationBuilder.CreateIndex(
                name: "IX_UnitInSectionImages_TempKey",
                table: "UnitInSectionImages",
                column: "TempKey");

            migrationBuilder.CreateIndex(
                name: "IX_UnitInSectionImages_UnitInSectionId",
                table: "UnitInSectionImages",
                column: "UnitInSectionId");

            migrationBuilder.CreateIndex(
                name: "IX_UnitInSections_PropertyId",
                table: "UnitInSections",
                column: "PropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_UnitInSections_SectionId_UnitId",
                table: "UnitInSections",
                columns: new[] { "SectionId", "UnitId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_UnitInSections_UnitId",
                table: "UnitInSections",
                column: "UnitId");

            migrationBuilder.CreateIndex(
                name: "IX_Units_AllowsCancellation",
                table: "Units",
                column: "AllowsCancellation");

            migrationBuilder.CreateIndex(
                name: "IX_Units_IsAvailable",
                table: "Units",
                column: "IsAvailable");

            migrationBuilder.CreateIndex(
                name: "IX_Units_IsDeleted",
                table: "Units",
                column: "IsDeleted");

            migrationBuilder.CreateIndex(
                name: "IX_Units_PricingMethod",
                table: "Units",
                column: "PricingMethod");

            migrationBuilder.CreateIndex(
                name: "IX_Units_PropertyId",
                table: "Units",
                column: "PropertyId");

            migrationBuilder.CreateIndex(
                name: "IX_Units_PropertyId_Name",
                table: "Units",
                columns: new[] { "PropertyId", "Name" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Units_UnitTypeId",
                table: "Units",
                column: "UnitTypeId");

            migrationBuilder.CreateIndex(
                name: "IX_UnitTypeFields_PropertyTypeId_FieldName",
                table: "UnitTypeFields",
                columns: new[] { "UnitTypeId", "FieldName" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_UnitTypes_Name_PropertyTypeId",
                table: "UnitTypes",
                columns: new[] { "Name", "PropertyTypeId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_UnitTypes_PropertyTypeId",
                table: "UnitTypes",
                column: "PropertyTypeId");

            migrationBuilder.CreateIndex(
                name: "IX_UserChannels_ChannelId_IsActive",
                table: "UserChannels",
                columns: new[] { "ChannelId", "IsActive" });

            migrationBuilder.CreateIndex(
                name: "IX_UserChannels_IsActive",
                table: "UserChannels",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_UserChannels_UserId_ChannelId",
                table: "UserChannels",
                columns: new[] { "UserId", "ChannelId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_UserRoles_IsDeleted",
                table: "UserRoles",
                column: "IsDeleted");

            migrationBuilder.CreateIndex(
                name: "IX_UserRoles_RoleId",
                table: "UserRoles",
                column: "RoleId");

            migrationBuilder.CreateIndex(
                name: "IX_UserRoles_UserId",
                table: "UserRoles",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_Users_Email",
                table: "Users",
                column: "Email",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Users_IsDeleted",
                table: "Users",
                column: "IsDeleted");

            migrationBuilder.CreateIndex(
                name: "IX_Users_Name_trgm",
                table: "Users",
                column: "Name")
                .Annotation("Npgsql:IndexMethod", "gin")
                .Annotation("Npgsql:IndexOperators", new[] { "gin_trgm_ops" });

            migrationBuilder.CreateIndex(
                name: "IX_Users_Phone",
                table: "Users",
                column: "Phone");

            migrationBuilder.CreateIndex(
                name: "IX_UserSettings_UserId",
                table: "UserSettings",
                column: "UserId",
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_PropertyImages_PropertyInSections_PropertyInSectionId",
                table: "PropertyImages",
                column: "PropertyInSectionId",
                principalTable: "PropertyInSections",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_PropertyImages_Sections_SectionId",
                table: "PropertyImages",
                column: "SectionId",
                principalTable: "Sections",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_PropertyImages_UnitInSections_UnitInSectionId",
                table: "PropertyImages",
                column: "UnitInSectionId",
                principalTable: "UnitInSections",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_PropertyInSectionImages_PropertyInSections_PropertyInSectio~",
                table: "PropertyInSectionImages",
                column: "PropertyInSectionId",
                principalTable: "PropertyInSections",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_PropertyInSections_Sections_SectionId",
                table: "PropertyInSections",
                column: "SectionId",
                principalTable: "Sections",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_SectionImages_Sections_SectionId",
                table: "SectionImages",
                column: "SectionId",
                principalTable: "Sections",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Sections_Cities_CityName",
                table: "Sections");

            migrationBuilder.DropForeignKey(
                name: "FK_SectionImages_Sections_SectionId",
                table: "SectionImages");

            migrationBuilder.DropTable(
                name: "AdminActions");

            migrationBuilder.DropTable(
                name: "AuditLogs");

            migrationBuilder.DropTable(
                name: "BookingServices");

            migrationBuilder.DropTable(
                name: "ChatAttachments");

            migrationBuilder.DropTable(
                name: "ChatConversationParticipant");

            migrationBuilder.DropTable(
                name: "ChatSettings");

            migrationBuilder.DropTable(
                name: "Favorites");

            migrationBuilder.DropTable(
                name: "FieldGroupFields");

            migrationBuilder.DropTable(
                name: "FinancialTransactions");

            migrationBuilder.DropTable(
                name: "IndexMetadata");

            migrationBuilder.DropTable(
                name: "MessageReactions");

            migrationBuilder.DropTable(
                name: "NotificationChannelHistories");

            migrationBuilder.DropTable(
                name: "Notifications");

            migrationBuilder.DropTable(
                name: "PricingRules");

            migrationBuilder.DropTable(
                name: "PropertyAmenities");

            migrationBuilder.DropTable(
                name: "PropertyImages");

            migrationBuilder.DropTable(
                name: "PropertyInSectionImages");

            migrationBuilder.DropTable(
                name: "PropertyPolicies");

            migrationBuilder.DropTable(
                name: "Reports");

            migrationBuilder.DropTable(
                name: "ReviewImages");

            migrationBuilder.DropTable(
                name: "ReviewResponses");

            migrationBuilder.DropTable(
                name: "SearchFilters");

            migrationBuilder.DropTable(
                name: "SearchLogs");

            migrationBuilder.DropTable(
                name: "Staff");

            migrationBuilder.DropTable(
                name: "UnitAvailability");

            migrationBuilder.DropTable(
                name: "UnitFieldValues");

            migrationBuilder.DropTable(
                name: "UnitInSectionImages");

            migrationBuilder.DropTable(
                name: "UserChannels");

            migrationBuilder.DropTable(
                name: "UserRoles");

            migrationBuilder.DropTable(
                name: "UserSettings");

            migrationBuilder.DropTable(
                name: "PropertyServices");

            migrationBuilder.DropTable(
                name: "FieldGroups");

            migrationBuilder.DropTable(
                name: "ChartOfAccounts");

            migrationBuilder.DropTable(
                name: "Payments");

            migrationBuilder.DropTable(
                name: "ChatMessages");

            migrationBuilder.DropTable(
                name: "PropertyTypeAmenities");

            migrationBuilder.DropTable(
                name: "PropertyInSections");

            migrationBuilder.DropTable(
                name: "Reviews");

            migrationBuilder.DropTable(
                name: "UnitTypeFields");

            migrationBuilder.DropTable(
                name: "UnitInSections");

            migrationBuilder.DropTable(
                name: "NotificationChannels");

            migrationBuilder.DropTable(
                name: "Roles");

            migrationBuilder.DropTable(
                name: "ChatConversations");

            migrationBuilder.DropTable(
                name: "Amenities");

            migrationBuilder.DropTable(
                name: "Bookings");

            migrationBuilder.DropTable(
                name: "Units");

            migrationBuilder.DropTable(
                name: "Properties");

            migrationBuilder.DropTable(
                name: "UnitTypes");

            migrationBuilder.DropTable(
                name: "Currencies");

            migrationBuilder.DropTable(
                name: "Users");

            migrationBuilder.DropTable(
                name: "PropertyTypes");

            migrationBuilder.DropTable(
                name: "Cities");

            migrationBuilder.DropTable(
                name: "Sections");

            migrationBuilder.DropTable(
                name: "SectionImages");
        }
    }
}
