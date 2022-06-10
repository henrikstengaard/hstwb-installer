namespace HstWbInstaller.Core.IO.RigidDiskBlocks
{
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using Extensions;

    public static class PartitionBlockReader
    {
        public static async Task<IEnumerable<PartitionBlock>> Read(RigidDiskBlock rigidDiskBlock, Stream stream)
        {
            if (rigidDiskBlock.PartitionList == BlockIdentifiers.EndOfBlock)
            {
                return Enumerable.Empty<PartitionBlock>();
            }


            // get partition list block and set partition number to 1
            var partitionList = rigidDiskBlock.PartitionList;

            var partitionBlocks = new List<PartitionBlock>();

            do
            {
                // calculate partition block offset
                var partitionBlockOffset = rigidDiskBlock.BlockSize * partitionList;

                // seek partition block offset
                stream.Seek(partitionBlockOffset, SeekOrigin.Begin);

                // read block
                var blockBytes = await BlockHelper.ReadBlock(stream);

                // read partition block
                var partitionBlock = await Parse(rigidDiskBlock, blockBytes);

                // fail, if partition block is null
                if (partitionBlock == null)
                {
                    throw new IOException("Invalid partition block");
                }

                partitionBlocks.Add(partitionBlock);

                // get next partition list block and increase partition number
                partitionList = partitionBlock.NextPartitionBlock;
            } while (partitionList > 0 && partitionList != BlockIdentifiers.EndOfBlock);

            rigidDiskBlock.PartitionBlocks = partitionBlocks;

            rigidDiskBlock.FileSystemHeaderBlocks =
                await FileSystemHeaderBlockReader.Read(rigidDiskBlock, stream);

            return partitionBlocks;
        }

        public static async Task<PartitionBlock> Parse(RigidDiskBlock rigidDiskBlock, byte[] blockBytes)
        {
            var blockStream = new MemoryStream(blockBytes);

            var magic = await blockStream.ReadAsciiString(); // Identifier 32 bit word : 'PART'
            if (!magic.Equals(BlockIdentifiers.PartitionBlock))
            {
                return null;
            }

            await blockStream.ReadUInt32(); // Size of the structure for checksums
            var checksum = await blockStream.ReadInt32(); // Checksum of the structure
            var hostId = await blockStream.ReadUInt32(); // SCSI Target ID of host, not really used 
            var nextPartitionBlock = await blockStream.ReadUInt32(); // Block number of the next PartitionBlock
            var flags = await blockStream.ReadUInt32(); // Part Flags (NOMOUNT and BOOTABLE)

            // skip reserved
            blockStream.Seek(4 * 2, SeekOrigin.Current);

            var devFlags = await blockStream.ReadUInt32(); // Preferred flags for OpenDevice
            var driveNameLength =
                (await blockStream.ReadBytes(1)).FirstOrDefault(); //  Preferred DOS device name: BSTR form
            var driveName = await blockStream.ReadString(driveNameLength); // # Preferred DOS device name: BSTR form

            if (driveNameLength < 31)
            {
                await blockStream.ReadBytes(31 - driveNameLength);
            }

            // skip reserved
            blockStream.Seek(4 * 15, SeekOrigin.Current);

            var sizeOfVector = await blockStream.ReadUInt32(); // Size of Environment vector
            var sizeBlock = await blockStream.ReadUInt32(); // Size of the blocks in 32 bit words, usually 128
            var secOrg = await blockStream.ReadUInt32(); // Not used; must be 0
            var surfaces = await blockStream.ReadUInt32(); // Number of heads (surfaces)
            var sectors = await blockStream.ReadUInt32(); // Disk sectors per block, used with SizeBlock, usually 1
            var blocksPerTrack = await blockStream.ReadUInt32(); // Blocks per track. drive specific
            var reserved = await blockStream.ReadUInt32(); // DOS reserved blocks at start of partition.
            var preAlloc = await blockStream.ReadUInt32(); // DOS reserved blocks at end of partition
            var interleave = await blockStream.ReadUInt32(); // Not used, usually 0
            var lowCyl = await blockStream.ReadUInt32(); // First cylinder of the partition
            var highCyl = await blockStream.ReadUInt32(); // Last cylinder of the partition
            var numBuffer = await blockStream.ReadUInt32(); // Initial # DOS of buffers.
            var bufMemType = await blockStream.ReadUInt32(); // Type of mem to allocate for buffers
            var maxTransfer = await blockStream.ReadUInt32(); // Max number of bytes to transfer at a time
            var mask = await blockStream.ReadUInt32(); // Address Mask to block out certain memory
            var bootPriority = await blockStream.ReadUInt32(); // Boot priority for autoboot
            var dosType = await blockStream.ReadBytes(4); // # Dostype of the file system
            var baud = await blockStream.ReadUInt32(); // Baud rate for serial handler
            var control = await blockStream.ReadUInt32(); // Control word for handler/filesystem 
            var bootBlocks = await blockStream.ReadUInt32(); // Number of blocks containing boot code 

            // skip reserved
            blockStream.Seek(4 * 12, SeekOrigin.Current);
            
            // calculate size of partition in bytes
            var partitionSize = (long)(highCyl - lowCyl + 1) * surfaces * blocksPerTrack * rigidDiskBlock.BlockSize;

            var calculatedChecksum = await ChecksumHelper.CalculateChecksum(blockBytes, 8);

            if (checksum != calculatedChecksum)
            {
                throw new Exception("Invalid partition block checksum");
            }

            var fileSystemBlockSize = sizeBlock * 4;

            return new PartitionBlock
            {
                BlockBytes = blockBytes,
                Checksum = checksum,
                HostId = hostId,
                NextPartitionBlock = nextPartitionBlock,
                Flags = flags,
                DevFlags = devFlags,
                DriveName = driveName,
                SizeOfVector = sizeOfVector,
                SizeBlock = sizeBlock,
                SecOrg = secOrg,
                Surfaces = surfaces,
                Sectors = sectors,
                BlocksPerTrack = blocksPerTrack,
                Reserved = reserved,
                PreAlloc = preAlloc,
                Interleave = interleave,
                LowCyl = lowCyl,
                HighCyl = highCyl,
                NumBuffer = numBuffer,
                BufMemType = bufMemType,
                MaxTransfer = maxTransfer,
                Mask = mask,
                BootPriority = bootPriority,
                DosType = dosType,
                Baud = baud,
                Control = control,
                BootBlocks = bootBlocks,
                PartitionSize = partitionSize,
                FileSystemBlockSize = fileSystemBlockSize,
            };
        }
    }
}