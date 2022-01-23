namespace HstWbInstaller.Imager.Core
{
    using System;

    public class DataProcessedEventArgs : EventArgs
    {
        public readonly double PercentComplete;
        public readonly long BytesProcessed;
        public readonly long TotalBytesProcessed;
        public readonly long TotalBytes;

        public DataProcessedEventArgs(double percentComplete, long bytesProcessed, long totalBytesProcessed, long totalBytes)
        {
            PercentComplete = percentComplete;
            BytesProcessed = bytesProcessed;
            TotalBytesProcessed = totalBytesProcessed;
            TotalBytes = totalBytes;
        }
    }
}