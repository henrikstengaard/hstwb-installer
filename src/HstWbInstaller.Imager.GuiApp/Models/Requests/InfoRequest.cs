namespace HstWbInstaller.Imager.GuiApp.Models.Requests
{
    using System.ComponentModel.DataAnnotations;

    public class InfoRequest
    {
        [Required] 
        public string Path { get; set; }
    }
}