namespace HstWbInstaller.Imager.GuiApp.Hubs
{
    using System.Collections.Generic;
    using System.Threading.Tasks;
    using Core.Models;
    using Microsoft.AspNetCore.SignalR;
    using Models;

    public class ResultHub : Hub
    {
        [HubMethodName(Constants.HubMethodNames.Info)]
        public async Task Info(MediaInfoViewModel mediaInfo)
        {
            await Clients.Others.SendAsync(Constants.HubMethodNames.Info, mediaInfo);
        }
        
        [HubMethodName(Constants.HubMethodNames.List)]
        public async Task List(IEnumerable<MediaInfoViewModel> mediaInfos)
        {
            await Clients.Others.SendAsync(Constants.HubMethodNames.List, mediaInfos);
        }
    }
}