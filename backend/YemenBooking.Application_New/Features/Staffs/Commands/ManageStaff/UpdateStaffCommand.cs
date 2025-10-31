using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Enums;

namespace YemenBooking.Application.Features.Staffs.Commands.ManageStaff;

/// <summary>
/// أمر لتحديث بيانات الموظف
/// Command to update staff information
/// </summary>
public class UpdateStaffCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف الموظف
    /// Staff ID
    /// </summary>
    public Guid StaffId { get; set; }

    /// <summary>
    /// المنصب أو الدور المحدث
    /// Updated position or role
    /// </summary>
    public StaffPosition? Position { get; set; }

    /// <summary>
    /// صلاحيات الموظف المحدثة
    /// Updated permissions
    /// </summary>
    public string? Permissions { get; set; }
} 