namespace HstWbInstaller.Imager.Core
{
    using System;
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using HstWbInstaller.Core.IO.Vhds;

    public class ImageConverter
    {
        private readonly int bufferSize;
        
        public event EventHandler<DataProcessedEventArgs> DataProcessed;

        public ImageConverter(int bufferSize = 1024 * 1024)
        {
            this.bufferSize = bufferSize;
        }

        public async Task Convert(Stream source, Stream destination, long size, bool skipZeroFilled = false)
        {
            var dataSectorReader = new DataSectorReader(source, bufferSize: bufferSize);
            
            var totalBytesProcessed = 0L;
            long bytesRead = 0;
            SectorResult sectorResult;
            do
            {
                sectorResult = await dataSectorReader.ReadNext();
                bytesRead += sectorResult.BytesRead;

                if (skipZeroFilled)
                {
                    foreach (var sector in sectorResult.Sectors.Where(x => x.Start < size))
                    {
                        destination.Seek(sector.Start, SeekOrigin.Begin);
                        await destination.WriteAsync(sector.Data, 0, sector.Data.Length);
                    }
                }
                else
                {
                    var length = sectorResult.End > size ? size - sectorResult.Start : sectorResult.Data.Length;
                    await destination.WriteAsync(sectorResult.Data, 0, System.Convert.ToInt32(length));
                }

                var bytesProcessed = sectorResult.End >= size ? size - sectorResult.Start : sectorResult.BytesRead;
                totalBytesProcessed += bytesProcessed;
                var percentComplete = totalBytesProcessed == 0 ? 0 : (double)100 / size * totalBytesProcessed;
                OnDataProcessed(percentComplete, bytesProcessed, totalBytesProcessed, size);
            } while (bytesRead < size && !sectorResult.EndOfSectors);
        }

        private void OnDataProcessed(double percentComplete, long bytesProcessed, long totalBytesProcessed, long totalBytes)
        {
            DataProcessed?.Invoke(this, new DataProcessedEventArgs(percentComplete, bytesProcessed, totalBytesProcessed, totalBytes));
        }
    }
}