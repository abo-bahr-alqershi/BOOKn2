// using System;
// using System.Threading;
// using System.Threading.Channels;
// using System.Threading.Tasks;
// using LiteDB;
// using Microsoft.Extensions.Hosting;
// using Microsoft.Extensions.Logging;

// namespace YemenBooking.Infrastructure.Indexing.Services
// {
// 	public interface ILiteDbWriteQueue
// 	{
// 		Task EnqueueAsync(Func<LiteDatabase, Task> handler, string description, CancellationToken cancellationToken = default);
// 	}

// 	public class LiteDbWriteOperation
// 	{
// 		public Func<LiteDatabase, Task> Handler { get; init; } = default!;
// 		public string Description { get; init; } = string.Empty;
// 		public TaskCompletionSource<bool> CompletionSource { get; init; } = new(TaskCreationOptions.RunContinuationsAsynchronously);
// 	}

// 	/// <summary>
// 	/// Queued single-writer service for LiteDB operations to avoid concurrent write issues.
// 	/// </summary>
// 	public class QueuedLiteDbService : IHostedService, ILiteDbWriteQueue, IDisposable
// 	{
// 		private readonly Channel<LiteDbWriteOperation> _operationQueue;
// 		private readonly ConnectionString _connectionString;
// 		private readonly ILogger<QueuedLiteDbService> _logger;
// 		private Task? _processingTask;
// 		private CancellationTokenSource? _cts;

// 		public QueuedLiteDbService(string dbPath, ILogger<QueuedLiteDbService> logger)
// 		{
// 			_connectionString = new ConnectionString
// 			{
// 				Filename = dbPath,
// 				Connection = ConnectionType.Shared,
// 				InitialSize = 1024 * 1024,
// 				Upgrade = true
// 			};
// 			_logger = logger;

// 			var options = new BoundedChannelOptions(2000)
// 			{
// 				FullMode = BoundedChannelFullMode.Wait,
// 				SingleReader = true,
// 				SingleWriter = false
// 			};
// 			_operationQueue = Channel.CreateBounded<LiteDbWriteOperation>(options);
// 		}

// 		public async Task EnqueueAsync(Func<LiteDatabase, Task> handler, string description, CancellationToken cancellationToken = default)
// 		{
// 			var op = new LiteDbWriteOperation
// 			{
// 				Handler = handler,
// 				Description = description
// 			};
// 			await _operationQueue.Writer.WriteAsync(op, cancellationToken);
// 			_logger.LogDebug("تمت إضافة عملية للصف: {Description}", description);
// 			await op.CompletionSource.Task.ConfigureAwait(false);
// 		}

// 		public Task StartAsync(CancellationToken cancellationToken)
// 		{
// 			_cts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
// 			_processingTask = Task.Run(() => ProcessQueueAsync(_cts.Token), CancellationToken.None);
// 			_logger.LogInformation("بدء معالج طابور LiteDB");
// 			return Task.CompletedTask;
// 		}

// 		private async Task ProcessQueueAsync(CancellationToken ct)
// 		{
// 			await foreach (var op in _operationQueue.Reader.ReadAllAsync(ct))
// 			{
// 				try
// 				{
// 					using var db = new LiteDatabase(_connectionString);
// 					await op.Handler(db).ConfigureAwait(false);
// 					op.CompletionSource.SetResult(true);
// 				}
// 				catch (Exception ex)
// 				{
// 					_logger.LogError(ex, "خطأ أثناء معالجة عملية: {Description}", op.Description);
// 					op.CompletionSource.SetException(ex);
// 				}
// 			}
// 		}

// 		public async Task StopAsync(CancellationToken cancellationToken)
// 		{
// 			_operationQueue.Writer.TryComplete();
// 			try
// 			{
// 				if (_processingTask != null)
// 				{
// 					await _processingTask.ConfigureAwait(false);
// 				}
// 			}
// 			finally
// 			{
// 				_cts?.Cancel();
// 				_logger.LogInformation("توقف معالج طابور LiteDB");
// 			}
// 		}

// 		public void Dispose()
// 		{
// 			_cts?.Dispose();
// 		}
// 	}
// }