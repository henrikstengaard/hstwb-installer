namespace HstWbInstaller.Imager.GuiApp.Extensions
{
    using System.Threading;
    using System.Threading.Tasks;
    using Core.Models;
    using Core.Models.BackgroundTasks;
    using Microsoft.AspNetCore.SignalR;
    using Models;
    using BackgroundTask = Core.Models.BackgroundTasks.BackgroundTask;

    public static class HubExtensions
    {
        public static async Task SendProgress<THub>(this IHubContext<THub> hubContext, 
            Progress progress, CancellationToken token = default) where THub : Hub
        {
            await hubContext.Clients.All.SendAsync(Constants.HubMethodNames.UpdateProgress, progress, token);
        }
        
        public static async Task SendError<THub>(this IHubContext<THub> hubContext, 
            string message, CancellationToken token = default) where THub : Hub
        {
            await hubContext.Clients.All.SendAsync(Constants.HubMethodNames.UpdateError, new Error
            {
                Message = message
            }, token);
        }

        public static async Task SendInfoResult<THub>(this IHubContext<THub> hubContext, 
            MediaInfoViewModel mediaInfo, CancellationToken token = default) where THub : Hub
        {
            await hubContext.Clients.All.SendAsync(Constants.HubMethodNames.Info, mediaInfo, token);
        }
        
        public static async Task RunBackgroundTask<THub>(this IHubContext<THub> hubContext, 
            BackgroundTask backgroundTask, CancellationToken token = default) where THub : Hub
        {
            await hubContext.Clients.All.SendAsync(Constants.HubMethodNames.RunBackgroundTask, backgroundTask, token);
        }
        
        public static async Task CancelBackgroundTask<THub>(this IHubContext<THub> hubContext, 
            CancellationToken token = default) where THub : Hub
        {
            await hubContext.Clients.All.SendAsync(Constants.HubMethodNames.CancelBackgroundTask, token);
        }
    }
}