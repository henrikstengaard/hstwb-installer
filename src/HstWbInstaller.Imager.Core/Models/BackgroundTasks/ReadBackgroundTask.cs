namespace HstWbInstaller.Imager.Core.Models.BackgroundTasks
{
    using System.Threading;

    public class ReadBackgroundTask : IBackgroundTask
    {
        public string Title { get; set; }
        public string SourcePath { get; set; }
        public string DestinationPath { get; set; }
        public CancellationToken Token { get; set; }
    }
    
    
}