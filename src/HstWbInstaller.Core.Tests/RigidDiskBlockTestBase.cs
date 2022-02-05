namespace HstWbInstaller.Core.Tests
{
    using System;
    using System.IO;
    using System.Threading.Tasks;
    using IO.RigidDiskBlocks;

    public abstract class RigidDiskBlockTestBase
    {
        protected RigidDiskBlock CreateRigidDiskBlock(long size)
        {
            var rigidDiskBlock = new RigidDiskBlock();
            
            var blocksPerCylinder = rigidDiskBlock.Heads * rigidDiskBlock.Sectors;
            var cylinders = (uint)Math.Floor((double)size / (blocksPerCylinder * rigidDiskBlock.BlockSize));
            rigidDiskBlock.Cylinders = cylinders;
            rigidDiskBlock.ParkingZone = cylinders;
            rigidDiskBlock.ReducedWrite = cylinders;
            rigidDiskBlock.WritePreComp = cylinders;

            return rigidDiskBlock;
        }
        
        protected PartitionBlock CreatePartitionBlock(RigidDiskBlock rigidDiskBlock, uint startCylinder, long size,
            byte[] dosType, string driveName, uint reserved = 2, bool bootable = false)
        {
            var blocksPerCylinder = rigidDiskBlock.Heads * rigidDiskBlock.Sectors;
            var cylinders = (uint)Math.Floor((double)size / (blocksPerCylinder * rigidDiskBlock.BlockSize));

            return new PartitionBlock
            {
                DosType = dosType,
                DriveName = driveName,
                Flags = bootable ? (uint)PartitionBlock.PartitionFlagsEnum.Bootable : 0,
                Reserved = reserved,
                LowCyl = startCylinder + reserved,
                HighCyl = startCylinder + cylinders
            };
        }

        protected async Task<FileSystemHeaderBlock> CreateFileSystemHeaderBlock()
        {
            await using var pfs3AioStream = new MemoryStream(await File.ReadAllBytesAsync(@"TestData\pfs3aio"));

            return
                await BlockHelper.CreateFileSystemHeaderBlock(FormatHelper.FormatDosType("PDS", 3), 19, 2,
                    pfs3AioStream);
        }
    }
}