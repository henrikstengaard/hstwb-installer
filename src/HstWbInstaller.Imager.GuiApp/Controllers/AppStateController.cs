namespace HstWbInstaller.Imager.GuiApp.Controllers
{
    using Microsoft.AspNetCore.Mvc;
    using Models;

    /// <summary>
    /// get app state
    /// </summary>
    [ApiController]
    [Route("api/app-state")]
    public class AppStateController : ControllerBase
    {
        private readonly AppState appState;

        public AppStateController(AppState appState)
        {
            this.appState = appState;
        }

        [HttpGet]
        public IActionResult Get()
        {
            return Ok(appState);
        }
    }
}