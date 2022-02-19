namespace HstWbInstaller.Imager.GuiApp.Models
{
    using System.Collections.Generic;
    using System.ComponentModel.DataAnnotations;
    using System.Linq;

    public class DialogViewModel
    {
        [Required]
        public string Id { get; set; }

        [Required]
        public string Title { get; set; }
        
        public string Path { get; set; }

        public IEnumerable<FileFilterViewModel> FileFilters { get; set; }

        public DialogViewModel()
        {
            FileFilters = Enumerable.Empty<FileFilterViewModel>();
        }
    }
}