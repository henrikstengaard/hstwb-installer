namespace HstWbInstaller.Imager.GuiApp.Models
{
    using System.Collections.Generic;
    using System.ComponentModel.DataAnnotations;

    public class FileFilterViewModel
    {
        [Required]
        public string Name { get; set; }
        
        [Required]
        public IEnumerable<string> Extensions { get; set; }
    }
}