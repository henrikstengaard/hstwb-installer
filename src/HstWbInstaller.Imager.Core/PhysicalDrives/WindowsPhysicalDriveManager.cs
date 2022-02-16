namespace HstWbInstaller.Imager.Core.PhysicalDrives
{
    using System;
    using System.Collections.Generic;
    using System.Diagnostics;
    using System.Linq;
    using System.Threading.Tasks;

    public class WindowsPhysicalDriveManager : IPhysicalDriveManager
    {
        public async Task<IEnumerable<IPhysicalDrive>> GetPhysicalDrives()
        {
            var wmicCsv = await GetWmicCsv();
            
            var wmicDiskDrives = WmicReader.ParseWmicCsv(wmicCsv).ToList();

            var removableMedias = wmicDiskDrives.Where(x =>
                x.MediaType.Equals("Removable Media", StringComparison.OrdinalIgnoreCase) ||
                x.MediaType.Equals("External hard disk media", StringComparison.OrdinalIgnoreCase))
                .ToList();

            return removableMedias.Select(x => new WindowsPhysicalDrive(x.Name, x.MediaType, x.Model, x.Size));
        }

        private async Task<string> GetWmicCsv()
        {
            if (!OperatingSystem.IsWindows())
            {
                throw new NotSupportedException("Windows physical drive manager is not running on Windows environment");
            }

            var process = Process.Start(
                new ProcessStartInfo("wmic", "diskdrive list /format:csv")
                {
                    RedirectStandardOutput = true,
                    CreateNoWindow = true,
                    UseShellExecute = false
                });

            if (process == null)
            {
                throw new NotSupportedException("Failed to run wmic");
            }

            return await process.StandardOutput.ReadToEndAsync();
        }
    }
}