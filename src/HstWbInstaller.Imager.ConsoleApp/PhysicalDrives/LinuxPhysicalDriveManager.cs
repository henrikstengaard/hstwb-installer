namespace HstWbInstaller.Imager.ConsoleApp.PhysicalDrives
{
    using System;
    using System.Collections.Generic;
    using System.Diagnostics;
    using System.IO;
    using System.Linq;
    using System.Text.Json;
    using System.Threading.Tasks;
    using Core;
    using Models;
    using OperatingSystem = ConsoleApp.OperatingSystem;

    public class LinuxPhysicalDriveManager : IPhysicalDriveManager
    {
        private readonly bool fake;

        public LinuxPhysicalDriveManager(bool fake = false)
        {
            this.fake = fake;
        }

        public async Task<IEnumerable<IPhysicalDrive>> GetPhysicalDrives()
        {
            var lsBlkJson = await GetLsBlkJson();
            var lsBlk = JsonSerializer.Deserialize<LsBlk>(lsBlkJson) ?? new LsBlk();

            if (lsBlk.BlockDevices == null)
            {
                return Enumerable.Empty<IPhysicalDrive>();
            }

            var diskBlockDevices =
                lsBlk.BlockDevices.Where(x =>
                    !string.IsNullOrWhiteSpace(x.Type) &&
                    x.Type.Equals("disk", StringComparison.OrdinalIgnoreCase)).ToList();

            return diskBlockDevices.Select(x => new GenericPhysicalDrive(x.Path, x.Type, x.Model, x.Size));
        }

        private async Task<string> GetLsBlkJson()
        {
            if (fake && File.Exists("fake-lsblk.json"))
            {
                return await File.ReadAllTextAsync("fake-lsblk.json");
            }
            
            if (!OperatingSystem.IsLinux())
            {
                throw new NotSupportedException("Linux physical drive manager is not running on Linux environment");
            }
            
            var process = Process.Start(
                new ProcessStartInfo("lsblk", "-ba -o TYPE,NAME,RM,MODEL,PATH,SIZE --json")
                {
                    RedirectStandardOutput = true,
                    CreateNoWindow = true,
                    UseShellExecute = false
                });
            
            if (process == null)
            {
                throw new NotSupportedException("Failed to run lsblk");
            }
            
            return await process.StandardOutput.ReadToEndAsync();
        }
    }
}