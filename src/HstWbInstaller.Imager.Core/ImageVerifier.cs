namespace HstWbInstaller.Imager.Core
{
    using System;
    using System.Diagnostics;
    using System.IO;
    using System.Threading;
    using System.Threading.Tasks;
    using Commands;
    using Helpers;
    using HstWbInstaller.Core;

    public class ImageVerifier
    {
        private readonly int bufferSize;
        
        public event EventHandler<DataProcessedEventArgs> DataProcessed;

        public ImageVerifier(int bufferSize = 1024 * 1024)
        {
            this.bufferSize = bufferSize;
        }

        public async Task<Result> Verify(CancellationToken token, Stream source, Stream destination, long size)
        {
            var stopwatch = new Stopwatch();
            stopwatch.Start();
            
            // var srcBuffer = new byte[bufferSize];
            // var destBuffer = new byte[bufferSize];
            //
            // var bytesProcessed = 0L;
            // int srcBytesRead;
            // int destBytesRead;
            // do
            // {
            //     var chunkSize = Convert.ToInt32(bytesProcessed + bufferSize >= size ? size - bytesProcessed : bufferSize);
            //     
            //     srcBytesRead = await source.ReadAsync(srcBuffer, 0, chunkSize);
            //     destBytesRead = await destination.ReadAsync(destBuffer, 0, chunkSize);
            //
            //     if (srcBytesRead != destBytesRead)
            //     {
            //         return false;
            //     }
            //     
            //     for (var i = 0; i < srcBytesRead; i++)
            //     {
            //         if (srcBuffer[i] != destBuffer[i])
            //         {
            //             return false;
            //         }
            //     }
            //     
            //     bytesProcessed += chunkSize;
            //     var bytesRemaining = size - bytesProcessed;
            //     var percentComplete = bytesProcessed == 0 ? 0 : (double)100 / size * bytesProcessed;
            //     var timeElapsed = stopwatch.Elapsed;
            //     var timeRemaining = TimeHelper.CalculateTimeRemaining(percentComplete, timeElapsed);
            //     var timeTotal = timeElapsed + timeRemaining;
            //     
            //     OnDataProcessed(percentComplete, bytesProcessed, bytesRemaining, size, timeElapsed, timeRemaining, timeTotal);
            // } while (srcBytesRead == bufferSize && destBytesRead == srcBytesRead);

            var srcBuffer = new byte[bufferSize];
            var destBuffer = new byte[bufferSize];
            int srcBytesRead;
            long offset = 0;
            do
            {
                if (token.IsCancellationRequested)
                {
                    return new Result<Error>(new Error("Cancelled"));
                }
                
                var verifyBytes = Convert.ToInt32(offset + bufferSize > size ? size - offset : bufferSize);
                srcBytesRead = await source.ReadAsync(srcBuffer, 0, verifyBytes, token);
                var destBytesRead = await destination.ReadAsync(destBuffer, 0, verifyBytes, token);
                
                if (srcBytesRead != destBytesRead)
                {
                    return new Result(new SizeNotEqualError(offset + srcBytesRead, offset + destBytesRead));
                }
                
                for (int i = 0; i < verifyBytes; i++)
                {
                    if (srcBuffer[i] == destBuffer[i])
                    {
                        continue;
                    }
                    
                    return new Result(new ByteNotEqualError(offset + i, srcBuffer[i], destBuffer[i]));
                }
            
                offset += verifyBytes;
                var bytesRemaining = size - offset;
                var percentComplete = offset == 0 ? 0 : Math.Round((double)100 / size * offset, 1);
                var timeElapsed = stopwatch.Elapsed;
                var timeRemaining = TimeHelper.CalculateTimeRemaining(percentComplete, timeElapsed);
                var timeTotal = timeElapsed + timeRemaining;
                
                OnDataProcessed(percentComplete, offset, bytesRemaining, size, timeElapsed, timeRemaining, timeTotal);
            } while (srcBytesRead == bufferSize && offset < size);            
            
            return new Result();
        }

        private void OnDataProcessed(double percentComplete, long bytesProcessed, long bytesRemaining, long bytesTotal, TimeSpan timeElapsed, TimeSpan timeRemaining, TimeSpan timeTotal)
        {
            DataProcessed?.Invoke(this, new DataProcessedEventArgs(percentComplete, bytesProcessed, bytesRemaining, bytesTotal, timeElapsed, timeRemaining, timeTotal));
        }
    }
}