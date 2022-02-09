namespace HstWbInstaller.Core.IO.RigidDiskBlocks
{
    using System;
    using System.Linq;
    using Extensions;

    public class PartitionBlock : BlockBase
    {
        [Flags]
        public enum PartitionFlagsEnum
        {
            Bootable = 1,
            NoMount = 2,
            Raid = 4,
            Lvm = 8
        }
        
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
        public string MaxTransferHex => $"0x{MaxTransfer.FormatHex()}";

        /// <summary>
        /// Address mask to block out certain memory often 0xffff fffe
        /// </summary>
        public uint Mask { get; set; }
        public string MaskHex => $"0x{Mask.FormatHex()}";
        
        /// <summary>
        /// boot priority for autoboot
        /// </summary>
        public uint BootPriority { get; set; }

        /// <summary>
        /// dostype for filesystem (DOS3, PDS3)
        /// </summary>
        public byte[] DosType { get; set; }

        public string DosTypeFormatted => DosType.FormatDosType();
        public string DosTypeHex => $"0x{DosType.FormatHex()}";
        
        public uint Baud { get; set; }
        public uint Control { get; set; }
        public uint BootBlocks { get; set; }
        
        public long PartitionSize { get; set; }
        public uint FileSystemBlockSize { get; set; }
        public bool Bootable => ((PartitionFlagsEnum)Flags).HasFlag(PartitionFlagsEnum.Bootable);
        public bool NoMount => ((PartitionFlagsEnum)Flags).HasFlag(PartitionFlagsEnum.NoMount);

        public PartitionBlock()
        {
            Baud = 0;
            BlocksPerTrack = 63;
            BootBlocks = 0;
            BootPriority = 0;
            BufMemType = 0;
            Control = 0;
            DevFlags = 0;
            HostId = 7;
            HighCyl = 0; // calculated when added to rigid disk block
            Interleave = 0;
            LowCyl = 0; // calculated when added to rigid disk block
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
            FileSystemBlockSize = SizeBlock * 4 * Sectors;
        }

        public static PartitionBlock Create(RigidDiskBlock rigidDiskBlock, byte[] dosType, string driveName, long size = 0, bool bootable = false)
        {
            var lastPartitionBlock = rigidDiskBlock.PartitionBlocks.LastOrDefault();
            var lowCyl = lastPartitionBlock == null ? rigidDiskBlock.LoCylinder : lastPartitionBlock.HighCyl + 1;

            uint cylinders;
            if (size > 0)
            {
                size = size.ToSectorSize();
                var blocksPerCylinder = rigidDiskBlock.Heads * rigidDiskBlock.Sectors;
                cylinders = (uint)Math.Floor((double)size / (blocksPerCylinder * rigidDiskBlock.BlockSize));
            }
            else
            {
                cylinders = lastPartitionBlock == null
                    ? rigidDiskBlock.Cylinders
                    : rigidDiskBlock.Cylinders - lowCyl;
            }

            var highCyl = lowCyl + cylinders - 1 > rigidDiskBlock.HiCylinder
                ? rigidDiskBlock.HiCylinder
                : lowCyl + cylinders - 1;

            var partitionBlock = new PartitionBlock
            {
                PartitionSize = cylinders * rigidDiskBlock.Heads * rigidDiskBlock.Sectors * rigidDiskBlock.BlockSize,
                DosType = dosType,
                DriveName = driveName,
                Flags = bootable ? (uint)PartitionFlagsEnum.Bootable : 0,
                LowCyl = lowCyl,
                HighCyl = highCyl
            };

            return partitionBlock;
        }
    }
}