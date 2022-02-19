namespace HstWbInstaller.Imager.GuiApp.Models
{
    using System.Collections.Generic;
    using System.Linq;

    public class ShowDialogResult
    {
        public string Id { get; set; }
        public bool IsSuccess { get; set; }
        public IEnumerable<string> Paths { get; set; }

        public ShowDialogResult()
        {
            Paths = Enumerable.Empty<string>();
        }
    }
}