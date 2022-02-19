namespace HstWbInstaller.Imager.GuiApp.Models.BackgroundTasks
{
    using System.Collections.Generic;
    using System.Linq;
    using System.Threading;
    using Services;

    public class ShowDialogBackgroundTask : IBackgroundTask
    {
        public CancellationToken Token { get; set; }
        public string Id { get; set; }
        public string Title { get; set; }
        public string Path { get; set; }
        public IEnumerable<FileFilter> FileFilters { get; set; }

        public ShowDialogBackgroundTask()
        {
            FileFilters = Enumerable.Empty<FileFilter>();
        }
    }
}