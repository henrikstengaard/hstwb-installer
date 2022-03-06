namespace HstWbInstaller.Imager.Core.Models.BackgroundTasks
{
    using System.Threading;

    public class ListBackgroundTask : IBackgroundTask
    {
        public CancellationToken Token { get; set; }
    }
}