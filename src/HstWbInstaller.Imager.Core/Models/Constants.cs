namespace HstWbInstaller.Imager.Core.Models
{
    public class Constants
    {
        public const string AppName = "HstWB Imager";
        
        public class HubMethodNames
        {
            public const string UpdateProgress = "UpdateProgress";
            public const string UpdateError = "UpdateError";
            public const string Info = "Info";
            public const string List = "List";
            public const string RunBackgroundTask = "RunBackgroundTask";
            public const string CancelBackgroundTask = "CancelBackgroundTask";
            public const string WorkerReady = "WorkerReady";
            public const string ShowDialogResult = "ShowDialogResult";
        }
    }
}