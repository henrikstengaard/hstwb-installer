namespace HstWbInstaller.Imager.GuiApp.Hubs
{
    using System.Threading.Tasks;
    using Core.Models;
    using Microsoft.AspNetCore.SignalR;
    using Models;

    public class ShowDialogResultHub : Hub
    {
        [HubMethodName(Constants.HubMethodNames.ShowDialogResult)]
        public async Task ShowDialogResult(ShowDialogResult showDialogResult)
        {
            await Clients.Others.SendAsync(Constants.HubMethodNames.ShowDialogResult, showDialogResult);
        }
    }
}