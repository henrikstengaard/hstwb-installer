namespace HstWbInstaller.Core.IO.RigidDiskBlocks
{
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using Extensions;

    public class RigidDiskBlock
    {
        // [Flags]
        // public enum RigidDiskBlockFlagsEnum
        // {
        //     Bootable = 1,
        //     NoMount = 2,
        //     Raid = 4,
        //     Lvm = 8
        // }
        
        public uint Size { get; set; }
        
        /// <summary>
        /// checksum
        /// </summary>
        public int Checksum { get; set; }
        
        /// <summary>
        /// SCSI Target ID of host (== 7 for IDE and ZIP disks)
        /// </summary>
        public uint HostId { get; set; }
        
        /// <summary>
        /// typically 512 bytes, but can be other powers of 2
        /// </summary>
        public uint BlockSize { get; set; }
        
        /// <summary>
        /// flags
        /// </summary>
        public uint Flags { get; set; }
        
        /// <summary>
        /// block pointer (-1 means last block)
        /// </summary>
        public uint BadBlockList { get; set; }
        
        /// <summary>
        /// block pointer (-1 means last)
        /// </summary>
        public uint PartitionList { get; set; }
        
        /// <summary>
        /// block pointer (-1 means last)
        /// </summary>
        public uint FileSysHdrList { get; set; }
        
        /// <summary>
        /// drive-specific init code (optional)
        /// </summary>
        public uint DriveInitCode { get; set; }
        
        /// <summary>
        /// amiga os 4 boot blocks pointer
        /// </summary>
        public uint BootBlockList { get; set; }

        /// <summary>
        /// number of drive cylinder
        /// </summary>
        public uint Cylinders { get; set; }
        
        /// <summary>
        /// sectors per track
        /// </summary>
        public uint Sectors { get; set; }
        
        /// <summary>
        /// number of drive heads
        /// </summary>
        public uint Heads { get; set; }
        
        /// <summary>
        /// interleave
        /// </summary>
        public uint Interleave { get; set; }
        
        /// <summary>
        /// landing zone cylinders, soon after the last cylinder
        /// </summary>
        public uint ParkingZone { get; set; }

        /// <summary>
        /// starting cyl : write precompensation
        /// </summary>
        public uint WritePreComp { get; set; }
        
        /// <summary>
        /// starting cyl : reduced write current
        /// </summary>
        public uint ReducedWrite { get; set; }
        
        /// <summary>
        /// drive step rate
        /// </summary>
        public uint StepRate { get; set; }

        /// <summary>
        /// low block of range reserved for hardblk
        /// </summary>
        public uint RdbBlockLo { get; set; }
        
        /// <summary>
        /// high block of range for this hardblocks
        /// </summary>
        public uint RdbBlockHi { get; set; }
        
        /// <summary>
        /// low cylinder of partitionable disk area
        /// </summary>
        public uint LoCylinder { get; set; }
        
        /// <summary>
        /// high cylinder of partitionable data area
        /// </summary>
        public uint HiCylinder { get; set; }
        
        /// <summary>
        /// number of blocks available per cylinder
        /// </summary>
        public uint CylBlocks { get; set; }
        
        /// <summary>
        /// zero for no autopark
        /// </summary>
        public uint AutoParkSeconds { get; set; }
        
        /// <summary>
        /// highest block used by RDSK (not including replacement bad blocks)
        /// </summary>
        public uint HighRsdkBlock { get; set; }
        
        public string DiskVendor { get; set; }
        public string DiskProduct { get; set; }
        public string DiskRevision { get; set; }
        public string ControllerVendor { get; set; }
        public string ControllerProduct { get; set; }
        public string ControllerRevision { get; set; }
        
        public long DiskSize { get; set; }

        public IEnumerable<PartitionBlock> PartitionBlocks { get; set; }
        public IEnumerable<FileSystemHeaderBlock> FileSystemHeaderBlocks { get; set; }
        public IEnumerable<BadBlock> BadBlocks { get; set; }

        public RigidDiskBlock()
        {
            AutoParkSeconds = 0;
            BadBlockList = BlockIdentifiers.EndOfBlock;
            BootBlockList = BlockIdentifiers.EndOfBlock;
            BlockSize = 512;
            ControllerProduct = string.Empty;
            ControllerRevision = string.Empty;
            ControllerVendor = string.Empty;
            CylBlocks = 1008;
            DiskProduct = "HstWB Imager";
            DiskRevision = "0.4";
            DiskVendor = "HstWB";
            DriveInitCode = BlockIdentifiers.EndOfBlock;
            FileSysHdrList = BlockIdentifiers.EndOfBlock;
            Flags = 7;
            Heads = 16;
            HostId = 7;
            Interleave = 1;
            PartitionList = BlockIdentifiers.EndOfBlock;
            RdbBlockHi = 2015;
            RdbBlockLo = 0;
            Sectors = 63;
            StepRate = 3;

            // properties that are calculated when size of disk changes
            Cylinders = 0; // set to size of disk
            LoCylinder = 0; // first usable cylinder
            HiCylinder = 0; // last usable cylinder
            HighRsdkBlock = 179; //
            ParkingZone = Cylinders; // set to last cylinder
            ReducedWrite = Cylinders; // set to last cylinder
            WritePreComp = Cylinders; // set to last cylinder
        }
    }
}