namespace HstWbInstaller.Core.IO.Vhds
{
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Threading.Tasks;
    using HstwbInstaller.Core;

    public class DataSectorReader
    {
        private readonly Stream stream;
        private readonly int sectorSize;
        private readonly int bufferSize;
        private readonly byte[] buffer;
        private long offset;

        public DataSectorReader(Stream stream, int sectorSize = 512, int bufferSize = 1024 * 1024)
        {
            if (sectorSize % 512 != 0)
            {
                throw new ArgumentException("Sector size must be dividable by 512", nameof(sectorSize));
            }
            
            if (bufferSize % 512 != 0)
            {
                throw new ArgumentException("Buffer size must be dividable by 512", nameof(bufferSize));
            }
            
            this.stream = stream;
            this.sectorSize = sectorSize;
            this.bufferSize = bufferSize;
            this.buffer = new byte[bufferSize];
            offset = this.stream.Position;
        }

        public async Task<SectorResult> ReadNext()
        {
            var bytesRead = await stream.ReadAsync(buffer, 0, bufferSize);
            var sectors = new List<Sector>();

            var start = 0;
            int end;
            do
            {
                for (; start < bytesRead; start += sectorSize)
                {
                    if (!IsSectorZeroFilled(start, start + sectorSize - 1))
                    {
                        break;
                    }
                }

                end = start;
                for (; end < bytesRead; end += sectorSize)
                {
                    if (IsSectorZeroFilled(end, end + sectorSize - 1))
                    {
                        break;
                    }
                }

                if (start != end)
                {
                    var length = end - start;
                    var data = new byte[length];
                    Array.Copy(buffer, start, data, 0, length);
                    sectors.Add(new Sector
                    {
                        Start = offset + start,
                        End = offset + end - 1,
                        Data = data
                    });
                }
                
                start = end;
            } while (start < bytesRead && end < bytesRead);

            offset += bytesRead;

            return new SectorResult
            {
                EndOfSectors = bytesRead != bufferSize,
                Sectors = sectors
            };
        }

        private bool IsSectorZeroFilled(int sectorStart, int sectorEnd)
        {
            for (var i = sectorStart; i <= sectorEnd; i++)
            {
                if (buffer[i] != 0)
                {
                    return false;
                }
            }

            return true;
        }
    }
}