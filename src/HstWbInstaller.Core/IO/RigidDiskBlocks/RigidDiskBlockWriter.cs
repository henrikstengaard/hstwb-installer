namespace HstWbInstaller.Core.IO.RigidDiskBlocks
{
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;

    public static class RigidDiskBlockWriter
    {
        public static async Task<byte[]> BuildBlock(RigidDiskBlock rigidDiskBlock)
        {
            var blockStream =
                new MemoryStream(rigidDiskBlock.BlockBytes == null || rigidDiskBlock.BlockBytes.Length == 0
                    ? new byte[BlockSize.RigidDiskBlock * 4]
                    : rigidDiskBlock.BlockBytes);

            await blockStream.WriteAsciiString(BlockIdentifiers.RigidDiskBlock);
            await blockStream.WriteLittleEndianUInt32(BlockSize.RigidDiskBlock); // size

            // skip checksum, calculated when block is built
            blockStream.Seek(4, SeekOrigin.Current);

            await blockStream.WriteLittleEndianUInt32(rigidDiskBlock.HostId); // SCSI Target ID of host, not really used
            await blockStream.WriteLittleEndianUInt32(rigidDiskBlock.BlockSize); // Size of disk blocks
            await blockStream.WriteLittleEndianUInt32(rigidDiskBlock.Flags); // RDB Flags
            await blockStream.WriteLittleEndianUInt32(rigidDiskBlock.BadBlockList); // Bad block list
            await blockStream.WriteLittleEndianUInt32(rigidDiskBlock.PartitionList); // Partition list
            await blockStream.WriteLittleEndianUInt32(rigidDiskBlock.FileSysHdrList); // File system header list
            await blockStream.WriteLittleEndianUInt32(rigidDiskBlock.DriveInitCode); // Drive specific init code
            await blockStream.WriteLittleEndianUInt32(rigidDiskBlock.BootBlockList); // Amiga OS 4 Boot Blocks

            // read reserved, unused word, need to be set to $ffffffff
            var reservedBytes = new byte[] { 255, 255, 255, 255 };
            for (var i = 0; i < 5; i++)
            {
                await blockStream.WriteBytes(reservedBytes);
            }

            // physical drive characteristics
            await blockStream.WriteLittleEndianUInt32(rigidDiskBlock.Cylinders); // Number of the cylinders of the drive
            await blockStream.WriteLittleEndianUInt32(rigidDiskBlock.Sectors); // Number of sectors of the drive
            await blockStream.WriteLittleEndianUInt32(rigidDiskBlock.Heads); // Number of heads of the drive
            await blockStream.WriteLittleEndianUInt32(rigidDiskBlock.Interleave); // Interleave 
            await blockStream.WriteLittleEndianUInt32(rigidDiskBlock.ParkingZone); // Head parking cylinder

            // read reserved, unused word, need to be set to $ffffffff
            reservedBytes = new byte[4];
            for (var i = 0; i < 3; i++)
            {
                await blockStream.WriteBytes(reservedBytes);
            }

            await blockStream.WriteLittleEndianUInt32(rigidDiskBlock
                .WritePreComp); // Starting cylinder of write pre-compensation 
            await blockStream.WriteLittleEndianUInt32(rigidDiskBlock
                .ReducedWrite); // Starting cylinder of reduced write current
            await blockStream.WriteLittleEndianUInt32(rigidDiskBlock.StepRate); // Step rate of the drive

            // read reserved, unused word, need to be set to $ffffffff
            for (var i = 0; i < 5; i++)
            {
                await blockStream.WriteBytes(reservedBytes);
            }

            // logical drive characteristics
            await blockStream.WriteLittleEndianUInt32(rigidDiskBlock
                .RdbBlockLo); // low block of range reserved for hardblocks
            await blockStream.WriteLittleEndianUInt32(rigidDiskBlock
                .RdbBlockHi); // high block of range for these hardblocks
            await blockStream.WriteLittleEndianUInt32(rigidDiskBlock
                .LoCylinder); // low cylinder of partitionable disk area
            await blockStream.WriteLittleEndianUInt32(rigidDiskBlock
                .HiCylinder); // high cylinder of partitionable data area
            await blockStream.WriteLittleEndianUInt32(rigidDiskBlock
                .CylBlocks); // number of blocks available per cylinder
            await blockStream.WriteLittleEndianUInt32(rigidDiskBlock.AutoParkSeconds); // zero for no auto park
            await blockStream.WriteLittleEndianUInt32(rigidDiskBlock
                .HighRsdkBlock); // highest block used by RDSK (not including replacement bad blocks)

            await blockStream.WriteBytes(reservedBytes); // read reserved, unused word

            // drive identification
            await blockStream.WriteString(rigidDiskBlock.DiskVendor, 8, 32);
            await blockStream.WriteString(rigidDiskBlock.DiskProduct, 16, 32);
            await blockStream.WriteString(rigidDiskBlock.DiskRevision, 4, 32);

            // write controller vendor
            if (!string.IsNullOrWhiteSpace(rigidDiskBlock.ControllerVendor))
            {
                await blockStream.WriteString(rigidDiskBlock.ControllerVendor, 8, 32);
            }
            else
            {
                await blockStream.WriteBytes(new byte[8]);
            }

            // write controller product
            if (!string.IsNullOrWhiteSpace(rigidDiskBlock.ControllerProduct))
            {
                await blockStream.WriteString(rigidDiskBlock.ControllerProduct, 16, 32);
            }
            else
            {
                await blockStream.WriteBytes(new byte[16]);
            }

            // write controller revision
            if (!string.IsNullOrWhiteSpace(rigidDiskBlock.ControllerRevision))
            {
                await blockStream.WriteString(rigidDiskBlock.ControllerRevision, 4, 32);
            }
            else
            {
                await blockStream.WriteBytes(new byte[4]);
            }

            await blockStream.WriteBytes(reservedBytes); // read reserved, unused word

            // calculate and update checksum
            var blockBytes = blockStream.ToArray();
            rigidDiskBlock.Checksum = await BlockHelper.UpdateChecksum(blockBytes, 8);
            rigidDiskBlock.BlockBytes = blockBytes;

            return blockBytes;
        }

        public static async Task WriteBlock(RigidDiskBlock rigidDiskBlock, Stream stream)
        {
            // update block pointers to maintain rigid disk block structure
            BlockHelper.UpdateBlockPointers(rigidDiskBlock);

            // seek rigid disk block offset
            stream.Seek(rigidDiskBlock.RdbBlockLo * 512, SeekOrigin.Begin);

            var rigidDiskBlockBytes = await BuildBlock(rigidDiskBlock);

            await stream.WriteBytes(rigidDiskBlockBytes);

            if (rigidDiskBlock.PartitionList != BlockIdentifiers.EndOfBlock)
            {
                // seek partition block index offset
                stream.Seek(rigidDiskBlock.PartitionList * 512, SeekOrigin.Begin);

                foreach (var partitionBlock in rigidDiskBlock.PartitionBlocks)
                {
                    var partitionBlockBytes = await PartitionBlockWriter.BuildBlock(partitionBlock);

                    await stream.WriteBytes(partitionBlockBytes);

                    if (partitionBlock.NextPartitionBlock == BlockIdentifiers.EndOfBlock)
                    {
                        break;
                    }

                    // seek next partition block index offset
                    stream.Seek(partitionBlock.NextPartitionBlock * 512, SeekOrigin.Begin);
                }
            }

            if (rigidDiskBlock.FileSysHdrList != BlockIdentifiers.EndOfBlock)
            {
                // seek file system header block index offset
                stream.Seek(rigidDiskBlock.FileSysHdrList * 512, SeekOrigin.Begin);

                foreach (var fileSystemHeaderBlock in rigidDiskBlock.FileSystemHeaderBlocks)
                {
                    var fileSystemHeaderBytes = await FileSystemHeaderBlockWriter.BuildBlock(fileSystemHeaderBlock);

                    await stream.WriteBytes(fileSystemHeaderBytes);

                    // seek load seg block index offset
                    stream.Seek(fileSystemHeaderBlock.SegListBlocks * 512, SeekOrigin.Begin);

                    foreach (var loadSegBlock in fileSystemHeaderBlock.LoadSegBlocks)
                    {
                        var loadSegBlockBytes = await LoadSegBlockWriter.BuildBlock(loadSegBlock);

                        await stream.WriteBytes(loadSegBlockBytes);

                        if (loadSegBlock.NextLoadSegBlock == -1)
                        {
                            break;
                        }

                        // seek next load seg block index offset
                        stream.Seek(loadSegBlock.NextLoadSegBlock * 512, SeekOrigin.Begin);
                    }

                    if (fileSystemHeaderBlock.NextFileSysHeaderBlock == BlockIdentifiers.EndOfBlock)
                    {
                        break;
                    }

                    // seek next file system header block index offset
                    stream.Seek(fileSystemHeaderBlock.NextFileSysHeaderBlock * 512, SeekOrigin.Begin);
                }
            }

            if (rigidDiskBlock.BadBlockList != BlockIdentifiers.EndOfBlock)
            {
                // seek bad block index offset
                stream.Seek(rigidDiskBlock.BadBlockList * 512, SeekOrigin.Begin);

                foreach (var badBlock in rigidDiskBlock.BadBlocks)
                {
                    var badBlockBytes = await BadBlockWriter.BuildBlock(badBlock);

                    await stream.WriteBytes(badBlockBytes);

                    if (badBlock.NextBadBlock == BlockIdentifiers.EndOfBlock)
                    {
                        break;
                    }

                    // seek next bad block index offset
                    stream.Seek(badBlock.NextBadBlock * 512, SeekOrigin.Begin);
                }
            }
        }
    }
}