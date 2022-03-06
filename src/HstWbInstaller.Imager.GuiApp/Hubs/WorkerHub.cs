namespace HstWbInstaller.Imager.GuiApp.Hubs
{
    using System.Threading.Tasks;
    using Core.Models;
    using Microsoft.AspNetCore.SignalR;
    using Services;
    using BackgroundTask = Core.Models.BackgroundTasks.BackgroundTask;

    public class WorkerHub : Hub
    {
        private readonly WorkerService workerService;

        public WorkerHub(WorkerService workerService)
        {
            this.workerService = workerService;
        }

        [HubMethodName(Constants.HubMethodNames.RunBackgroundTask)]
        public async Task RunBackgroundTask(BackgroundTask backgroundTask)
        {
            await Clients.Others.SendAsync(Constants.HubMethodNames.RunBackgroundTask, backgroundTask);
        }
        
        public override Task OnConnectedAsync()
        {
            this.workerService.SetIsReady(true);
            return base.OnConnectedAsync();
        }
    }
}