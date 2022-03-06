namespace HstWbInstaller.Imager.GuiApp.Services
{
    using System.Threading;
    using Core.Models.BackgroundTasks;

    public class BackgroundTask : IBackgroundTask
    {
        public CancellationToken Token { get; set; }
    }
}