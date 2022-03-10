namespace HstWbInstaller.Imager.Core.PhysicalDrives
{
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Threading.Tasks;
    using HstWbInstaller.Core.Extensions;
    using Microsoft.Extensions.Logging;
    using Models;

    public class WindowsPhysicalDriveManager : IPhysicalDriveManager
    {
        private readonly ILogger<WindowsPhysicalDriveManager> logger;

        public WindowsPhysicalDriveManager(ILogger<WindowsPhysicalDriveManager> logger)
        {
            this.logger = logger;
        }

        public async Task<IEnumerable<IPhysicalDrive>> GetPhysicalDrives()
        {
            if (!OperatingSystem.IsWindows())
            {
                throw new NotSupportedException("Windows physical drive manager is not running on Windows environment");
            }

            var wmicDiskDriveListCsv = await GetWmicDiskDriveListCsv();
            var wmicWin32DiskDriveToDiskPartitionsCsv = await GetWmicWin32DiskDriveToDiskPartitionPath();
            var wmicWin32LogicalDiskToPartitionsCsv = await GetWmicWin32LogicalDiskToPartitionPath();

            var wmicDiskDrives = WmicReader.ParseWmicCsv<WmicDiskDrive>(wmicDiskDriveListCsv).ToList();
            var wmicDiskDriveToDiskPartitions =
                WmicReader.ParseWmicDiskDriveToDiskPartitions(wmicWin32DiskDriveToDiskPartitionsCsv).ToList();
            var wmicLogicalDiskToPartitions =
                WmicReader.ParseWmicLogicalDiskToPartitions(wmicWin32LogicalDiskToPartitionsCsv).ToList();

            var removableMedias = wmicDiskDrives.Where(x =>
                    x.MediaType.Equals("Removable Media", StringComparison.OrdinalIgnoreCase) ||
                    x.MediaType.Equals("External hard disk media", StringComparison.OrdinalIgnoreCase))
                .ToList();

            return removableMedias.Select(x =>
                CreatePhysicalDrive(x, wmicDiskDriveToDiskPartitions, wmicLogicalDiskToPartitions));
        }

        private IPhysicalDrive CreatePhysicalDrive(WmicDiskDrive wmicDiskDrive,
            IEnumerable<WmicDiskDriveToDiskPartition> wmicDiskDriveToDiskPartitions,
            IEnumerable<WmicLogicalDiskToPartition> wmicLogicalDiskToPartitions)
        {
            var driveLetters = wmicDiskDriveToDiskPartitions.Where(x => x.Antecedent == wmicDiskDrive.Name)
                .Join(wmicLogicalDiskToPartitions, disk => disk.Dependent, logical => logical.Antecedent,
                    (_, logical) => logical.Dependent);
            return new WindowsPhysicalDrive(wmicDiskDrive.Name, wmicDiskDrive.MediaType, wmicDiskDrive.Model,
                wmicDiskDrive.Size, driveLetters);
        }

        private async Task<string> GetWmicDiskDriveListCsv()
        {
            var output = await "wmic".RunProcessAsync("diskdrive list /format:csv");
            logger.LogDebug(output);
            return output;
        }

        private async Task<string> GetWmicWin32DiskDriveToDiskPartitionPath()
        {
            var output = await "wmic".RunProcessAsync("path Win32_DiskDriveToDiskPartition get * /format:csv");
            logger.LogDebug(output);
            return output;
        }

        private async Task<string> GetWmicWin32LogicalDiskToPartitionPath()
        {
            var output = await "wmic".RunProcessAsync("path Win32_LogicalDiskToPartition get * /format:csv");
            logger.LogDebug(output);
            return output;
        }
    }
}