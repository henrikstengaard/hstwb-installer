namespace HstWbInstaller.Imager.GuiApp.Models.BackgroundTasks
{
    using System.Collections.Generic;
    using System.Linq;

    public class FileFilter
    {
        public string Name { get; set; }
        public IEnumerable<string> Extensions { get; set; }

        public FileFilter()
        {
            Extensions = Enumerable.Empty<string>();
        }
    }
}