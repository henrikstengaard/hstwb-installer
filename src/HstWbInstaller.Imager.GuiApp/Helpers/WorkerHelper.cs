namespace HstWbInstaller.Imager.GuiApp.Helpers
{
    using System.IO;
    using Core.Helpers;

    public static class WorkerHelper
    {
        public static string GetWorkerFileName()
        {
            var executingFile = ApplicationDataHelper.GetExecutingFile();
            return $"{Path.GetFileNameWithoutExtension(executingFile)}.exe";
        }
    }
}