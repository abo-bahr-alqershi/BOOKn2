using MediatR;
using Microsoft.Extensions.Logging;

namespace YemenBooking.Application.Common.Behaviors;

public class AuthorizationBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
    where TRequest : IRequest<TResponse>
{
    private readonly ILogger<AuthorizationBehavior<TRequest, TResponse>> _logger;

    public AuthorizationBehavior(ILogger<AuthorizationBehavior<TRequest, TResponse>> logger)
    {
        _logger = logger;
    }

    public async Task<TResponse> Handle(TRequest request, RequestHandlerDelegate<TResponse> next, CancellationToken cancellationToken)
    {
        _logger.LogInformation("Checking authorization for {RequestName}", typeof(TRequest).Name);
        
        // Add authorization logic here if needed
        // For now, we'll just pass through
        
        var response = await next();
        _logger.LogInformation("Authorization check completed for {RequestName}", typeof(TRequest).Name);
        
        return response;
    }
}
