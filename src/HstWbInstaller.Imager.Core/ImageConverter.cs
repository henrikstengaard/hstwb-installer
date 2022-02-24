namespace HstWbInstaller.Imager.Core
{
    using System;
    using System.Diagnostics;
    using System.IO;
    using System.Linq;
    using System.Threading;
    using System.Threading.Tasks;
    using Helpers;
    using HstWbInstaller.Core;
    using HstWbInstaller.Core.IO.Vhds;

    public class ImageConverter
    {
        private readonly int bufferSize;
        
        public event EventHandler<DataProcessedEventArgs> DataProcessed;

        public ImageConverter(int bufferSize = 1024 * 1024)
        {
            this.bufferSize = bufferSize;
        }

        public async Task<Result> Convert(CancellationToken token, Stream source, Stream destination, long size, bool skipZeroFilled = false)
        {
            var stopwatch = new Stopwatch();
            stopwatch.Start();

            source.Seek(0, SeekOrigin.Begin);
            destination.Seek(0, SeekOrigin.Begin);
            
            var dataSectorReader = new DataSectorReader(source, bufferSize: bufferSize);
            
            var bytesProcessed = 0L;
            long bytesRead = 0;
            SectorResult sectorResult;
            do
            {
                if (token.IsCancellationRequested)
                {
                    return new Result<Error>(new Error("Cancelled"));
                }
                
                sectorResult = await dataSectorReader.ReadNext();
                bytesRead += sectorResult.BytesRead;

                if (skipZeroFilled)
                {
                    foreach (var sector in sectorResult.Sectors.Where(x => x.Start < size))
                    {
                        destination.Seek(sector.Start, SeekOrigin.Begin);
                        await destination.WriteAsync(sector.Data, 0, sector.Data.Length, token);
                    }
                }
                else
                {
                    var length = sectorResult.End > size ? size - sectorResult.Start : sectorResult.Data.Length;
                    await destination.WriteAsync(sectorResult.Data, 0, System.Convert.ToInt32(length), token);
                }

                var sectorBytesProcessed = sectorResult.End >= size ? size - sectorResult.Start : sectorResult.BytesRead;
                bytesProcessed += sectorBytesProcessed;
                var bytesRemaining = size - bytesProcessed;
                var percentComplete = bytesProcessed == 0 ? 0 : Math.Round((double)100 / size * bytesProcessed, 1);
                var timeElapsed = stopwatch.Elapsed;
                var timeRemaining = TimeHelper.CalculateTimeRemaining(percentComplete, timeElapsed);
                var timeTotal = timeElapsed + timeRemaining;
                
                OnDataProcessed(percentComplete, bytesProcessed, bytesRemaining, size, timeElapsed, timeRemaining, timeTotal);
            } while (bytesRead < size && !sectorResult.EndOfSectors);

            return new Result();
        }

        private void OnDataProcessed(double percentComplete, long bytesProcessed, long bytesRemaining, long bytesTotal, TimeSpan timeElapsed, TimeSpan timeRemaining, TimeSpan timeTotal)
        {
            DataProcessed?.Invoke(this, new DataProcessedEventArgs(percentComplete, bytesProcessed, bytesRemaining, bytesTotal, timeElapsed, timeRemaining, timeTotal));
        }
    }
}