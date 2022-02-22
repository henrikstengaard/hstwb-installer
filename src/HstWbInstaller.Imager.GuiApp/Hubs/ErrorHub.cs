namespace HstWbInstaller.Imager.GuiApp.Hubs
{
    using System.Threading.Tasks;
    using Microsoft.AspNetCore.SignalR;
    using Models;

    public class ErrorHub : Hub
    {
        public async Task SendError(ErrorViewModel errorViewModel)
        {
            await Clients.All.SendAsync("UpdateError", errorViewModel);
        }        
    }
}