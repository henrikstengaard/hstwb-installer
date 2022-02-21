namespace HstWbInstaller.Imager.GuiApp.Extensions
{
    using System.Linq;
    using Core.Commands;
    using HstWbInstaller.Core.IO.RigidDiskBlocks;
    using Models;

    public static class ViewModelExtensions
    {
        public static MediaInfoViewModel ToViewModel(this MediaInfo mediaInfo)
        {
            return new MediaInfoViewModel
            {
                Model = mediaInfo.Model,
                Path = mediaInfo.Path,
                DiskSize = mediaInfo.DiskSize,
                IsPhysicalDrive = mediaInfo.IsPhysicalDrive,
                RigidDiskBlock = mediaInfo.RigidDiskBlock?.ToViewModel()
            };
        }

        public static RigidDiskBlockViewModel ToViewModel(this RigidDiskBlock rigidDiskBlock)
        {
            return new RigidDiskBlockViewModel
            {
                BlockSize = rigidDiskBlock.BlockSize,
                ControllerProduct = rigidDiskBlock.ControllerProduct,
                ControllerRevision = rigidDiskBlock.ControllerRevision,
                ControllerVendor = rigidDiskBlock.ControllerVendor,
                CylBlocks = rigidDiskBlock.CylBlocks,
                Cylinders = rigidDiskBlock.Cylinders,
                DiskProduct = rigidDiskBlock.DiskProduct,
                DiskRevision = rigidDiskBlock.DiskRevision,
                DiskVendor = rigidDiskBlock.DiskVendor,
                DiskSize = rigidDiskBlock.DiskSize,
                Heads = rigidDiskBlock.Heads,
                Sectors = rigidDiskBlock.Sectors,
                HiCylinder = rigidDiskBlock.HiCylinder,
                LoCylinder = rigidDiskBlock.LoCylinder,
                ParkingZone = rigidDiskBlock.ParkingZone,
                RdbBlockHi = rigidDiskBlock.RdbBlockHi,
                RdbBlockLo = rigidDiskBlock.RdbBlockLo,
                PartitionBlocks = rigidDiskBlock.PartitionBlocks.Select(x => x.ToViewModel()).ToList(),
                FileSystemHeaderBlocks = rigidDiskBlock.FileSystemHeaderBlocks.Select(x => x.ToViewModel()).ToList()
            };
        }

        public static PartitionBlockViewModel ToViewModel(this PartitionBlock partitionBlock)
        {
            return new PartitionBlockViewModel
            {
                Bootable = partitionBlock.Bootable,
                Mask = partitionBlock.Mask,
                DosType = partitionBlock.DosType,
                DosTypeFormatted = partitionBlock.DosTypeFormatted,
                DosTypeHex = partitionBlock.DosTypeHex,
                Reserved = partitionBlock.Reserved,
                BlocksPerTrack = partitionBlock.BlocksPerTrack,
                BootPriority = partitionBlock.BootPriority,
                Sectors = partitionBlock.Sectors,
                Surfaces = partitionBlock.Surfaces,
                DriveName = partitionBlock.DriveName,
                HighCyl = partitionBlock.HighCyl,
                LowCyl = partitionBlock.LowCyl,
                MaskHex = partitionBlock.MaskHex,
                MaxTransfer = partitionBlock.MaxTransfer,
                MaxTransferHex = partitionBlock.MaxTransferHex,
                NoMount = partitionBlock.NoMount,
                NumBuffer = partitionBlock.NumBuffer,
                PartitionSize = partitionBlock.PartitionSize,
                PreAlloc = partitionBlock.PreAlloc,
                SizeBlock = partitionBlock.SizeBlock,
                SizeOfVector = partitionBlock.SizeOfVector,
                FileSystemBlockSize = partitionBlock.FileSystemBlockSize
            };
        }

        public static FileSystemHeaderBlockViewModel ToViewModel(this FileSystemHeaderBlock fileSystemHeaderBlock)
        {
            return new FileSystemHeaderBlockViewModel
            {
                DosType = fileSystemHeaderBlock.DosType,
                DosTypeFormatted = fileSystemHeaderBlock.DosTypeFormatted,
                DosTypeHex = fileSystemHeaderBlock.DosTypeHex,
                Version = fileSystemHeaderBlock.Version,
                MajorVersion = fileSystemHeaderBlock.MajorVersion,
                MinorVersion = fileSystemHeaderBlock.MinorVersion
            };
        }
    }
}