namespace HstWbInstaller.Imager.GuiApp.Controllers
{
    using System;
    using System.Threading.Tasks;
    using Core;
    using Core.Commands;
    using Extensions;
    using Hubs;
    using Microsoft.AspNetCore.Mvc;
    using Microsoft.AspNetCore.SignalR;
    using Models;
    using Models.BackgroundTasks;
    using Models.Requests;
    using Services;

    [ApiController]
    [Route("api/write")]
    public class WriteController : ControllerBase
    {
        private readonly IHubContext<ProgressHub> progressHubContext;
        private readonly IBackgroundTaskQueue backgroundTaskQueue;
        private readonly PhysicalDriveManagerFactory physicalDriveManagerFactory;

        public WriteController(IHubContext<ProgressHub> progressHubContext,
            IBackgroundTaskQueue backgroundTaskQueue, PhysicalDriveManagerFactory physicalDriveManagerFactory)
        {
            this.progressHubContext = progressHubContext;
            this.backgroundTaskQueue = backgroundTaskQueue;
            this.physicalDriveManagerFactory = physicalDriveManagerFactory;
        }
        
        [HttpPost]
        public async Task<IActionResult> Post(WriteRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            await backgroundTaskQueue.QueueBackgroundWorkItemAsync(WriteWorkItem, new WriteBackgroundTask
            {
                Title = request.Title,
                SourcePath = request.SourcePath,
                DestinationPath = request.DestinationPath
            });
            
            return Ok();
        }

        private async ValueTask WriteWorkItem(IBackgroundTaskContext context)
        {
            if (context.BackgroundTask is not WriteBackgroundTask writeBackgroundTask)
            {
                return;
            }

            try
            {
                var physicalDriveManager = physicalDriveManagerFactory.Create();
                var physicalDrives = await physicalDriveManager.GetPhysicalDrives();

                var commandHelper = new CommandHelper();
                var writeCommand =
                    new WriteCommand(commandHelper, physicalDrives, writeBackgroundTask.SourcePath, writeBackgroundTask.DestinationPath);
                writeCommand.DataProcessed += async (_, args) =>
                {
                    await progressHubContext.SendProgress(new Progress
                    {
                        Title = writeBackgroundTask.Title,
                        IsComplete = false,
                        PercentComplete = args.PercentComplete,
                        BytesProcessed = args.BytesProcessed,
                        BytesRemaining = args.BytesRemaining,
                        BytesTotal = args.BytesTotal,
                        MillisecondsElapsed = args.PercentComplete > 0 ? (long)args.TimeElapsed.TotalMilliseconds : new long?(),
                        MillisecondsRemaining = args.PercentComplete > 0 ? (long)args.TimeRemaining.TotalMilliseconds : new long?(),
                        MillisecondsTotal = args.PercentComplete > 0 ? (long)args.TimeTotal.TotalMilliseconds : new long?()
                    }, context.Token);                
                };

                var result = await writeCommand.Execute(context.Token);

                await progressHubContext.SendProgress(new Progress
                {
                    Title = writeBackgroundTask.Title,
                    IsComplete = true,
                    HasError = result.IsFaulted,
                    ErrorMessage = result.IsFaulted ? result.Error.Message : null,
                    PercentComplete = 100
                }, context.Token);
            }
            catch (Exception e)
            {
                await progressHubContext.SendProgress(new Progress
                {
                    Title = writeBackgroundTask.Title,
                    IsComplete = true,
                    HasError = true,
                    ErrorMessage = e.Message,
                    PercentComplete = 100
                }, context.Token);
            }
        }
    }
}