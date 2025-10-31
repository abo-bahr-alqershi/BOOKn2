using MediatR;
using System;
using System.Collections.Generic;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.DynamicFields.Events {
    // أحداث الحقول الديناميكية
    public class DynamicFieldChangedEvent : INotification
    {
        public Guid PropertyId { get; set; }
        public string FieldName { get; set; }
        public string FieldValue { get; set; }
        public bool IsAdd { get; set; } // true للإضافة، false للحذف
        public DateTime ChangedAt { get; set; }
    }

}