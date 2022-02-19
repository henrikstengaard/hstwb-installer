namespace HstWbInstaller.Imager.GuiApp.Services
{
    using System.Threading;

    public interface IBackgroundTask
    {
        CancellationToken Token { get; set; }
    }
}