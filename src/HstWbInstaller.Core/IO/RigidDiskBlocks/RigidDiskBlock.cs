namespace HstWbInstaller.Core.IO.RigidDiskBlocks
{
    using System.Collections.Generic;

    public class RigidDiskBlock
    {
        public uint Size { get; set; }
        public int Checksum { get; set; }
        public uint HostId { get; set; }
        public uint BlockSize { get; set; }
        public uint Flags { get; set; }
        public uint BadBlockList { get; set; }
        public uint PartitionList { get; set; }
        public uint FileSysHdrList { get; set; }
        public uint DriveInitCode { get; set; }
        public uint BootBlockList { get; set; }

        public uint Cylinders { get; set; }
        public uint Sectors { get; set; }
        public uint Heads { get; set; }
        public uint Interleave { get; set; }
        public uint ParkingZone { get; set; }

        public uint WritePreComp { get; set; }
        public uint ReducedWrite { get; set; }
        public uint StepRate { get; set; }

        public uint RdbBlockLo { get; set; }
        public uint RdbBlockHi { get; set; }
        public uint LoCylinder { get; set; }
        public uint HiCylinder { get; set; }
        public uint CylBlocks { get; set; }
        public uint AutoParkSeconds { get; set; }
        public uint HighRsdkBlock { get; set; }
        public string DiskVendor { get; set; }
        public string DiskProduct { get; set; }
        public string DiskRevision { get; set; }
        public string ControllerVendor { get; set; }
        public string ControllerProduct { get; set; }
        public string ControllerRevision { get; set; }
        public ulong DiskSize { get; set; }

        public IEnumerable<PartitionBlock> PartitionBlocks { get; set; }
    }
}