namespace HstWbInstaller.Core.IO.RigidDiskBlocks
{
    using System;

    public class PartitionBlock
    {
        [Flags]
        public enum PartitionFlagsEnum
        {
            Bootable = 1,
            NoMount = 2,
            Raid = 4,
            Lvm = 8
        }
        
        public uint Size { get; set; }
        public int Checksum { get; set; }
        public uint HostId { get; set; }
        public uint NextPartitionBlock { get; set; }
        public uint Flags { get; set; }
        public uint DevFlags { get; set; }
        public string DriveName { get; set; }
        
        /// <summary>
        /// == 16 (longs), 11 is the minimal value
        /// </summary>
        public uint SizeOfVector { get; set; }
        
        /// <summary>
        /// size of the blocks in longs == 128 for BSIZE = 512
        /// </summary>
        public uint SizeBlock { get; set; }
        public uint SecOrg { get; set; }
        
        /// <summary>
        /// number of heads (surfaces) of drive
        /// </summary>
        public uint Surfaces { get; set; }
        public uint Sectors { get; set; }
        public uint BlocksPerTrack { get; set; }
        
        // DOS reserved blocks at start of partition, usually = 2 (minimum 1)
        public uint Reserved { get; set; }
        
        /// <summary>
        /// DOS reserved blocks at end of partition (no impact on Root block allocation)
        /// </summary>
        public uint PreAlloc { get; set; }
        
        public uint Interleave { get; set; }
        
        /// <summary>
        /// first cylinder of a partition (inclusive)
        /// </summary>
        public uint LowCyl { get; set; }
        
        /// <summary>
        /// last cylinder of a partition (inclusive)
        /// </summary>
        public uint HighCyl { get; set; }
        
        /// <summary>
        /// often 30 (used for buffering)
        /// </summary>
        public uint NumBuffer { get; set; }
        public uint BufMemType { get; set; }
        public uint MaxTransfer { get; set; }
        public string MaxTransferHex { get; set; }
        
        /// <summary>
        /// Address mask to block out certain memory often 0xffff fffe
        /// </summary>
        public uint Mask { get; set; }
        public string MaskHex { get; set; }
        
        /// <summary>
        /// boot priority for autoboot
        /// </summary>
        public uint BootPriority { get; set; }
        
        /// <summary>
        /// dostype for filesystem (DOS3, PDS3)
        /// </summary>
        public byte[] DosType { get; set; }
        public string DosTypeFormatted { get; set; }
        public string DosTypeHex { get; set; }
        
        public uint Baud { get; set; }
        public uint Control { get; set; }
        public uint BootBlocks { get; set; }
        
        public long PartitionSize { get; set; }
        public uint FileSystemBlockSize { get; set; }
        public bool Bootable { get; set; }
        public bool NoMount { get; set; }

        public PartitionBlock()
        {
            Baud = 0;
            BlocksPerTrack = 63;
            BootBlocks = 0;
            BootPriority = 0;
            BufMemType = 0;
            Control = 0;
            DevFlags = 0;
            //Flags 1
            //HighCyl: 610
            HostId = 7;
            Interleave = 0;
            //LowCyl: 2
            Mask = 2147483646;
            MaxTransfer = 130560;
            NumBuffer = 30;
            PreAlloc = 0;
            Reserved = 2;
            SecOrg = 0;
            Sectors = 1;
            SizeBlock = 128; // block size 512 
            SizeOfVector = 16;
            Surfaces = 16; // heads
        }
    }
}