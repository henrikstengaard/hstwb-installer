namespace HstWbInstaller.Imager.GuiApp.BackgroundTasks
{
    using System.Threading.Tasks;
    using Core.Models.BackgroundTasks;

    public interface IBackgroundTaskHandler
    {
        ValueTask Handle(IBackgroundTaskContext backgroundTaskContext);
    }
}