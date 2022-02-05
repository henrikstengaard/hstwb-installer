namespace HstWbInstaller.Core.IO.RigidDiskBlocks
{
    using System;
    using System.IO;
    using System.Threading.Tasks;

    public static class LoadSegBlockWriter
    {
        public static async Task<byte[]> BuildBlock(LoadSegBlock loadSegBlock)
        {
            if (loadSegBlock.Data.Length % 4 != 0)
            {
                throw new ArgumentException("Load seg block data must be dividable by 4", nameof(LoadSegBlock.Data));
            }

            var maxSize = 512 - (5 * 4);
            if (loadSegBlock.Data.Length > maxSize)
            {
                throw new ArgumentException($"Load seg block data is larger than max size {maxSize}",
                    nameof(LoadSegBlock.Data));
            }

            var size = loadSegBlock.Data.Length / 4 + 5;
            var blockStream = new MemoryStream(size);

            await blockStream.WriteAsciiString(BlockIdentifiers.LoadSegBlock);
            await blockStream.WriteLittleEndianUInt32((uint)size); // size
            await blockStream.WriteLittleEndianInt32(0); // checksum, calculated when block is built
            await blockStream.WriteLittleEndianUInt32(loadSegBlock.HostId); // SCSI Target ID of host, not really used 
            await blockStream.WriteLittleEndianInt32(loadSegBlock
                .NextLoadSegBlock); // Block number of the next PartitionBlock

            await blockStream.WriteBytes(loadSegBlock.Data);

            // calculate and update checksum
            var blockBytes = blockStream.ToArray();
            await BlockHelper.UpdateChecksum(blockBytes, 8);

            return blockBytes;
        }
    }
}