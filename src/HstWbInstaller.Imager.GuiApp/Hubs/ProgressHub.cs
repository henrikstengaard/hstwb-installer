namespace HstWbInstaller.Imager.GuiApp.Hubs
{
    using System.Threading.Tasks;
    using Core.Models;
    using Core.Models.BackgroundTasks;
    using Microsoft.AspNetCore.SignalR;

    public class ProgressHub : Hub
    {
        [HubMethodName(Constants.HubMethodNames.UpdateProgress)]
        public async Task UpdateProgress(Progress progress)
        {
            await Clients.Others.SendAsync(Constants.HubMethodNames.UpdateProgress, progress);
        }
    }
}