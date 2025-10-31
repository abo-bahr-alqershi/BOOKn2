using YemenBooking.Application.Features.Units.DTOs;

namespace YemenBooking.Application.Features.DynamicFields.DTOs {
    using System;
    using System.Collections.Generic;

    /// <summary>
    /// DTO لمجموعة حقول نوع الوحدة
    /// DTO for grouping unit type fields
    /// </summary>
    public class FieldGroupDto
    {
        /// <summary>
        /// معرف المجموعة
        /// Group identifier
        /// </summary>
        public string GroupId { get; set; }
        
        /// <summary>
        /// معرف نوع الوحدة
        /// Unit type identifier
        /// </summary>
        public string UnitTypeId { get; set; }

        /// <summary>
        /// اسم المجموعة
        /// Group name
        /// </summary>
        public string GroupName { get; set; }

        /// <summary>
        /// الاسم المعروض للمجموعة
        /// Display name of the group
        /// </summary>
        public string DisplayName { get; set; }

        /// <summary>
        /// وصف المجموعة
        /// Description of the group
        /// </summary>
        public string Description { get; set; }
        
        /// <summary>
        /// ترتيب المجموعة
        /// Sort order
        /// </summary>
        public int SortOrder { get; set; }
        
        /// <summary>
        /// قابلية الطي للمجموعة
        /// Whether the group is collapsible
        /// </summary>
        public bool IsCollapsible { get; set; }
        
        /// <summary>
        /// حالة التوسع الافتراضي للمجموعة
        /// Default expanded state
        /// </summary>
        public bool IsExpandedByDefault { get; set; }

        /// <summary>
        /// حقول المجموعة
        /// Fields within the group
        /// </summary>
        public List<UnitTypeFieldDto> Fields { get; set; } = new List<UnitTypeFieldDto>();
    }
} 