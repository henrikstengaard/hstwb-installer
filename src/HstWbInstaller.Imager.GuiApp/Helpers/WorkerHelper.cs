namespace HstWbInstaller.Imager.GuiApp.Helpers
{
    using System.IO;
    using Core.Helpers;

    public static class WorkerHelper
    {
        public static string GetWorkerFileName()
        {
            var executingFile = ApplicationDataHelper.GetExecutingFile();
            return Path.GetExtension(executingFile) switch
            {
                ".dll" => $"{Path.GetFileNameWithoutExtension(executingFile)}.exe",
                _ => Path.GetFileName(executingFile)
            };
        }
    }
}