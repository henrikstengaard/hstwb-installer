namespace HstWbInstaller.Imager.GuiApp.Controllers
{
    using System.Threading.Tasks;
    using Core.Helpers;
    using Core.Models;
    using Microsoft.AspNetCore.Mvc;
    using Models;

    [ApiController]
    [Route("api/settings")]
    public class SettingsController : ControllerBase
    {
        private readonly AppState appState;

        public SettingsController(AppState appState)
        {
            this.appState = appState;
        }

        [HttpPost]
        public async Task<IActionResult> Post(Settings request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            appState.Settings = request;
            await ApplicationDataHelper.WriteSettings(Constants.AppName, request);

            return Ok();
        }
    }
}