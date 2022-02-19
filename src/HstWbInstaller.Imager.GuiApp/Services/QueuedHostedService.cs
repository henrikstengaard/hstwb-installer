namespace HstWbInstaller.Imager.GuiApp.Services
{
    using System;
    using System.Threading;
    using System.Threading.Tasks;
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

                    await queuedBackgroundTask.WorkItem(new BackgroundTaskContext(linkedTokenSource.Token, queuedBackgroundTask.BackgroundTask));
                }
                catch (OperationCanceledException)
                {
                    linkedTokenSource.Token.ThrowIfCancellationRequested();
                }
                catch (Exception ex)
                {
                    logger.LogError(ex,
                        "Error occurred executing {WorkItem}.", nameof(queuedBackgroundTask));
                }
            }

            activeTaskList.Reset();
        }

        public override async Task StopAsync(CancellationToken stoppingToken)
        {
            logger.LogInformation("Queued Hosted Service is stopping.");

            await base.StopAsync(stoppingToken);
        }
    }

    public interface IBackgroundTaskContext
    {
        CancellationToken Token { get; }
        IBackgroundTask BackgroundTask { get; }
    }

    public class BackgroundTaskContext : IBackgroundTaskContext
    {
        public BackgroundTaskContext(CancellationToken token, IBackgroundTask backgroundTask)
        {
            Token = token;
            BackgroundTask = backgroundTask;
        }

        public CancellationToken Token { get; }
        public IBackgroundTask BackgroundTask { get; }
    }
}