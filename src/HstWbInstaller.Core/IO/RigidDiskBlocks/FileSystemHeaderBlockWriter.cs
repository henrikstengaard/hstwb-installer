namespace HstWbInstaller.Core.IO.RigidDiskBlocks
{
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;

    public static class FileSystemHeaderBlockWriter
    {
        public static async Task<byte[]> BuildBlock(FileSystemHeaderBlock fileSystemHeaderBlock)
        {
            var blockStream = new MemoryStream(BlockSize.FileSystemHeaderBlock * 4);

            await blockStream.WriteAsciiString(BlockIdentifiers.FileSystemHeaderBlock);
            await blockStream.WriteLittleEndianUInt32(BlockSize.FileSystemHeaderBlock); // size
            await blockStream.WriteLittleEndianInt32(0); // checksum, calculated when block is built
            await blockStream.WriteLittleEndianUInt32(fileSystemHeaderBlock
                .HostId); // SCSI Target ID of host, not really used 
            await blockStream.WriteLittleEndianUInt32(fileSystemHeaderBlock
                .NextFileSysHeaderBlock); // Block number of the next FileSysHeaderBlock
            await blockStream.WriteLittleEndianUInt32(fileSystemHeaderBlock.Flags); // Flags
// 11 diff
            // read reserved, unused word
            var reservedBytes = new byte[4];
            for (var i = 0; i < 2; i++)
            {
                await blockStream.WriteBytes(reservedBytes);
            }

            await blockStream
                .WriteBytes(fileSystemHeaderBlock
                    .DosType); // # Dostype of the file system, file system description: match this with partition environment's DE_DOSTYPE entry
            await blockStream.WriteLittleEndianUInt32(fileSystemHeaderBlock
                .Version); // filesystem version 0x0027001b == 39.27
            await blockStream.WriteLittleEndianUInt32(fileSystemHeaderBlock.PatchFlags);
            await blockStream.WriteLittleEndianUInt32(fileSystemHeaderBlock.Type);
            await blockStream.WriteLittleEndianUInt32(fileSystemHeaderBlock.Task);
            await blockStream.WriteLittleEndianUInt32(fileSystemHeaderBlock.Lock);
            await blockStream.WriteLittleEndianUInt32(fileSystemHeaderBlock.Handler);
            await blockStream.WriteLittleEndianUInt32(fileSystemHeaderBlock.StackSize);
            await blockStream.WriteLittleEndianInt32(fileSystemHeaderBlock.Priority);
            await blockStream.WriteLittleEndianInt32(fileSystemHeaderBlock.Startup);
            await blockStream.WriteLittleEndianInt32(fileSystemHeaderBlock
                .SegListBlocks); // first of linked list of LoadSegBlocks
            await blockStream.WriteLittleEndianInt32(fileSystemHeaderBlock.GlobalVec);

            // read reserved, unused word
            for (var i = 0; i < 23 + 21; i++)
            {
                await blockStream.WriteBytes(reservedBytes);
            }

            // calculate and update checksum
            var blockBytes = blockStream.ToArray();
            await BlockHelper.UpdateChecksum(blockBytes, 8);

            return blockBytes;
        }

        // public static async Task<byte[]> WriteBlock(RigidDiskBlock rigidDiskBlock,
        //     FileSystemHeaderBlock fileSystemHeaderBlock, Stream stream, long offset)
        // {
        //     // calculate file system header block offset
        //     var blockOffset = rigidDiskBlock.BlockSize * fileSysHdrList;
        //
        //     // seek partition block offset
        //     stream.Seek(fileSystemHeaderBlockOffset, SeekOrigin.Begin);
        //
        //
        //     fileSystemHeaderBlock.
        // }
    }
}