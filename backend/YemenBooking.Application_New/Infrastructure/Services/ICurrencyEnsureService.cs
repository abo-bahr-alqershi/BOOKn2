using System.Threading;
using System.Threading.Tasks;

namespace YemenBooking.Application.Infrastructure.Services
{
    /// <summary>
    /// خدمة لضمان وجود العملة في قاعدة البيانات عند الحاجة
    /// Service to ensure a currency exists in the database on demand
    /// </summary>
    public interface ICurrencyEnsureService
    {
        /// <summary>
        /// يتأكد من وجود العملة برمزها؛ إذا لم تكن موجودة يتم إنشاؤها
        /// Ensure currency with given code exists; create it if missing
        /// </summary>
        Task EnsureCurrencyExistsAsync(string currencyCode, CancellationToken cancellationToken = default);
    }
}

