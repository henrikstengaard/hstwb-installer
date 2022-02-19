namespace HstWbInstaller.Imager.GuiApp.Controllers
{
    using System;
    using System.Threading.Tasks;
    using Hubs;
    using Microsoft.AspNetCore.Mvc;
    using Microsoft.AspNetCore.SignalR;
    using Models;
    using Models.BackgroundTasks;
    using Services;

    [ApiController]
    [Route("read")]
    public class ReadController : ControllerBase
    {
        private readonly IHubContext<ProgressHub> progressHubContext;
        private readonly IBackgroundTaskQueue backgroundTaskQueue;

        public ReadController(IHubContext<ProgressHub> progressHubContext, IBackgroundTaskQueue backgroundTaskQueue)
        {
            this.progressHubContext = progressHubContext;
            this.backgroundTaskQueue = backgroundTaskQueue;
        }

        [HttpPost]
        public async Task<IActionResult> Post(ReadRequest model)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }
            
            await backgroundTaskQueue.QueueBackgroundWorkItemAsync(ReadWorkItem, new ReadBackgroundTask
            {
                Title = model.Title,
                SourcePath = model.SourcePath,
                DestinationPath = model.DestinationPath
            });
            
            return Ok();
        }
        
        private async ValueTask ReadWorkItem(IBackgroundTaskContext context)
        {
            if (context.BackgroundTask is not ReadBackgroundTask readBackgroundTask)
            {
                return;
            }
            
            var counter = 0;

            while (!context.Token.IsCancellationRequested && counter <= 100)
            {
                try
                {
                    await Task.Delay(TimeSpan.FromMilliseconds(300), context.Token);
                }
                catch (OperationCanceledException)
                {
                    // Prevent throwing if the Delay is cancelled
                }

                if (context.Token.IsCancellationRequested)
                {
                    break;
                }

                await progressHubContext.Clients.All.SendAsync("UpdateProgress", new Progress
                {
                    Title = readBackgroundTask.Title,
                    IsComplete = false,
                    PercentComplete = counter
                }, context.Token);
                
                counter++;
            }
            
            await progressHubContext.Clients.All.SendAsync("UpdateProgress", new Progress
            {
                Title = readBackgroundTask.Title,
                IsComplete = true,
                PercentComplete = counter
            }, context.Token);
        }        
    }
}