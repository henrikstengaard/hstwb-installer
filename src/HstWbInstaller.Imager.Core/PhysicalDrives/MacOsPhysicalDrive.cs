namespace HstWbInstaller.Imager.Core.PhysicalDrives
{
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using HstWbInstaller.Core.Extensions;

    public class MacOsPhysicalDrive : GenericPhysicalDrive
    {
        public readonly IEnumerable<string> PartitionDevices;

        public MacOsPhysicalDrive(string path, string type, string model, long size, IEnumerable<string> partitionDevices) : base(
            path, type, model, size)
        {
            this.PartitionDevices = partitionDevices;
        }

        public override Stream Open()
        {
            $"unmountDisk unmountDisk {Path}".RunProcess();
            return File.Open(Path, FileMode.Open, Writable ? FileAccess.ReadWrite : FileAccess.Read);
        }
    }
}