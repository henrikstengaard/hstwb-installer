namespace HstWbInstaller.Imager.Core.PhysicalDrives
{
    using System;
    using System.Collections.Generic;
    using System.Diagnostics;
    using System.Globalization;
    using System.IO;
    using System.Linq;
    using System.Text;
    using System.Threading.Tasks;
    using CsvHelper;
    using CsvHelper.Configuration;
    using Models;

    public class WindowsPhysicalDriveManager : IPhysicalDriveManager
    {
        private readonly bool fake;

        public WindowsPhysicalDriveManager(bool fake = false)
        {
            this.fake = fake;
        }

        public async Task<IEnumerable<IPhysicalDrive>> GetPhysicalDrives()
        {
            var wmicDiskDrives = (await GetWmicDiskDrives()).ToList();

            var removableMedias = wmicDiskDrives.Where(x =>
                x.MediaType.Equals("Removable Media", StringComparison.OrdinalIgnoreCase) ||
                x.MediaType.Equals("External hard disk media", StringComparison.OrdinalIgnoreCase))
                .ToList();

            if (fake)
            {
                    return removableMedias.Select(x => new FakePhysicalDrive(x.Name, x.MediaType, x.Model, x.Size))
                        .ToList();
            }
            
            return removableMedias.Select(x => new WindowsPhysicalDrive(x.Name, x.MediaType, x.Model, x.Size));
        }

        private async Task<string> GetWmicCsv()
        {
            if (fake && File.Exists("fake-wmic.csv"))
            {
                return await File.ReadAllTextAsync("fake-wmic.csv");
            }

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

        private async Task<IEnumerable<WmicDiskDrive>> GetWmicDiskDrives()
        {
            var wmicCsv = await GetWmicCsv();

            using var csv = new CsvReader(new StreamReader(new MemoryStream(Encoding.UTF8.GetBytes(wmicCsv))),
                new CsvConfiguration(CultureInfo.InvariantCulture)
                {
                    Delimiter = ",",
                    Encoding = Encoding.UTF8
                });

            return csv.GetRecords<WmicDiskDrive>().ToList();
        }
    }
}