namespace HstWbInstaller.Imager.ConsoleApp
{
    using System;
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using HstWbInstaller.Core.IO.Vhds;

    public class ImageConverter
    {
        private readonly int bufferSize;
        
        public event EventHandler<DataConvertedEventArgs> DataConverted;

        public ImageConverter(int bufferSize = 1024 * 1024)
        {
            this.bufferSize = bufferSize;
        }

        public async Task Convert(Stream source, Stream destination, long size, bool skipZeroFilled = false)
        {
            var dataSectorReader = new DataSectorReader(source, bufferSize: bufferSize);
            
            long bytesRead = 0;
            SectorResult sectorResult;
            do
            {
                sectorResult = await dataSectorReader.ReadNext();
                bytesRead += sectorResult.BytesRead;

                if (skipZeroFilled)
                {
                    await destination.WriteAsync(sectorResult.Data, 0, sectorResult.Data.Length);
                }
                else
                {
                    foreach (var sector in sectorResult.Sectors.Where(x => x.Start < size))
                    {
                        destination.Seek(sector.Start, SeekOrigin.Begin);
                        await destination.WriteAsync(sector.Data, 0, sector.Data.Length);
                        
                        // vhdDisk.Content.Position = sector.Start;
                        // await vhdDisk.Content.WriteAsync(sector.Data.AsMemory(0, sector.Data.Length));
                    }
                }
                
                OnDataConverted(sectorResult.End >= size ? size - sectorResult.Start : sectorResult.BytesRead);
            } while (bytesRead < size && !sectorResult.EndOfSectors);
            
            //
            // int bytesRead;
            // do
            // {
            //     bytesRead = await source.ReadAsync(buffer, 0, buffer.Length);
            //     bytesWritten += (ulong)bytesRead;
            //     await destination.WriteAsync(buffer, 0, bytesRead);
            //
            //     var pct = bytesWritten == 0 ? 0 : ((double)100 / srcSize) * bytesWritten;
            //     Console.WriteLine($"{pct}");
            // } while (bytesRead == buffer.Length);
        }
        
        protected virtual void OnDataConverted(long bytesConverted)
        {
            DataConverted?.Invoke(this, new DataConvertedEventArgs(bytesConverted));
        }
    }
}