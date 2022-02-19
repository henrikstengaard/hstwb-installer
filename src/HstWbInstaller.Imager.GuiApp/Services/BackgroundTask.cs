namespace HstWbInstaller.Imager.GuiApp.Services
{
    using System.Threading;

    public class BackgroundTask : IBackgroundTask
    {
        public CancellationToken Token { get; set; }
    }
}