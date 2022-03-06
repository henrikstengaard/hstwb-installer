namespace HstWbInstaller.Imager.Core.Models.BackgroundTasks
{
    using System.Threading;

    public class BlankBackgroundTask : IBackgroundTask
    {
        public string Title { get; set; }
        public string Path { get; set; }
        public long Size { get; set; }
        public bool CompatibleSize { get; set; }
        public CancellationToken Token { get; set; }
    }
}