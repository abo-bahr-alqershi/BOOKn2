using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using System;
using System.Threading;
using System.Threading.Tasks;

namespace YemenBooking.Core.Interfaces;

/// <summary>
/// واجهة وحدة العمل للتحكم في المعاملات
/// Unit of Work interface for transaction management
/// </summary>
public interface IUnitOfWork : IDisposable
{
    /// <summary>
    /// مستودع المستخدمين
    /// Users repository
    /// </summary>
    IUserRepository Users { get; }
    IRepository<T> Repository<T>() where T : class;

    /// <summary>
    /// بدء معاملة جديدة
    /// Begin new transaction
    /// </summary>
    Task BeginTransactionAsync(CancellationToken cancellationToken = default);
    
    /// <summary>
    /// تأكيد المعاملة
    /// Commit transaction
    /// </summary>
    Task CommitTransactionAsync(CancellationToken cancellationToken = default);
    
    /// <summary>
    /// إلغاء المعاملة
    /// Rollback transaction
    /// </summary>
    Task RollbackTransactionAsync(CancellationToken cancellationToken = default);
    
    /// <summary>
    /// حفظ جميع التغييرات
    /// Save all changes
    /// </summary>
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
    
    /// <summary>
    /// تنفيذ عملية في معاملة
    /// Execute operation in transaction
    /// </summary>
    Task<T> ExecuteInTransactionAsync<T>(Func<Task<T>> operation, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// تنفيذ عملية في معاملة (بدون إرجاع قيمة)
    /// Execute operation in transaction (void)
    /// </summary>
    Task ExecuteInTransactionAsync(Func<Task> operation, CancellationToken cancellationToken = default);
}