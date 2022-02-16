namespace HstWbInstaller.Imager.Core.PhysicalDrives
{
    using System;
    using System.Collections.Generic;
    using System.Diagnostics;
    using System.IO;
    using System.Linq;
    using System.Text;
    using System.Threading.Tasks;
    using OperatingSystem = OperatingSystem;

    public class MacOsPhysicalDriveManager : IPhysicalDriveManager
    {
        public async Task<IEnumerable<IPhysicalDrive>> GetPhysicalDrives()
        {
            var listOutput = await RunDiskUtil("list -plist external");

            var disks = DiskUtilReader.ParseList(new MemoryStream(Encoding.UTF8.GetBytes(listOutput))).ToList();

            var physicalDrives = new List<IPhysicalDrive>();
            
            foreach (var disk in disks)
            {
                var infoOutput = await RunDiskUtil($"info -plist {disk}");

                var info = DiskUtilReader.ParseInfo(new MemoryStream(Encoding.UTF8.GetBytes(infoOutput)));
                
                physicalDrives.Add(new GenericPhysicalDrive(info.DeviceNode, info.MediaType, info.IoRegistryEntryName, info.Size));
            }
            
            return physicalDrives;
        }

        private async Task<string> RunDiskUtil(string arguments)
        {
            if (!OperatingSystem.IsMacOs())
            {
                throw new NotSupportedException("MacOS physical drive manager is not running on macOS environment");
            }
            
            var process = Process.Start(
                new ProcessStartInfo("diskutil", arguments)
                {
                    RedirectStandardOutput = true,
                    CreateNoWindow = true,
                    UseShellExecute = false
                });
            
            if (process == null)
            {
                throw new NotSupportedException("Failed to run diskutil");
            }
            
            return await process.StandardOutput.ReadToEndAsync();
        }
    }
}