namespace YemenBooking.Core.Enums;

/// <summary>
/// أدوار المستخدمين في النظام
/// User roles in the system
/// </summary>
public enum UserRole
{
    /// <summary>
    /// المشرف العام - صلاحيات كاملة على النظام
    /// Super Administrator - Full system access
    /// </summary>
    SUPER_ADMIN,
    
    /// <summary>
    /// مدير النظام - صلاحيات إدارية واسعة
    /// Administrator - Wide administrative permissions
    /// </summary>
    ADMIN,
    
    /// <summary>
    /// مالك الفندق - إدارة الفندق والغرف والحجوزات
    /// Hotel Owner - Hotel, rooms and bookings management
    /// </summary>
    HOTEL_OWNER,
    
    /// <summary>
    /// مدير الفندق - إدارة العمليات اليومية
    /// Hotel Manager - Daily operations management
    /// </summary>
    HOTEL_MANAGER,
    
    /// <summary>
    /// موظف الاستقبال - إدارة الحجوزات وخدمة العملاء
    /// Receptionist - Bookings and customer service
    /// </summary>
    RECEPTIONIST,
    
    /// <summary>
    /// عميل - حجز الغرف وإدارة الحساب الشخصي
    /// Customer - Room booking and personal account management
    /// </summary>
    CUSTOMER
}