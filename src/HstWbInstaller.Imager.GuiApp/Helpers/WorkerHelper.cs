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
            if (!OperatingSystem.IsWindows())
            {
                return Path.GetFileName(executingFile);
            }
            
            return Path.GetExtension(executingFile) switch
            {
                ".dll" => $"{Path.GetFileNameWithoutExtension(executingFile)}.exe",
                _ => Path.GetFileName(executingFile)
            };
        }
    }
}