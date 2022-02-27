namespace HstWbInstaller.Imager.GuiApp.Controllers
{
    using System.Threading.Tasks;
    using ElectronNET.API;
    using Helpers;
    using Microsoft.AspNetCore.Mvc;
    using Models.Requests;

    [ApiController]
    [Route("api/license")]
    public class LicenseController : ControllerBase
    {
        [HttpPost]
        public async Task<IActionResult> Post(LicenseRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            if (HybridSupport.IsElectronActive && !request.LicenseAgreed)
            {
                Electron.App.Exit();
            }

            await ApplicationDataHelper.AgreeLicense(GetType().Assembly, "HstWB Imager", request.LicenseAgreed);
            
            return Ok();
        }
    }
}