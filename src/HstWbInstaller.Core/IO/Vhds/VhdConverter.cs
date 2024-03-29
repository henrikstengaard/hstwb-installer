﻿namespace HstWbInstaller.Core.IO.Vhds
{
    using System;
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using DiscUtils;
    using DiscUtils.Streams;
    using DiscUtils.Vhd;

    public class VhdConverter
    {
        private readonly int bufferSize;
        
        public event EventHandler<DataTransferredArgs> DataTransferred;

        public VhdConverter(int bufferSize = 1024 * 1024)
        {
            this.bufferSize = bufferSize;
        }

        public async Task ConvertVhdToImg(string vhdPath, Stream imgStream)
        {
            DiscUtils.Containers.SetupHelper.SetupContainers();
            DiscUtils.FileSystems.SetupHelper.SetupFileSystems();
            using var vhdDisk = VirtualDisk.OpenDisk(vhdPath, FileAccess.Read);
            vhdDisk.Content.Position = 0;

            var buffer = new byte[bufferSize];
            
            int bytesRead;
            do
            {
                bytesRead = await vhdDisk.Content.ReadAsync(buffer, 0, bufferSize);
                await imgStream.WriteAsync(buffer, 0, bytesRead);
                OnDataTransferred(bytesRead);
            } while (bytesRead == buffer.Length);
        }

        public async Task ConvertImgToVhd(Stream imgStream, Stream vhdStream, long length = 0)
        {
            var vhdDisk = Disk.InitializeDynamic(vhdStream, Ownership.None, length == 0 ? imgStream.Length : length);

            var dataSectorReader = new DataSectorReader(imgStream, bufferSize: bufferSize);

            long totalBytesRead = 0;
            SectorResult sectorResult;
            do
            {
                sectorResult = await dataSectorReader.ReadNext();
                totalBytesRead += sectorResult.BytesRead;

                foreach (var sector in sectorResult.Sectors.Where(x => x.Start < length))
                {
                    vhdDisk.Content.Position = sector.Start;
                    await vhdDisk.Content.WriteAsync(sector.Data.AsMemory(0, sector.Data.Length));
                }
                OnDataTransferred(sectorResult.BytesRead);
            } while (totalBytesRead <= length && !sectorResult.EndOfSectors);
        }
        
        protected virtual void OnDataTransferred(int bytesTransferred)
        {
            DataTransferred?.Invoke(this, new DataTransferredArgs(bytesTransferred));
        }
    }
}