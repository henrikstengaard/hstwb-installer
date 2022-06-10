namespace HstWbInstaller.Imager.GuiApp.Services
{
    using System;
    using System.Threading;
    using System.Threading.Tasks;
    using Core.Models.BackgroundTasks;

    public interface IBackgroundTaskQueue
    {
        ValueTask QueueBackgroundWorkItemAsync(Func<IBackgroundTaskContext, ValueTask> workItem, IBackgroundTask backgroundTask = null);

        ValueTask<QueuedBackgroundTask> DequeueAsync(
            CancellationToken cancellationToken);
    }
}