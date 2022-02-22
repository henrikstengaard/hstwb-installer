namespace HstWbInstaller.Imager.GuiApp.Models.Requests
{
    using System.ComponentModel.DataAnnotations;

    public class VerifyRequest
    {
        [Required]
        public string Title { get; set; }

        [Required]
        public string SourcePath { get; set; }

        [Required]
        public string DestinationPath { get; set; }
    }
}