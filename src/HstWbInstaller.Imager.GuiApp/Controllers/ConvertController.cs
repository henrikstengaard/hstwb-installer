namespace HstWbInstaller.Imager.GuiApp.Controllers
{
    using System.Threading.Tasks;
    using Core.Models.BackgroundTasks;
    using Microsoft.AspNetCore.Mvc;
    using Models.Requests;
    using Services;

    [ApiController]
    [Route("api/convert")]
    public class ConvertController : ControllerBase
    {
        private readonly WorkerService workerService;

        public ConvertController(WorkerService workerService)
        {
            this.workerService = workerService;
        }
        
        [HttpPost]
        public async Task<IActionResult> Post(ConvertRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            await workerService.EnqueueAsync(new ConvertBackgroundTask
            {
                Title = request.Title,
                SourcePath = request.SourcePath,
                DestinationPath = request.DestinationPath
            });
            
            return Ok();
        }
    }
}