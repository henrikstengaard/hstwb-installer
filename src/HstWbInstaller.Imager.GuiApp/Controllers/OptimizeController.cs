namespace HstWbInstaller.Imager.GuiApp.Controllers
{
    using System.Threading.Tasks;
    using Core.Models.BackgroundTasks;
    using Microsoft.AspNetCore.Mvc;
    using Models.Requests;
    using Services;

    [ApiController]
    [Route("api/optimize")]
    public class OptimizeController : ControllerBase
    {
        private readonly WorkerService workerService;

        public OptimizeController(WorkerService workerService)
        {
            this.workerService = workerService;
        }
        
        [HttpPost]
        public async Task<IActionResult> Post(OptimizeRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }
            
            await workerService.EnqueueAsync(new OptimizeBackgroundTask
            {
                Title = request.Title,
                Path = request.Path
            });
            
            return Ok();            
        }
    }
}