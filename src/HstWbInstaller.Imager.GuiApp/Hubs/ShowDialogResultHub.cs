namespace HstWbInstaller.Imager.GuiApp.Hubs
{
    using System.Threading.Tasks;
    using Microsoft.AspNetCore.SignalR;
    using Models;

    public class ShowDialogResultHub : Hub
    {
        public async Task SendShowDialogResult(ShowDialogResult showDialogResult)
        {
            await Clients.All.SendAsync("ShowDialogResult", showDialogResult);
        }        
    }
}