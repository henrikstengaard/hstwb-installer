﻿namespace HstWbInstaller.Imager.Core.PhysicalDrives
{
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Text;
    using System.Threading.Tasks;
    using HstWbInstaller.Core.Extensions;
    using Microsoft.Extensions.Logging;
    using OperatingSystem = HstWbInstaller.Core.OperatingSystem;

    public class MacOsPhysicalDriveManager : IPhysicalDriveManager
    {
        private readonly ILogger<MacOsPhysicalDriveManager> logger;

        public MacOsPhysicalDriveManager(ILogger<MacOsPhysicalDriveManager> logger)
        {
            this.logger = logger;
        }

        public async Task<IEnumerable<IPhysicalDrive>> GetPhysicalDrives()
        {
            if (!OperatingSystem.IsMacOs())
            {
                throw new NotSupportedException("MacOS physical drive manager is not running on macOS environment");
            }
            
            var listOutput = await GetDiskUtilExternalDisks();

            var disks = DiskUtilReader.ParseList(new MemoryStream(Encoding.UTF8.GetBytes(listOutput))).ToList();

            var physicalDrives = new List<IPhysicalDrive>();
            
            foreach (var disk in disks)
            {
                var partitionDevices = disk.Partitions.Select(x => x.DeviceIdentifier).ToList();
                var infoOutput = await GetDiskUtilInfoDisk(disk.DeviceIdentifier);

                var info = DiskUtilReader.ParseInfo(new MemoryStream(Encoding.UTF8.GetBytes(infoOutput)));

                if (info.BusProtocol.Equals("Disk Image", StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }
                
                physicalDrives.Add(new MacOsPhysicalDrive(info.DeviceNode, info.MediaType, info.IoRegistryEntryName, info.Size, partitionDevices));
            }
            
            return physicalDrives;
        }

        private async Task<string> GetDiskUtilExternalDisks()
        {
            var output = await "diskutil".RunProcessAsync("list -plist external");
            logger.LogDebug(output);
            return output;
        }

        private async Task<string> GetDiskUtilInfoDisk(string disk)
        {
            var output = await "diskutil".RunProcessAsync($"info -plist {disk}");
            logger.LogDebug(output);
            return output;
        }
    }
}