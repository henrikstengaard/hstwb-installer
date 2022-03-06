namespace HstWbInstaller.Imager.GuiApp.Services
{
    using System;
    using System.Linq;
    using System.Threading;
    using System.Threading.Tasks;
    using BackgroundTasks;
    using Extensions;
    using Hubs;
    using Microsoft.AspNetCore.SignalR;
    using Microsoft.Extensions.DependencyInjection;
    using Microsoft.Extensions.Hosting;
    using Microsoft.Extensions.Logging;

    public class BackgroundTaskService : BackgroundService
    {
        private readonly ILogger<BackgroundTaskService> logger;
        private readonly IHubContext<WorkerHub> workerHubContext;
        private readonly WorkerService workerService;

        public BackgroundTaskService(
            ILoggerFactory loggerFactory,
            IServiceScopeFactory serviceScopeFactory)
        {
            logger = loggerFactory.CreateLogger<BackgroundTaskService>();
            using var scope = serviceScopeFactory.CreateScope();
            workerService = scope.ServiceProvider.GetService<WorkerService>();
            workerHubContext = scope.ServiceProvider.GetService<IHubContext<WorkerHub>>();
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            logger.LogDebug("Starting background task service");

            while (!stoppingToken.IsCancellationRequested)
            {
                await Task.Delay(TimeSpan.FromMilliseconds(200), stoppingToken);

                if (!workerService.IsReady())
                {
                    continue;
                }
                
                try
                {
                    var backgroundTask = (await workerService.DequeueAsync()).LastOrDefault();

                    if (!workerService.IsReady() || backgroundTask == null)
                    {
                        continue;
                    }

                    await workerHubContext.RunBackgroundTask(backgroundTask, token: stoppingToken);
                }
                catch (Exception e)
                {
                    logger.LogError(e, $"An error occurred");
                }
            }
        }
    }
}