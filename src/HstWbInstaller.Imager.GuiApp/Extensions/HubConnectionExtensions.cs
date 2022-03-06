namespace HstWbInstaller.Imager.GuiApp.Extensions
{
    using System.Collections.Generic;
    using System.Linq;
    using System.Threading;
    using System.Threading.Tasks;
    using Core.Commands;
    using Core.Models;
    using Core.Models.BackgroundTasks;
    using Microsoft.AspNetCore.SignalR.Client;
    using Models;

    public static class HubConnectionExtensions
    {
        public static async Task UpdateProgress(this HubConnection hubConnection,
            Progress progress, CancellationToken token = default)
        {
            await hubConnection.InvokeCoreAsync(Constants.HubMethodNames.UpdateProgress, new object[]
            {
                progress
            }, token);
        }

        public static async Task UpdateError(this HubConnection hubConnection,
            string message, CancellationToken token = default)
        {
            await hubConnection.InvokeCoreAsync(Constants.HubMethodNames.UpdateError, new object[]
            {
                new Error
                {
                    Message = message
                }
            }, token);
        }
        
        public static async Task SendInfoResult(this HubConnection hubConnection,
            MediaInfoViewModel mediaInfo, CancellationToken token = default)
        {
            await hubConnection.InvokeCoreAsync(Constants.HubMethodNames.Info, new object[]
            {
                mediaInfo
            }, token);
        }
        
        public static async Task SendListResult(this HubConnection hubConnection,
            IEnumerable<MediaInfoViewModel> mediaInfos, CancellationToken token = default)
        {
            await hubConnection.InvokeCoreAsync(Constants.HubMethodNames.List, new object[]
            {
                mediaInfos
            }, token);
        }
    }
}