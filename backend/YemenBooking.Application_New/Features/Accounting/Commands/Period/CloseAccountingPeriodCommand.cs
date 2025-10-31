using System;
using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Accounting.Commands.Period
{
    /// <summary>
    /// أمر إقفال الفترة المحاسبية
    /// Close accounting period command
    /// </summary>
    public class CloseAccountingPeriodCommand : IRequest<ResultDto<bool>>
    {
        /// <summary>
        /// السنة المالية
        /// Fiscal year
        /// </summary>
        public int Year { get; set; }

        /// <summary>
        /// الشهر المالي
        /// Fiscal month
        /// </summary>
        public int Month { get; set; }

        /// <summary>
        /// ملاحظات الإقفال
        /// Closing notes
        /// </summary>
        public string Notes { get; set; }

        /// <summary>
        /// فرض الإقفال حتى لو كانت هناك معاملات غير مرحلة
        /// Force closing even if there are unposted transactions
        /// </summary>
        public bool ForceClose { get; set; } = false;
    }
}
