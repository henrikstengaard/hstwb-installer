namespace HstWbInstaller.Imager.GuiApp.Services
{
    using System;
    using System.Threading;
    using System.Threading.Channels;
    using System.Threading.Tasks;
    using Core.Models.BackgroundTasks;

    public class BackgroundTaskQueue : IBackgroundTaskQueue
    {
        private readonly Channel<QueuedBackgroundTask> queue;

        public BackgroundTaskQueue(int capacity)
        {
            // Capacity should be set based on the expected application load and
            // number of concurrent threads accessing the queue.            
            // BoundedChannelFullMode.Wait will cause calls to WriteAsync() to return a task,
            // which completes only when space became available. This leads to backpressure,
            // in case too many publishers/calls start accumulating.
            var options = new BoundedChannelOptions(capacity)
            {
                FullMode = BoundedChannelFullMode.Wait
            };
            queue = Channel.CreateBounded<QueuedBackgroundTask>(options);
        }

        public async ValueTask QueueBackgroundWorkItemAsync(
            Func<IBackgroundTaskContext, ValueTask> workItem, IBackgroundTask backgroundTask = null)
        {
            if (workItem == null)
            {
                throw new ArgumentNullException(nameof(workItem));
            }

            await queue.Writer.WriteAsync(new QueuedBackgroundTask(workItem, backgroundTask));
        }

        public async ValueTask<QueuedBackgroundTask> DequeueAsync(
            CancellationToken cancellationToken) =>
            await queue.Reader.ReadAsync(cancellationToken);
    }
}