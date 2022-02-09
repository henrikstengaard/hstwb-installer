namespace HstWbInstaller.Core.IO.RigidDiskBlocks
{
    using System;
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;

    public static class PartitionBlockWriter
    {
        public static async Task<byte[]> BuildBlock(PartitionBlock partitionBlock)
        {
            var blockStream =
                new MemoryStream(partitionBlock.BlockBytes == null || partitionBlock.BlockBytes.Length == 0
                    ? new byte[BlockSize.PartitionBlock * 4]
                    : partitionBlock.BlockBytes);

            await blockStream.WriteAsciiString(BlockIdentifiers.PartitionBlock);
            await blockStream.WriteLittleEndianUInt32(BlockSize.PartitionBlock); // size

            // skip checksum, calculated when block is built
            blockStream.Seek(4, SeekOrigin.Current);

            await blockStream.WriteLittleEndianUInt32(partitionBlock
                .HostId); // SCSI Target ID of host, not really used 
            await blockStream.WriteLittleEndianUInt32(partitionBlock
                .NextPartitionBlock); // Block number of the next PartitionBlock
            await blockStream.WriteLittleEndianUInt32(partitionBlock.Flags); // Part Flags (NOMOUNT and BOOTABLE)

            // skip reserved
            blockStream.Seek(4 * 2, SeekOrigin.Current);

            await blockStream.WriteLittleEndianUInt32(partitionBlock.DevFlags); // Preferred flags for OpenDevice

            var driveName = partitionBlock.DriveName.Length > 31
                ? partitionBlock.DriveName.Substring(0, 31)
                : partitionBlock.DriveName;

            await blockStream.WriteBytes(new[] { Convert.ToByte(driveName.Length) });
            await blockStream.WriteString(driveName, 31);

            // skip reserved
            blockStream.Seek(4 * 15, SeekOrigin.Current);

            await blockStream.WriteLittleEndianUInt32(partitionBlock.SizeOfVector); // Size of Environment vector
            await blockStream.WriteLittleEndianUInt32(partitionBlock
                .SizeBlock); // Size of the blocks in 32 bit words, usually 128
            await blockStream.WriteLittleEndianUInt32(partitionBlock.SecOrg); // Not used; must be 0
            await blockStream.WriteLittleEndianUInt32(partitionBlock.Surfaces); // Number of heads (surfaces)
            await blockStream.WriteLittleEndianUInt32(partitionBlock
                .Sectors); // Disk sectors per block, used with SizeBlock, usually 1
            await blockStream.WriteLittleEndianUInt32(partitionBlock
                .BlocksPerTrack); // Blocks per track. drive specific
            await blockStream.WriteLittleEndianUInt32(partitionBlock
                .Reserved); // DOS reserved blocks at start of partition.
            await blockStream.WriteLittleEndianUInt32(partitionBlock
                .PreAlloc); // DOS reserved blocks at end of partition
            await blockStream.WriteLittleEndianUInt32(partitionBlock.Interleave); // Not used, usually 0
            await blockStream.WriteLittleEndianUInt32(partitionBlock.LowCyl); // First cylinder of the partition
            await blockStream.WriteLittleEndianUInt32(partitionBlock.HighCyl); // Last cylinder of the partition
            await blockStream.WriteLittleEndianUInt32(partitionBlock.NumBuffer); // Initial # DOS of buffers.
            await blockStream.WriteLittleEndianUInt32(partitionBlock.BufMemType); // Type of mem to allocate for buffers
            await blockStream.WriteLittleEndianUInt32(partitionBlock
                .MaxTransfer); // Max number of bytes to transfer at a time
            await blockStream.WriteLittleEndianUInt32(partitionBlock.Mask); // Address Mask to block out certain memory
            await blockStream.WriteLittleEndianUInt32(partitionBlock.BootPriority); // Boot priority for autoboot
            await blockStream.WriteBytes(partitionBlock.DosType); // # Dostype of the file system
            await blockStream.WriteLittleEndianUInt32(partitionBlock.Baud); // Baud rate for serial handler
            await blockStream.WriteLittleEndianUInt32(partitionBlock.Control); // Control word for handler/filesystem 
            await blockStream.WriteLittleEndianUInt32(partitionBlock
                .BootBlocks); // Number of blocks containing boot code 

            // skip reserved
            blockStream.Seek(4 * 12, SeekOrigin.Current);

            // calculate and update checksum
            var blockBytes = blockStream.ToArray();
            partitionBlock.Checksum = await BlockHelper.UpdateChecksum(blockBytes, 8);
            partitionBlock.BlockBytes = blockBytes;

            return blockBytes;
        }
    }
}