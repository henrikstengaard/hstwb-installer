namespace HstWbInstaller.Imager.GuiApp.Models.Requests
{
    using System.ComponentModel.DataAnnotations;

    public class OptimizeRequest
    {
        [Required]
        public string Title { get; set; }

        [Required]
        public string Path { get; set; }
        
        [Required]
        public long Size { get; set; }
    }
}