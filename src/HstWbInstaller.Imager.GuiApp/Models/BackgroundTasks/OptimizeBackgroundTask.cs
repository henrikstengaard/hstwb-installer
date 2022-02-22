namespace HstWbInstaller.Imager.GuiApp.Models.BackgroundTasks
{
    using System.Threading;
    using Services;

    public class OptimizeBackgroundTask : IBackgroundTask
    {
        public CancellationToken Token { get; set; }
        public string Title { get; set; }
        public string Path { get; set; }
    }
}