using MediatR;
using Microsoft.Extensions.Logging;
using System.Diagnostics;

namespace YemenBooking.Application.Common.Behaviors;

public class PerformanceBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
    where TRequest : IRequest<TResponse>
{
    private readonly ILogger<PerformanceBehavior<TRequest, TResponse>> _logger;

    public PerformanceBehavior(ILogger<PerformanceBehavior<TRequest, TResponse>> logger)
    {
        _logger = logger;
    }

    public async Task<TResponse> Handle(TRequest request, RequestHandlerDelegate<TResponse> next, CancellationToken cancellationToken)
    {
        var stopwatch = Stopwatch.StartNew();
        
        _logger.LogInformation("Starting performance monitoring for {RequestName}", typeof(TRequest).Name);
        
        var response = await next();
        
        stopwatch.Stop();
        
        _logger.LogInformation("Completed {RequestName} in {ElapsedMilliseconds} ms", 
            typeof(TRequest).Name, stopwatch.ElapsedMilliseconds);
        
        return response;
    }
}
