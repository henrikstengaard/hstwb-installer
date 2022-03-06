namespace HstWbInstaller.Imager.GuiApp.Controllers
{
    using System.Threading.Tasks;
    using Extensions;
    using Hubs;
    using Microsoft.AspNetCore.Mvc;
    using Microsoft.AspNetCore.SignalR;
    using Services;

    /// <summary>
    /// cancel controller to cancel active background task list
    /// </summary>
    [ApiController]
    [Route("api/cancel")]
    public class CancelController : ControllerBase
    {
        private readonly IHubContext<WorkerHub> workerHubContext;
        private readonly IActiveBackgroundTaskList activeBackgroundTaskList;

        public CancelController(IHubContext<WorkerHub> workerHubContext, IActiveBackgroundTaskList activeBackgroundTaskList)
        {
            this.workerHubContext = workerHubContext;
            this.activeBackgroundTaskList = activeBackgroundTaskList;
        }

        [HttpPost]
        public async Task<IActionResult> Post()
        {
            this.activeBackgroundTaskList.CancelAll();
            await this.workerHubContext.CancelBackgroundTask();
            return Ok();
        }
    }
}