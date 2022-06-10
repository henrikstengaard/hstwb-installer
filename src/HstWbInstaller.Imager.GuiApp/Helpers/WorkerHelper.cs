namespace HstWbInstaller.Imager.GuiApp.Helpers
{
    using System;
    using System.IO;
    using System.Linq;

    public static class WorkerHelper
    {
        public static string GetExecutingFile()
        {
            return Environment.GetCommandLineArgs().FirstOrDefault();
        }

        public static string GetWorkerFileName(string executingFile)
        {
            return Path.GetExtension(executingFile) switch
            {
                ".dll" => string.Concat(Path.GetFileNameWithoutExtension(executingFile),
                    OperatingSystem.IsWindows() ? ".exe" : string.Empty),
                _ => Path.GetFileName(executingFile)
            };
        }
    }
}