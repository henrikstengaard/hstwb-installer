namespace HstWbInstaller.Imager.Core.PhysicalDrives
{
    using System;
    using System.Collections.Generic;
    using System.Diagnostics;
    using System.Linq;
    using System.Threading.Tasks;
    using Extensions;
    using OperatingSystem = OperatingSystem;

    public class LinuxPhysicalDriveManager : IPhysicalDriveManager
    {
        public async Task<IEnumerable<IPhysicalDrive>> GetPhysicalDrives()
        {
            if (!OperatingSystem.IsLinux())
            {
                throw new NotSupportedException("Linux physical drive manager is not running on Linux environment");
            }

            var lsBlkJson = await GetLsBlkJson();

            var lsBlk = LsBlkReader.ParseLsBlk(lsBlkJson);

            if (lsBlk.BlockDevices == null)
            {
                return Enumerable.Empty<IPhysicalDrive>();
            }

            var diskBlockDevices =
                lsBlk.BlockDevices.Where(x =>
                    !string.IsNullOrWhiteSpace(x.Type) &&
                    x.Type.Equals("disk", StringComparison.OrdinalIgnoreCase) &&
                    x.Removable).ToList();

            return diskBlockDevices.Select(x =>
                new GenericPhysicalDrive(x.Path, x.Type, string.Concat(x.Vendor, " ", x.Model), x.Size));
        }

        private async Task<string> GetLsBlkJson()
        {
            return await "lsblk".RunProcessAsync("-ba -o TYPE,NAME,RM,MODEL,PATH,SIZE,VENDOR --json");
        }
    }
}