using YemenBooking.Core.Interfaces;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Events;

/// <summary>
/// حدث فهرسة الحقول الديناميكية
/// Dynamic field indexing event
/// </summary>
public class DynamicFieldIndexingEvent : IDomainEvent
{
    public Guid EventId { get; } = Guid.NewGuid();
    public DateTime OccurredOn { get; } = DateTime.UtcNow;
    public string EventType => nameof(DynamicFieldIndexingEvent);
    public int Version { get; } = 1;
    public Guid? UserId { get; set; }
    public string? CorrelationId { get; set; }

    /// <summary>
    /// معرف الحقل الديناميكي
    /// Dynamic field ID
    /// </summary>
    public Guid FieldId { get; set; }

    /// <summary>
    /// اسم الحقل
    /// Field name
    /// </summary>
    public string FieldName { get; set; } = string.Empty;

    /// <summary>
    /// نوع الحقل
    /// Field type
    /// </summary>
    public string FieldType { get; set; } = string.Empty;

    /// <summary>
    /// قيمة الحقل
    /// Field value
    /// </summary>
    public string FieldValue { get; set; } = string.Empty;

    /// <summary>
    /// معرف الكيان المرتبط (عقار أو وحدة)
    /// Associated entity ID (property or unit)
    /// </summary>
    public Guid EntityId { get; set; }

    /// <summary>
    /// نوع الكيان (Property, Unit)
    /// Entity type
    /// </summary>
    public string EntityType { get; set; } = string.Empty;

    /// <summary>
    /// نوع العملية (Create, Update, Delete)
    /// Operation type
    /// </summary>
    public string Operation { get; set; } = string.Empty;

    /// <summary>
    /// بيانات إضافية للفهرسة
    /// Additional indexing data
    /// </summary>
    public Dictionary<string, object> AdditionalData { get; set; } = new();
}

/// <summary>
/// حدث فهرسة المدن
/// City indexing event
/// </summary>
public class CityIndexingEvent : IDomainEvent
{
    public Guid EventId { get; } = Guid.NewGuid();
    public DateTime OccurredOn { get; } = DateTime.UtcNow;
    public string EventType => nameof(CityIndexingEvent);
    public int Version { get; } = 1;
    public Guid? UserId { get; set; }
    public string? CorrelationId { get; set; }

    /// <summary>
    /// اسم المدينة
    /// City name
    /// </summary>
    public string CityName { get; set; } = string.Empty;

    /// <summary>
    /// معرف العقار
    /// Property ID
    /// </summary>
    public Guid PropertyId { get; set; }

    /// <summary>
    /// نوع العملية (Add, Remove, Update)
    /// Operation type
    /// </summary>
    public string Operation { get; set; } = string.Empty;

    /// <summary>
    /// إحصائيات المدينة المحدثة
    /// Updated city statistics
    /// </summary>
    public Dictionary<string, object> CityStats { get; set; } = new();
}

/// <summary>
/// حدث فهرسة التسعير المتقدم
/// Advanced pricing indexing event
/// </summary>
public class AdvancedPricingIndexingEvent : IDomainEvent
{
    public Guid EventId { get; } = Guid.NewGuid();
    public DateTime OccurredOn { get; } = DateTime.UtcNow;
    public string EventType => nameof(AdvancedPricingIndexingEvent);
    public int Version { get; } = 1;
    public Guid? UserId { get; set; }
    public string? CorrelationId { get; set; }

    /// <summary>
    /// معرف قاعدة التسعير
    /// Pricing rule ID
    /// </summary>
    public Guid PricingRuleId { get; set; }

    /// <summary>
    /// معرف الوحدة
    /// Unit ID
    /// </summary>
    public Guid UnitId { get; set; }

    /// <summary>
    /// نوع السعر
    /// Price type
    /// </summary>
    public string PriceType { get; set; } = string.Empty;

    /// <summary>
    /// مبلغ السعر
    /// Price amount
    /// </summary>
    public decimal PriceAmount { get; set; }

    /// <summary>
    /// العملة
    /// Currency
    /// </summary>
    public string Currency { get; set; } = string.Empty;

    /// <summary>
    /// تاريخ البداية
    /// Start date
    /// </summary>
    public DateTime StartDate { get; set; }

    /// <summary>
    /// تاريخ النهاية
    /// End date
    /// </summary>
    public DateTime EndDate { get; set; }

    /// <summary>
    /// نوع العملية (Create, Update, Delete)
    /// Operation type
    /// </summary>
    public string Operation { get; set; } = string.Empty;

    /// <summary>
    /// بيانات التسعير الديناميكي
    /// Dynamic pricing data
    /// </summary>
    public Dictionary<string, object> PricingData { get; set; } = new();
}

/// <summary>
/// حدث فهرسة الإتاحة المتقدمة
/// Advanced availability indexing event
/// </summary>
public class AdvancedAvailabilityIndexingEvent : IDomainEvent
{
    public Guid EventId { get; } = Guid.NewGuid();
    public DateTime OccurredOn { get; } = DateTime.UtcNow;
    public string EventType => nameof(AdvancedAvailabilityIndexingEvent);
    public int Version { get; } = 1;
    public Guid? UserId { get; set; }
    public string? CorrelationId { get; set; }

    /// <summary>
    /// معرف الإتاحة
    /// Availability ID
    /// </summary>
    public Guid AvailabilityId { get; set; }

    /// <summary>
    /// معرف الوحدة
    /// Unit ID
    /// </summary>
    public Guid UnitId { get; set; }

    /// <summary>
    /// تاريخ البداية
    /// Start date
    /// </summary>
    public DateTime StartDate { get; set; }

    /// <summary>
    /// تاريخ النهاية
    /// End date
    /// </summary>
    public DateTime EndDate { get; set; }

    /// <summary>
    /// حالة الإتاحة
    /// Availability status
    /// </summary>
    public string Status { get; set; } = string.Empty;

    /// <summary>
    /// نوع العملية (Create, Update, Delete)
    /// Operation type
    /// </summary>
    public string Operation { get; set; } = string.Empty;

    /// <summary>
    /// بيانات الإتاحة التفصيلية
    /// Detailed availability data
    /// </summary>
    public Dictionary<string, object> AvailabilityData { get; set; } = new();
}

/// <summary>
/// حدث فهرسة المرافق المتقدمة
/// Advanced facility indexing event
/// </summary>
public class AdvancedFacilityIndexingEvent : IDomainEvent
{
    public Guid EventId { get; } = Guid.NewGuid();
    public DateTime OccurredOn { get; } = DateTime.UtcNow;
    public string EventType => nameof(AdvancedFacilityIndexingEvent);
    public int Version { get; } = 1;
    public Guid? UserId { get; set; }
    public string? CorrelationId { get; set; }

    /// <summary>
    /// معرف العقار
    /// Property ID
    /// </summary>
    public Guid PropertyId { get; set; }

    /// <summary>
    /// معرف المرفق
    /// Facility ID
    /// </summary>
    public Guid FacilityId { get; set; }

    /// <summary>
    /// اسم المرفق
    /// Facility name
    /// </summary>
    public string FacilityName { get; set; } = string.Empty;

    /// <summary>
    /// نوع العملية (Associate, Dissociate, Update)
    /// Operation type
    /// </summary>
    public string Operation { get; set; } = string.Empty;

    /// <summary>
    /// بيانات المرفق الإضافية
    /// Additional facility data
    /// </summary>
    public Dictionary<string, object> FacilityData { get; set; } = new();
}

/// <summary>
/// حدث فهرسة أنواع العقارات والوحدات
/// Property and unit types indexing event
/// </summary>
public class TypeIndexingEvent : IDomainEvent
{
    public Guid EventId { get; } = Guid.NewGuid();
    public DateTime OccurredOn { get; } = DateTime.UtcNow;
    public string EventType => nameof(TypeIndexingEvent);
    public int Version { get; } = 1;
    public Guid? UserId { get; set; }
    public string? CorrelationId { get; set; }

    /// <summary>
    /// معرف النوع
    /// Type ID
    /// </summary>
    public Guid TypeId { get; set; }

    /// <summary>
    /// اسم النوع
    /// Type name
    /// </summary>
    public string TypeName { get; set; } = string.Empty;

    /// <summary>
    /// نوع الكيان (PropertyType, UnitType)
    /// Entity type
    /// </summary>
    public string EntityType { get; set; } = string.Empty;

    /// <summary>
    /// نوع العملية (Create, Update, Delete)
    /// Operation type
    /// </summary>
    public string Operation { get; set; } = string.Empty;

    /// <summary>
    /// الحقول المرتبطة بالنوع
    /// Associated fields with the type
    /// </summary>
    public List<string> AssociatedFields { get; set; } = new();

    /// <summary>
    /// بيانات النوع التفصيلية
    /// Detailed type data
    /// </summary>
    public Dictionary<string, object> TypeData { get; set; } = new();
}

/// <summary>
/// حدث فهرسة شامل متقدم
/// Advanced comprehensive indexing event
/// </summary>
public class ComprehensiveIndexingEvent : IDomainEvent
{
    public Guid EventId { get; } = Guid.NewGuid();
    public DateTime OccurredOn { get; } = DateTime.UtcNow;
    public string EventType => nameof(ComprehensiveIndexingEvent);
    public int Version { get; } = 1;
    public Guid? UserId { get; set; }
    public string? CorrelationId { get; set; }

    /// <summary>
    /// معرف الكيان الرئيسي
    /// Main entity ID
    /// </summary>
    public Guid EntityId { get; set; }

    /// <summary>
    /// نوع الكيان الرئيسي
    /// Main entity type
    /// </summary>
    public string EntityType { get; set; } = string.Empty;

    /// <summary>
    /// قائمة العمليات المطلوبة
    /// Required operations list
    /// </summary>
    public List<string> RequiredOperations { get; set; } = new();

    /// <summary>
    /// الكيانات المرتبطة للفهرسة
    /// Related entities for indexing
    /// </summary>
    public Dictionary<string, List<Guid>> RelatedEntities { get; set; } = new();

    /// <summary>
    /// أولوية الفهرسة
    /// Indexing priority
    /// </summary>
    public int Priority { get; set; } = 1;

    /// <summary>
    /// بيانات شاملة للفهرسة
    /// Comprehensive indexing data
    /// </summary>
    public Dictionary<string, object> IndexingData { get; set; } = new();
}