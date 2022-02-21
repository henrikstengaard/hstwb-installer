namespace HstWbInstaller.Imager.GuiApp.Controllers
{
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Threading;
    using System.Threading.Tasks;
    using Core;
    using Core.Commands;
    using Core.Helpers;
    using Extensions;
    using Microsoft.AspNetCore.Mvc;
    using Models;

    [ApiController]
    [Route("list")]
    public class ListController : ControllerBase
    {
        private readonly AppState appState;

        public ListController(AppState appState)
        {
            this.appState = appState;
        }

        [HttpGet]
        public async Task<IActionResult> Get()
        {
            var physicalDriveManager = PhysicalDriveManager.Create();
            var physicalDrives = await physicalDriveManager.GetPhysicalDrives();

            var commandHelper = new CommandHelper();
            var listCommand = new ListCommand(commandHelper, physicalDrives);
            var cancellationTokenSource = new CancellationTokenSource();
            
            IEnumerable<MediaInfo> mediaInfos = null;
            listCommand.ListRead += (sender, args) => { mediaInfos = args.MediaInfos; };

            var result = await listCommand.Execute(cancellationTokenSource.Token);
            if (result.IsFaulted)
            {
                throw new Exception(result.Error.Message);
            }

            if (appState.UseFake)
            {
                mediaInfos = mediaInfos.Concat(new[] { FakeHelper.CreateFakeMediaInfo() });
            }
            
            return Ok(mediaInfos.Select(x => x.ToViewModel()));
        }
    }
}