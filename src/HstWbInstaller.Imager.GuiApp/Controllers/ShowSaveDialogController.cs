namespace HstWbInstaller.Imager.GuiApp.Controllers
{
    using System.Linq;
    using System.Threading.Tasks;
    using ElectronNET.API;
    using Hubs;
    using Microsoft.AspNetCore.Mvc;
    using Microsoft.AspNetCore.SignalR;
    using Models;
    using Models.BackgroundTasks;
    using Services;
    using FileFilter = ElectronNET.API.Entities.FileFilter;

    [ApiController]
    [Route("show-save-dialog")]
    public class ShowSaveDialogController : ControllerBase
    {
        private readonly IBackgroundTaskQueue backgroundTaskQueue;
        private readonly IHubContext<ShowDialogResultHub> showDialogResultContext;

        public ShowSaveDialogController(IBackgroundTaskQueue backgroundTaskQueue, IHubContext<ShowDialogResultHub> showDialogResultContext)
        {
            this.backgroundTaskQueue = backgroundTaskQueue;
            this.showDialogResultContext = showDialogResultContext;
        }


        [HttpPost]
        public async Task<IActionResult> Post(DialogViewModel model)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            await backgroundTaskQueue.QueueBackgroundWorkItemAsync(ShowSaveDialogWorkItem, new ShowDialogBackgroundTask
            {
                Id = model.Id,
                Title = model.Title,
                Path = model.Path,
                FileFilters = model.FileFilters.Select(x => new Models.BackgroundTasks.FileFilter
                {
                    Name = x.Name,
                    Extensions = x.Extensions
                })
            });
            
            return Ok();
        }

        private async ValueTask ShowSaveDialogWorkItem(IBackgroundTaskContext context)
        {
            if (!HybridSupport.IsElectronActive)
            {
                return;
            }
            
            if (context.BackgroundTask is not ShowDialogBackgroundTask showDialogBackgroundTask)
            {
                return;
            }

            var browserWindow = Electron.WindowManager.BrowserWindows.FirstOrDefault();
            if (browserWindow == null)
            {
                return;
            }

            var path = await Electron.Dialog.ShowSaveDialogAsync(browserWindow, new SaveDialogOptions
            {
                Title = showDialogBackgroundTask.Title,
                Filters = showDialogBackgroundTask.FileFilters.Select(x => new FileFilter
                {
                    Name = x.Name,
                    Extensions = x.Extensions.ToArray()
                }).ToArray(),
                DefaultPath = showDialogBackgroundTask.Path
            });
            
            await showDialogResultContext.Clients.All.SendAsync("ShowDialogResult", new ShowDialogResult
            {
                Id = showDialogBackgroundTask.Id,
                IsSuccess = !string.IsNullOrWhiteSpace(path),
                Paths = new []{ path }
            }, context.Token);            
        }
    }
}