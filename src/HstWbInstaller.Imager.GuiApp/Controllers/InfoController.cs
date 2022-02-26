namespace HstWbInstaller.Imager.GuiApp.Controllers
{
    using System.Threading;
    using System.Threading.Tasks;
    using Core;
    using Core.Commands;
    using Core.Helpers;
    using Extensions;
    using Hubs;
    using Microsoft.AspNetCore.Mvc;
    using Microsoft.AspNetCore.SignalR;
    using Models;
    using Models.Requests;

    [ApiController]
    [Route("api/info")]
    public class InfoController : ControllerBase
    {
        private readonly AppState appState;
        private readonly IHubContext<ErrorHub> errorHubContext;

        public InfoController(AppState appState, IHubContext<ErrorHub> errorHubContext)
        {
            this.appState = appState;
            this.errorHubContext = errorHubContext;
        }

        [HttpPost]
        public async Task<IActionResult> Post(InfoRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            if (appState.UseFake && request.Path == FakeHelper.Path)
            {
                return Ok(FakeHelper.CreateFakeMediaInfo().ToViewModel());
            }
            
            var physicalDriveManager = PhysicalDriveManager.Create();
            var physicalDrives = await physicalDriveManager.GetPhysicalDrives();
            
            var commandHelper = new CommandHelper();
            var infoCommand = new InfoCommand(commandHelper, physicalDrives, request.Path);
            var cancellationTokenSource = new CancellationTokenSource();

            MediaInfo mediaInfo = null;            
            infoCommand.DiskInfoRead += (_, args) =>
            {
                mediaInfo = args.MediaInfo;
            };
            
            var result = await infoCommand.Execute(cancellationTokenSource.Token);
            if (result.IsFaulted)
            {
                await errorHubContext.SendError(result.Error.Message, cancellationTokenSource.Token);
                return BadRequest();
            }
            
            return Ok(mediaInfo?.ToViewModel());
        }
    }
}