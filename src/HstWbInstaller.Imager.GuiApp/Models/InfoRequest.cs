namespace HstWbInstaller.Imager.GuiApp.Models
{
    using System.ComponentModel.DataAnnotations;

    public class InfoRequest
    {
        [Required] public string Path { get; set; }
    }
}