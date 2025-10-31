namespace YemenBooking.Api.Middlewares
{
    using System;
    using System.Linq;
    using System.Net.WebSockets;
    using System.Threading;
    using System.Threading.Tasks;
    using Microsoft.AspNetCore.Http;
    using Microsoft.Extensions.Logging;
    using YemenBooking.Infrastructure.Services;
    using Microsoft.AspNetCore.Authentication;
    using Microsoft.AspNetCore.Authentication.JwtBearer;
    using System.Security.Claims;
    using System.IdentityModel.Tokens.Jwt;
    using System.Text;
    using System.Text.Json;
    using Microsoft.Extensions.DependencyInjection;
    using YemenBooking.Core.Interfaces.Repositories;
    using YemenBooking.Core.Interfaces;
    using YemenBooking.Application.Common.Interfaces;

    /// <summary>
    /// Middleware to handle WebSocket connections for chat
    /// </summary>
    public class ChatWebSocketMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly WebSocketConnectionManager _manager;
        private readonly ILogger<ChatWebSocketMiddleware> _logger;
        private readonly IServiceProvider _serviceProvider;
        

        public ChatWebSocketMiddleware(
            RequestDelegate next,
            WebSocketConnectionManager manager,
            ILogger<ChatWebSocketMiddleware> logger,
            IServiceProvider serviceProvider)
        {
            _next = next;
            _manager = manager;
            _logger = logger;
            _serviceProvider = serviceProvider;
            
        }

        public async Task InvokeAsync(HttpContext context)
        {
            if (context.Request.Path == "/chathub" && context.WebSockets.IsWebSocketRequest)
            {
                context.Response.StatusCode = StatusCodes.Status410Gone;
                await context.Response.WriteAsync("WebSocket chat is disabled. Use FCM.");
                    return;
            }
            else
            {
                await _next(context);
            }
        }

        private async Task Receive(WebSocket socket, Guid userId)
        {
            await Task.CompletedTask;
        }

        private async Task HandleTypingAsync(Guid userId, JsonElement data)
        {
            await Task.CompletedTask;
        }

        private async Task HandlePresenceAsync(Guid userId, JsonElement data)
        {
            await Task.CompletedTask;
        }

        private async Task HandleMarkAsReadAsync(Guid userId, JsonElement data)
        {
            await Task.CompletedTask;
        }
    }
} 