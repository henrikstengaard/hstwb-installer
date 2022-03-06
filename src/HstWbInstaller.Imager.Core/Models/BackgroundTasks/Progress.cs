namespace HstWbInstaller.Imager.Core.Models.BackgroundTasks
{
    public class Progress
    {
        public string Title { get; set; }
        public bool IsComplete { get; set; }
        public bool HasError { get; set; }
        public string ErrorMessage { get; set; }
        public double PercentComplete { get; set; }
        public long? BytesTotal { get; set; }
        public long? BytesProcessed { get; set; }
        public long? BytesRemaining { get; set; }
        public long? MillisecondsTotal { get; set; }
        public long? MillisecondsElapsed { get; set; }
        public long? MillisecondsRemaining { get; set; }
    }
}