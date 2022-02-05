namespace HstWbInstaller.Core.IO.RigidDiskBlocks
{
    using System;
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;

    public static class RigidDiskBlockWriter
    {
        public static async Task<byte[]> BuildBlock(RigidDiskBlock rigidDiskBlock)
        {
            var blockStream = new MemoryStream(BlockSize.RigidDiskBlock * 4);

            await blockStream.WriteAsciiString(BlockIdentifiers.RigidDiskBlock);
            await blockStream.WriteLittleEndianUInt32(BlockSize.RigidDiskBlock); // size
            await blockStream.WriteLittleEndianInt32(0); // checksum, calculated when block is built

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
            await BlockHelper.UpdateChecksum(blockBytes, 8);

            return blockBytes;
        }

        public static async Task WriteBlock(RigidDiskBlock rigidDiskBlock, Stream stream, long offset = 0)
        {
            if (offset % 512 != 0)
            {
                throw new ArgumentException("Offset must be dividable by 512", nameof(offset));
            }

            var highRsdkBlock = 1U;
            
            var rigidDiskBlockIndex = offset == 0 ? 0 : (uint)offset / 512;
            var partitionBlockIndex = rigidDiskBlockIndex + 1;
            rigidDiskBlock.PartitionList = partitionBlockIndex;
            
            var partitionBlocks = rigidDiskBlock.PartitionBlocks.ToList();

            for (var p = 0; p < partitionBlocks.Count; p++)
            {
                var partitionBlock = partitionBlocks[p];
                
                partitionBlock.NextPartitionBlock = p < partitionBlocks.Count - 1
                    ? (uint)(partitionBlockIndex + p + 1)
                    : BlockIdentifiers.EndOfBlock;

                if (partitionBlockIndex + p > highRsdkBlock)
                {
                    highRsdkBlock = (uint)(partitionBlockIndex + p);
                }
            }

            var fileSystemHeaderBlocks = rigidDiskBlock.FileSystemHeaderBlocks.ToList();
            var fileSystemHeaderBlockIndex = (uint)(partitionBlockIndex + partitionBlocks.Count);
            rigidDiskBlock.FileSysHdrList = fileSystemHeaderBlockIndex;
            
            for (var f = 0; f < fileSystemHeaderBlocks.Count; f++)
            {
                var fileSystemHeaderBlock = fileSystemHeaderBlocks[f];
                var loadSegBlocks = fileSystemHeaderBlock.LoadSegBlocks.ToList();

                fileSystemHeaderBlock.NextFileSysHeaderBlock = f < partitionBlocks.Count - 1
                    ? (uint)(fileSystemHeaderBlockIndex + f + 1 + loadSegBlocks.Count)
                    : BlockIdentifiers.EndOfBlock;
                fileSystemHeaderBlock.SegListBlocks = (int)(fileSystemHeaderBlockIndex + f + 1);

                if (fileSystemHeaderBlockIndex + f + loadSegBlocks.Count > highRsdkBlock)
                {
                    highRsdkBlock = (uint)(fileSystemHeaderBlockIndex + f + loadSegBlocks.Count);
                }
                
                for (var l = 0; l < loadSegBlocks.Count; l++)
                {
                    var loadSegBlock = loadSegBlocks[l];

                    loadSegBlock.NextLoadSegBlock = l < loadSegBlocks.Count - 1
                        ? (int)(fileSystemHeaderBlockIndex + f + 2 + l)
                        : -1;
                    
                }
            }

            rigidDiskBlock.HighRsdkBlock = highRsdkBlock;
            
            // seek rigid disk block offset
            stream.Seek(rigidDiskBlockIndex * 512, SeekOrigin.Begin);

            var rigidDiskBlockBytes = await BuildBlock(rigidDiskBlock);

            await stream.WriteBytes(rigidDiskBlockBytes);
            
            // seek partition block index offset
            stream.Seek(partitionBlockIndex * 512, SeekOrigin.Begin);

            foreach (var partitionBlock in rigidDiskBlock.PartitionBlocks)
            {
                var partitionBlockBytes = await PartitionBlockWriter.BuildBlock(partitionBlock);
                
                await stream.WriteBytes(partitionBlockBytes);

                // calculate partition start offset
                // var partitionStartOffset = (rigidDiskBlock.RdbBlockHi + 1 + partitionBlock.LowCyl - partitionBlock.Reserved) * 512;
                //
                // // seek next partition block index offset
                // stream.Seek(partitionStartOffset, SeekOrigin.Begin);
                //
                // await stream.WriteBytes(partitionBlock.DosType);
                
                if (partitionBlock.NextPartitionBlock == BlockIdentifiers.EndOfBlock)
                {
                    break;
                }
                
                // seek next partition block index offset
                stream.Seek(partitionBlock.NextPartitionBlock * 512, SeekOrigin.Begin);
            }

            // seek file system header block index offset
            stream.Seek(fileSystemHeaderBlockIndex * 512, SeekOrigin.Begin);
            
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
    }
}