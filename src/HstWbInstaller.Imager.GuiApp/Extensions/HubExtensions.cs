namespace HstWbInstaller.Imager.GuiApp.Extensions
{
    using System.Threading;
    using System.Threading.Tasks;
    using Microsoft.AspNetCore.SignalR;
    using Models;

    public static class HubExtensions
    {
        public static async Task SendProgress<THub>(this IHubContext<THub> hubContext, 
            Progress progress, CancellationToken? token = null) where THub : Hub
        {
            await hubContext.Clients.All.SendAsync("UpdateProgress", progress, token);
        }
        
        public static async Task SendError<THub>(this IHubContext<THub> hubContext, 
            string message, CancellationToken? token = null) where THub : Hub
        {
            await hubContext.Clients.All.SendAsync("UpdateError", new ErrorViewModel
            {
                Message = message
            }, token);
        }
    }
}