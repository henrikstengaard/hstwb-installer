namespace HstWbInstaller.Imager.GuiApp.Controllers
{
    using System;
    using System.Diagnostics;
    using System.Globalization;
    using System.Threading.Tasks;
    using Core.Extensions;
    using Hubs;
    using Humanizer;
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

            var stopwatch = new Stopwatch();
            stopwatch.Start();

            var percentComplete = 0;

            var bytesTotal = 100 * 1024 * 1024;
            while (!context.Token.IsCancellationRequested && percentComplete <= 100)
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

                var remainingTime = percentComplete > 0 ? TimeSpan.FromMilliseconds((double)stopwatch.ElapsedMilliseconds / percentComplete *
                                                                              (100 - percentComplete)) : TimeSpan.Zero;

                await progressHubContext.Clients.All.SendAsync("UpdateProgress", new Progress
                {
                    Title = readBackgroundTask.Title,
                    IsComplete = false,
                    PercentComplete = percentComplete,
                    BytesProcessed = percentComplete * 1024 * 1024,
                    BytesRemaining = (100 - percentComplete) * 1024 * 1024,
                    BytesTotal = bytesTotal,
                    MillisecondsElapsed = percentComplete > 0 ? (long)stopwatch.Elapsed.TotalMilliseconds : new long?(),
                    MillisecondsRemaining = percentComplete > 0 ? (long)remainingTime.TotalMilliseconds : new long?(),
                    MillisecondsTotal = percentComplete > 0 ? (long)(stopwatch.Elapsed.TotalMilliseconds + remainingTime.TotalMilliseconds) : new long?()
                }, context.Token);

                percentComplete++;
            }

            await progressHubContext.Clients.All.SendAsync("UpdateProgress", new Progress
            {
                Title = readBackgroundTask.Title,
                IsComplete = true,
                PercentComplete = 100
            }, context.Token);
        }
    }
}