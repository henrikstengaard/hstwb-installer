namespace HstWbInstaller.Imager.GuiApp.Services
{
    using System;
    using System.Threading;
    using System.Threading.Tasks;
    using Core.Models.BackgroundTasks;
    using Microsoft.Extensions.Hosting;
    using Microsoft.Extensions.Logging;

    public class QueuedHostedService : BackgroundService
    {
        private readonly IActiveBackgroundTaskList activeTaskList;
        private readonly ILogger<QueuedHostedService> logger;

        public QueuedHostedService(IBackgroundTaskQueue taskQueue,
            IActiveBackgroundTaskList activeTaskList,
            ILogger<QueuedHostedService> logger)
        {
            TaskQueue = taskQueue;
            this.activeTaskList = activeTaskList;
            this.logger = logger;
        }

        public IBackgroundTaskQueue TaskQueue { get; }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            await BackgroundProcessing(stoppingToken);
        }

        private async Task BackgroundProcessing(CancellationToken stoppingToken)
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                logger.LogDebug("Dequeuing background task");
                
                var queuedBackgroundTask =
                    await TaskQueue.DequeueAsync(stoppingToken);

                var workItemTokenSource = new CancellationTokenSource();
                using CancellationTokenSource linkedTokenSource =
                    CancellationTokenSource.CreateLinkedTokenSource(stoppingToken, workItemTokenSource.Token);

                try
                {
                    activeTaskList.Add(new ActiveBackgroundWorkItem
                    {
                        TokenSource = linkedTokenSource
                    });

                    logger.LogDebug($"Running background task '{queuedBackgroundTask.BackgroundTask.GetType().FullName}'");
                    
                    await queuedBackgroundTask.WorkItem(new BackgroundTaskContext(linkedTokenSource.Token,
                        queuedBackgroundTask.BackgroundTask));
                }
                catch (OperationCanceledException e)
                {
                    logger.LogError(e,
                        "OperationCanceledException");
                }
                catch (Exception ex)
                {
                    logger.LogError(ex,
                        "Error occurred executing {WorkItem}.", nameof(queuedBackgroundTask));
                }

                activeTaskList.Reset();
            }
        }

        public override async Task StopAsync(CancellationToken stoppingToken)
        {
            logger.LogInformation("Queued Hosted Service is stopping.");

            await base.StopAsync(stoppingToken);
        }
    }
}