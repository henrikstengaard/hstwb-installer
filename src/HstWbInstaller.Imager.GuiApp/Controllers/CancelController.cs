namespace HstWbInstaller.Imager.GuiApp.Controllers
{
    using Microsoft.AspNetCore.Mvc;
    using Services;

    /// <summary>
    /// cancel controller to cancel active background task list
    /// </summary>
    [ApiController]
    [Route("api/cancel")]
    public class CancelController : ControllerBase
    {
        private readonly IActiveBackgroundTaskList activeBackgroundTaskList;

        public CancelController(IActiveBackgroundTaskList activeBackgroundTaskList)
        {
            this.activeBackgroundTaskList = activeBackgroundTaskList;
        }

        [HttpPost]
        public IActionResult Post()
        {
            this.activeBackgroundTaskList.CancelAll();
            return Ok();
        }
    }
}