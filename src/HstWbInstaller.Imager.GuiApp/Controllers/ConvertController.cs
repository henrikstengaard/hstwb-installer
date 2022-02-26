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
    [Route("api/convert")]
    public class ConvertController : ControllerBase
    {
        private readonly IHubContext<ProgressHub> progressHubContext;
        private readonly IHubContext<ErrorHub> errorHubContext;
        private readonly IBackgroundTaskQueue backgroundTaskQueue;

        public ConvertController(IHubContext<ProgressHub> progressHubContext,
            IHubContext<ErrorHub> errorHubContext,
            IBackgroundTaskQueue backgroundTaskQueue)
        {
            this.progressHubContext = progressHubContext;
            this.errorHubContext = errorHubContext;
            this.backgroundTaskQueue = backgroundTaskQueue;
        }

        [HttpPost]
        public async Task<IActionResult> Post(ConvertRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            await backgroundTaskQueue.QueueBackgroundWorkItemAsync(ConvertWorkItem, new ConvertBackgroundTask
            {
                Title = request.Title,
                SourcePath = request.SourcePath,
                DestinationPath = request.DestinationPath
            });
            
            return Ok();
        }

        private async ValueTask ConvertWorkItem(IBackgroundTaskContext context)
        {
            if (context.BackgroundTask is not ConvertBackgroundTask convertBackgroundTask)
            {
                return;
            }

            try
            {
                var physicalDriveManager = PhysicalDriveManager.Create();
                var physicalDrives = await physicalDriveManager.GetPhysicalDrives();

                var commandHelper = new CommandHelper();
                var convertCommand =
                    new ConvertCommand(commandHelper, physicalDrives, convertBackgroundTask.SourcePath, convertBackgroundTask.DestinationPath);
                convertCommand.DataProcessed += async (_, args) =>
                {
                    await progressHubContext.SendProgress(new Progress
                    {
                        Title = convertBackgroundTask.Title,
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

                var result = await convertCommand.Execute(context.Token);
                if (result.IsFaulted)
                {
                    await errorHubContext.SendError(result.Error.Message, context.Token);
                    return;
                }
            
                await progressHubContext.SendProgress(new Progress
                {
                    Title = convertBackgroundTask.Title,
                    IsComplete = true,
                    PercentComplete = 100
                }, context.Token);
            }
            catch (Exception e)
            {
                await errorHubContext.SendError(e.Message, context.Token);
            }
        }
    }
}