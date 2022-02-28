namespace HstWbInstaller.Imager.GuiApp.Controllers
{
    using System.Collections.Generic;
    using System.Linq;
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

    [ApiController]
    [Route("api/list")]
    public class ListController : ControllerBase
    {
        private readonly IHubContext<ErrorHub> errorHubContext;
        private readonly AppState appState;

        public ListController(IHubContext<ErrorHub> errorHubContext, AppState appState)
        {
            this.errorHubContext = errorHubContext;
            this.appState = appState;
        }

        [HttpPost]
        public async Task<IActionResult> Post()
        {
            var physicalDriveManager = PhysicalDriveManager.Create();
            var physicalDrives = await physicalDriveManager.GetPhysicalDrives();

            var commandHelper = new CommandHelper();
            var listCommand = new ListCommand(commandHelper, physicalDrives);
            var cancellationTokenSource = new CancellationTokenSource();
            
            IEnumerable<MediaInfo> mediaInfos = null;
            listCommand.ListRead += (_, args) => { mediaInfos = args.MediaInfos; };

            var result = await listCommand.Execute(cancellationTokenSource.Token);
            if (result.IsFaulted)
            {
                await errorHubContext.SendError(result.Error.Message, cancellationTokenSource.Token);
                return BadRequest();
            }

            if (appState.UseFake)
            {
                mediaInfos = mediaInfos.Concat(new[] { FakeHelper.CreateFakeMediaInfo() });
            }
            
            return Ok(mediaInfos.Select(x => x.ToViewModel()));
        }
    }
}