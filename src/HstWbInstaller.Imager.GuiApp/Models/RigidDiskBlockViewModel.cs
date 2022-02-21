namespace HstWbInstaller.Imager.GuiApp.Models
{
    using System.Collections.Generic;

    public class RigidDiskBlockViewModel
    {
        public uint BlockSize { get; set; }
        public uint Cylinders { get; set; }
        public uint Sectors { get; set; }
        public uint Heads { get; set; }
        public uint ParkingZone { get; set; }
        public uint RdbBlockLo { get; set; }
        public uint RdbBlockHi { get; set; }
        public uint LoCylinder { get; set; }
        public uint HiCylinder { get; set; }
        public uint CylBlocks { get; set; }

        public string DiskVendor { get; set; }
        public string DiskProduct { get; set; }
        public string DiskRevision { get; set; }
        public string ControllerVendor { get; set; }
        public string ControllerProduct { get; set; }
        public string ControllerRevision { get; set; }

        public long DiskSize { get; set; }

        public IEnumerable<PartitionBlockViewModel> PartitionBlocks { get; set; }
        public IEnumerable<FileSystemHeaderBlockViewModel> FileSystemHeaderBlocks { get; set; }
    }
}