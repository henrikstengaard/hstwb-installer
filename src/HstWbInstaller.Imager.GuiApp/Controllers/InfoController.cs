namespace HstWbInstaller.Imager.GuiApp.Controllers
{
    using System;
    using System.Threading;
    using System.Threading.Tasks;
    using Core;
    using Core.Commands;
    using Extensions;
    using Microsoft.AspNetCore.Mvc;
    using Models;

    [ApiController]
    [Route("info")]
    public class InfoController : ControllerBase
    {
        [HttpPost]
        public async Task<IActionResult> Post(InfoRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
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
                throw new Exception(result.Error.Message);
            }
            
            return Ok(mediaInfo?.ToViewModel());
        }
    }
}