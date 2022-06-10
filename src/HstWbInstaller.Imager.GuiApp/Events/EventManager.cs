namespace HstWbInstaller.Imager.GuiApp.Events
{
    using System;

    public class EventManager
    {
        public event EventHandler WorkerHubConnected;
        
        private static readonly Lazy<EventManager> instance = new(() => new EventManager(), true);

        private EventManager()
        {
        }
        
        public static EventManager Instance { get { return instance.Value; } }

        public void OnWorkerHubConnected()
        {
            WorkerHubConnected?.Invoke(this, EventArgs.Empty);
        }
    }
}