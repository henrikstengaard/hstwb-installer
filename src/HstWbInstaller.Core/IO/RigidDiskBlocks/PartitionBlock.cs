namespace HstWbInstaller.Core.IO.RigidDiskBlocks
{
    public class PartitionBlock
    {
        public uint Size { get; set; }
        public int Checksum { get; set; }
        public uint HostId { get; set; }
        public uint NextPartitionBlock { get; set; }
        public uint Flags { get; set; }
        public uint DevFlags { get; set; }
        public string DriveName { get; set; }
        public uint SizeOfVector { get; set; }
        public uint SizeBlock { get; set; }
        public uint SecOrg { get; set; }
        public uint Surfaces { get; set; }
        public uint Sectors { get; set; }
        public uint BlocksPerTrack { get; set; }
        public uint Reserved { get; set; }
        public uint PreAlloc { get; set; }
        public uint Interleave { get; set; }
        public uint LowCyl { get; set; }
        public uint HighCyl { get; set; }
        public uint NumBuffer { get; set; }
        public uint BufMemType { get; set; }
        public uint MaxTransfer { get; set; }
        public uint Mask { get; set; }
        public uint BootPriority { get; set; }
        public byte[] DosType { get; set; }
        public uint Baud { get; set; }
        public uint Control { get; set; }
        public uint BootBlocks { get; set; }
        public ulong PartitionSize { get; set; }
    }
}