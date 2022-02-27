namespace HstWbInstaller.Imager.GuiApp.Controllers
{
    using System;
    using System.Threading;
    using System.Threading.Tasks;
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
    [Route("api/blank")]
    public class BlankController : ControllerBase
    {
        private readonly IHubContext<ProgressHub> progressHubContext;
        private readonly IHubContext<ErrorHub> errorHubContext;
        private readonly IBackgroundTaskQueue backgroundTaskQueue;

        public BlankController(IHubContext<ProgressHub> progressHubContext,
            IHubContext<ErrorHub> errorHubContext, IBackgroundTaskQueue backgroundTaskQueue)
        {
            this.progressHubContext = progressHubContext;
            this.errorHubContext = errorHubContext;
            this.backgroundTaskQueue = backgroundTaskQueue;
        }

        [HttpPost]
        public async Task<IActionResult> Post(BlankRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            await backgroundTaskQueue.QueueBackgroundWorkItemAsync(BlankWorkItem, new BlankBackgroundTask
            {
                Title = request.Title,
                Path = request.Path,
                Size = request.Size,
                CompatibleSize = request.CompatibleSize
            });
            
            return Ok();            
        }

        private async ValueTask BlankWorkItem(IBackgroundTaskContext context)
        {
            if (context.BackgroundTask is not BlankBackgroundTask blankBackgroundTask)
            {
                return;
            }

            try
            {
                var cancellationTokenSource = new CancellationTokenSource();
            
                await progressHubContext.SendProgress(new Progress
                {
                    Title = blankBackgroundTask.Title,
                    IsComplete = false,
                    PercentComplete = 50,
                }, cancellationTokenSource.Token);                

                var commandHelper = new CommandHelper();
                var blankCommand = new BlankCommand(commandHelper, blankBackgroundTask.Path,
                    blankBackgroundTask.CompatibleSize ? Convert.ToInt64(blankBackgroundTask.Size * 0.95) : blankBackgroundTask.Size);

                var result = await blankCommand.Execute(cancellationTokenSource.Token);
                if (result.IsFaulted)
                {
                    await errorHubContext.SendError(result.Error.Message, context.Token);
                    return;
                }

                await Task.Delay(1000, context.Token);
                
                await progressHubContext.SendProgress(new Progress
                {
                    Title = blankBackgroundTask.Title,
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