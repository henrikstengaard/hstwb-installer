namespace HstWbInstaller.Imager.Core.Models.BackgroundTasks
{
    using System.Threading;

    public class ImageFileInfoBackgroundTask : IBackgroundTask
    {
        public string Path { get; set; }
        public CancellationToken Token { get; set; }
    }
}