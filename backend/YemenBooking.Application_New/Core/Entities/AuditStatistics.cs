using System;
using System.Collections.Generic;
using YemenBooking.Application_New.Core.Enums;

namespace YemenBooking.Application_New.Core.Entities;

/// <summary>
/// إحصائيات التدقيق
/// Audit statistics
/// </summary>
public class AuditStatistics
{
    public int TotalOperations { get; set; }
    public Dictionary<AuditAction, int> OperationsByAction { get; set; } = new();
    public Dictionary<string, int> OperationsByEntityType { get; set; } = new();
    public Dictionary<string, int> OperationsByUser { get; set; } = new();
    public DateTime FromDate { get; set; }
    public DateTime ToDate { get; set; }
    public int UniqueUsers { get; set; }
    public int FailedOperations { get; set; }
}
