namespace HstWbInstaller.Imager.GuiApp.Controllers
{
    using System.Threading.Tasks;
    using Core.Models.BackgroundTasks;
    using Microsoft.AspNetCore.Mvc;
    using Models.Requests;
    using Services;

    [ApiController]
    [Route("api/info")]
    public class InfoController : ControllerBase
    {
        private readonly WorkerService workerService;

        public InfoController(WorkerService workerService)
        {
            this.workerService = workerService;
        }
        
        [HttpPost]
        public async Task<IActionResult> Post(InfoRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            await workerService.EnqueueAsync(new InfoBackgroundTask
            {
                Path = request.Path
            });

            return Ok();
        }
    }
}