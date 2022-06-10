namespace HstWbInstaller.Imager.Core.Models.BackgroundTasks
{
    using System.Threading;

    public class OptimizeBackgroundTask : IBackgroundTask
    {
        public string Title { get; set; }
        public string Path { get; set; }
        public CancellationToken Token { get; set; }
    }
}