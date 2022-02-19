namespace HstWbInstaller.Imager.GuiApp.Services
{
    using System.Collections.Concurrent;

    public class ActiveBackgroundTaskList : IActiveBackgroundTaskList
    {
        private readonly ConcurrentBag<ActiveBackgroundWorkItem> list;

        public ActiveBackgroundTaskList()
        {
            list = new ConcurrentBag<ActiveBackgroundWorkItem>();
        }

        public void Add(ActiveBackgroundWorkItem activeBackgroundWorkItem)
        {
            list.Add(activeBackgroundWorkItem);
        }

        public void Reset()
        {
            list.Clear();
        }

        public void CancelAll()
        {
            while (list.TryTake(out var activeBackgroundWorkItem))
            {
                activeBackgroundWorkItem.TokenSource.Cancel();
            }
        }
    }
}