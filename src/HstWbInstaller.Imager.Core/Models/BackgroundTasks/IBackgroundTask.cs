namespace HstWbInstaller.Imager.Core.Models.BackgroundTasks
{
    using System.Threading;

    public interface IBackgroundTask
    {
        CancellationToken Token { get; set; }
    }
    
    public interface IBackgroundTaskContext
    {
        CancellationToken Token { get; }
        IBackgroundTask BackgroundTask { get; }
    }

    public class BackgroundTaskContext : IBackgroundTaskContext
    {
        public BackgroundTaskContext(CancellationToken token, IBackgroundTask backgroundTask)
        {
            Token = token;
            BackgroundTask = backgroundTask;
        }

        public CancellationToken Token { get; }
        public IBackgroundTask BackgroundTask { get; }
    }
}