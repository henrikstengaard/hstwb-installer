namespace HstWbInstaller.Imager.GuiApp.Controllers
{
    using System.Threading.Tasks;
    using Core.Models.BackgroundTasks;
    using Microsoft.AspNetCore.Mvc;
    using Models.Requests;
    using Services;

    [ApiController]
    [Route("api/blank")]
    public class BlankController : ControllerBase
    {
        private readonly WorkerService workerService;

        public BlankController(WorkerService workerService)
        {
            this.workerService = workerService;
        }

        [HttpPost]
        public async Task<IActionResult> Post(BlankRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            await workerService.EnqueueAsync(new BlankBackgroundTask
            {
                Title = request.Title,
                Path = request.Path,
                Size = request.Size,
                CompatibleSize = request.CompatibleSize
            });
            
            return Ok();            
        }
    }
}