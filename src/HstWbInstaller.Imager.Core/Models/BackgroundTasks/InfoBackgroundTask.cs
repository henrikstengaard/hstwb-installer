namespace HstWbInstaller.Imager.Core.Models.BackgroundTasks
{
    using System.Threading;

    public class InfoBackgroundTask : IBackgroundTask
    {
        public string Path { get; set; }
        public CancellationToken Token { get; set; }
    }
}