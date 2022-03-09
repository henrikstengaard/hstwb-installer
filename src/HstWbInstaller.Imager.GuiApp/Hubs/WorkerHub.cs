namespace HstWbInstaller.Imager.GuiApp.Hubs
{
    using System.Threading.Tasks;
    using Core.Models;
    using Microsoft.AspNetCore.SignalR;
    using Microsoft.Extensions.Logging;
    using Services;
    using BackgroundTask = Core.Models.BackgroundTasks.BackgroundTask;

    public class WorkerHub : Hub
    {
        private readonly ILogger<WorkerHub> logger; 
        private readonly WorkerService workerService;

        public WorkerHub(ILogger<WorkerHub> logger, WorkerService workerService)
        {
            this.logger = logger;
            this.workerService = workerService;
        }

        [HubMethodName(Constants.HubMethodNames.RunBackgroundTask)]
        public async Task RunBackgroundTask(BackgroundTask backgroundTask)
        {
            await Clients.Others.SendAsync(Constants.HubMethodNames.RunBackgroundTask, backgroundTask);
        }
        
        public override Task OnConnectedAsync()
        {
            logger.LogDebug("Worker connected");
            this.workerService.SetIsReady(true);
            return base.OnConnectedAsync();
        }
    }
}