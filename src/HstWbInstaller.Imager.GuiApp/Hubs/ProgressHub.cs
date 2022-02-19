namespace HstWbInstaller.Imager.GuiApp.Hubs
{
    using System.Threading.Tasks;
    using Microsoft.AspNetCore.SignalR;
    using Models;

    public class ProgressHub : Hub
    {
        public async Task SendProgress(Progress progress)
        {
            await Clients.All.SendAsync("UpdateProgress", progress);
        }        
    }
}