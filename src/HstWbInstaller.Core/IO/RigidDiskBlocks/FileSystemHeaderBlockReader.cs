namespace HstWbInstaller.Core.IO.RigidDiskBlocks
{
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using Extensions;

    public static class FileSystemHeaderBlockReader
    {
        public static async Task<IEnumerable<FileSystemHeaderBlock>> Read(
            RigidDiskBlock rigidDiskBlock, Stream stream)
        {
            if (rigidDiskBlock.FileSysHdrList == BlockIdentifiers.EndOfBlock)
            {
                return Enumerable.Empty<FileSystemHeaderBlock>();
            }
            
            var fileSystemHeaderBlocks = new List<FileSystemHeaderBlock>();

            var fileSysHdrList = rigidDiskBlock.FileSysHdrList;

            do
            {
                // calculate file system header block offset
                var fileSystemHeaderBlockOffset = rigidDiskBlock.BlockSize * fileSysHdrList;

                // seek partition block offset
                stream.Seek(fileSystemHeaderBlockOffset, SeekOrigin.Begin);

                // read block
                var block = await BlockHelper.ReadBlock(stream);

                // parse file system header block
                var fileSystemHeaderBlock = await Parse(block);

                fileSystemHeaderBlocks.Add(fileSystemHeaderBlock);

                // get next partition list block and increase partition number
                fileSysHdrList = fileSystemHeaderBlock.NextFileSysHeaderBlock;
            } while (fileSysHdrList > 0 && fileSysHdrList != BlockIdentifiers.EndOfBlock);

            foreach (var fileSystemHeaderBlock in fileSystemHeaderBlocks)
            {
                fileSystemHeaderBlock.LoadSegBlocks =
                    await LoadSegBlockReader.Read(rigidDiskBlock, fileSystemHeaderBlock, stream);
            }

            return fileSystemHeaderBlocks;
        }

        public static async Task<FileSystemHeaderBlock> Parse(byte[] blockBytes)
        {
            var blockStream = new MemoryStream(blockBytes);

            var identifier = await blockStream.ReadAsciiString(); // Identifier 32 bit word : 'RDSK'
            if (!identifier.Equals(BlockIdentifiers.FileSystemHeaderBlock))
            {
                throw new IOException("Invalid file system header block identifier");
            }

            await blockStream.ReadUInt32(); // Size of the structure for checksums
            var checksum = await blockStream.ReadInt32(); // Checksum of the structure
            var hostId = await blockStream.ReadUInt32(); // SCSI Target ID of host, not really used
            var nextFileSysHeaderBlock = await blockStream.ReadUInt32(); // Block number of the next FileSysHeaderBlock
            var flags = await blockStream.ReadUInt32(); // Flags

            // read reserved, unused word
            for (var i = 0; i < 2; i++)
            {
                await blockStream.ReadBytes(4);
            }

            var dosType =
                await blockStream
                    .ReadBytes(4); // # Dostype of the file system, file system description: match this with partition environment's DE_DOSTYPE entry
            var version = await blockStream.ReadUInt32(); // filesystem version 0x0027001b == 39.27
            var patchFlags = await blockStream.ReadUInt32();
            var type = await blockStream.ReadUInt32();
            var task = await blockStream.ReadUInt32();
            var fileSysLock = await blockStream.ReadUInt32();
            var handler = await blockStream.ReadUInt32();
            var stackSize = await blockStream.ReadUInt32();
            var priority = await blockStream.ReadInt32();
            var startup = await blockStream.ReadInt32();
            var segListBlocks = await blockStream.ReadInt32(); // first of linked list of LoadSegBlocks
            var globalVec = await blockStream.ReadInt32();

            // skip reserved
            blockStream.Seek(4 * (23 + 21), SeekOrigin.Current);

            var calculatedChecksum = await BlockHelper.CalculateChecksum(blockBytes, 8);

            if (checksum != calculatedChecksum)
            {
                throw new IOException("Invalid file system header block checksum");
            }

            return new FileSystemHeaderBlock
            {
                BlockBytes = blockBytes,
                Checksum = checksum,
                HostId = hostId,
                NextFileSysHeaderBlock = nextFileSysHeaderBlock,
                Flags = flags,
                DosType = dosType,
                Version = version,
                PatchFlags = patchFlags,
                Type = type,
                Task = task,
                Lock = fileSysLock,
                Handler = handler,
                StackSize = stackSize,
                Priority = priority,
                Startup = startup,
                SegListBlocks = segListBlocks,
                GlobalVec = globalVec
            };
        }
    }
}