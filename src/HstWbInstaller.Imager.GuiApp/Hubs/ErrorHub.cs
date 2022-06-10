namespace HstWbInstaller.Imager.GuiApp.Hubs
{
    using System.Threading.Tasks;
    using Core.Models;
    using Core.Models.BackgroundTasks;
    using Microsoft.AspNetCore.SignalR;

    public class ErrorHub : Hub
    {
        [HubMethodName(Constants.HubMethodNames.UpdateError)]
        public async Task UpdateError(Error error)
        {
            await Clients.Others.SendAsync(Constants.HubMethodNames.UpdateError, error);
        }
    }
}