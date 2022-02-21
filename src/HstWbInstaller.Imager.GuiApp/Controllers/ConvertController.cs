namespace HstWbInstaller.Imager.GuiApp.Controllers
{
    using System;
    using System.Threading.Tasks;
    using Core;
    using Core.Commands;
    using Hubs;
    using Microsoft.AspNetCore.Mvc;
    using Microsoft.AspNetCore.SignalR;
    using Models;
    using Models.BackgroundTasks;
    using Models.Requests;
    using Services;

    [ApiController]
    [Route("convert")]
    public class ConvertController : ControllerBase
    {
        private readonly IHubContext<ProgressHub> progressHubContext;
        private readonly IBackgroundTaskQueue backgroundTaskQueue;

        public ConvertController(IHubContext<ProgressHub> progressHubContext,
            IBackgroundTaskQueue backgroundTaskQueue)
        {
            this.progressHubContext = progressHubContext;
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
            
            var physicalDriveManager = PhysicalDriveManager.Create();
            var physicalDrives = await physicalDriveManager.GetPhysicalDrives();

            var commandHelper = new CommandHelper();
            var convertCommand =
                new ConvertCommand(commandHelper, physicalDrives, convertBackgroundTask.SourcePath, convertBackgroundTask.DestinationPath);
            convertCommand.DataProcessed += async (_, args) =>
            {
                await progressHubContext.Clients.All.SendAsync("UpdateProgress", new Progress
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
                throw new Exception(result.Error.Message);
            }
            
            await progressHubContext.Clients.All.SendAsync("UpdateProgress", new Progress
            {
                Title = convertBackgroundTask.Title,
                IsComplete = true,
                PercentComplete = 100
            }, context.Token);
        }
    }
}