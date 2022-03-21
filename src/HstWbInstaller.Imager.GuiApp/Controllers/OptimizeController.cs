namespace HstWbInstaller.Imager.GuiApp.Controllers
{
    using System.Threading.Tasks;
    using BackgroundTasks;
    using Core.Models.BackgroundTasks;
    using Hubs;
    using Microsoft.AspNetCore.Mvc;
    using Microsoft.AspNetCore.SignalR;
    using Microsoft.Extensions.Logging;
    using Models.Requests;
    using Services;

    [ApiController]
    [Route("api/optimize")]
    public class OptimizeController : ControllerBase
    {
        private readonly ILoggerFactory loggerFactory;
        private readonly IHubContext<ProgressHub> progressHubContext;
        private readonly IBackgroundTaskQueue backgroundTaskQueue;

        public OptimizeController(ILoggerFactory loggerFactory, IHubContext<ProgressHub> progressHubContext,
            IBackgroundTaskQueue backgroundTaskQueue)
        {
            this.loggerFactory = loggerFactory;
            this.progressHubContext = progressHubContext;
            this.backgroundTaskQueue = backgroundTaskQueue;
        }
        
        [HttpPost]
        public async Task<IActionResult> Post(OptimizeRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }
            
            var task = new OptimizeBackgroundTask
            {
                Title = request.Title,
                Path = request.Path
            };
            var handler = new OptimizeBackgroundTaskHandler(loggerFactory, progressHubContext);
            await backgroundTaskQueue.QueueBackgroundWorkItemAsync(handler.Handle, task);
            
            return Ok();            
        }
    }
}