// RedisConnectionManager.cs
using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using StackExchange.Redis;
using Polly;
using Polly.CircuitBreaker;
using YemenBooking.Application.Infrastructure.Services;

namespace YemenBooking.Application.Infrastructure.Services
{
    public interface IRedisConnectionManager
    {
        IDatabase GetDatabase(int db = -1);
        ISubscriber GetSubscriber();
        IServer GetServer();
        Task<bool> IsConnectedAsync();
        Task FlushDatabaseAsync(int db = -1);
    }
}