namespace HstWbInstaller.Core.IO.RigidDiskBlocks
{
    using System;
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;

    public static class LoadSegBlockWriter
    {
        public static async Task<byte[]> BuildBlock(LoadSegBlock loadSegBlock)
        {
            if (loadSegBlock.Data.Length % 4 != 0)
            {
                throw new ArgumentException("Load seg block data must be dividable by 4", nameof(LoadSegBlock.Data));
            }

            var structureSize = 5 * 4;
            var maxDataSize = 512 - structureSize;
            if (loadSegBlock.Data.Length > maxDataSize)
            {
                throw new ArgumentException($"Load seg block data is larger than max data size {maxDataSize}",
                    nameof(LoadSegBlock.Data));
            }

            var blockStream = new MemoryStream(loadSegBlock.BlockBytes == null || loadSegBlock.BlockBytes.Length == 0
                ? new byte[structureSize + loadSegBlock.Data.Length]
                : loadSegBlock.BlockBytes);
            var size = (structureSize + loadSegBlock.Data.Length) / 4;

            await blockStream.WriteAsciiString(BlockIdentifiers.LoadSegBlock);
            await blockStream.WriteLittleEndianUInt32((uint)size); // size

            // skip checksum, calculated when block is built
            blockStream.Seek(4, SeekOrigin.Current);

            await blockStream.WriteLittleEndianUInt32(loadSegBlock.HostId); // SCSI Target ID of host, not really used 
            await blockStream.WriteLittleEndianInt32(loadSegBlock
                .NextLoadSegBlock); // Block number of the next PartitionBlock

            await blockStream.WriteBytes(loadSegBlock.Data);

            // calculate and update checksum
            var blockBytes = blockStream.ToArray();
            loadSegBlock.Checksum = await ChecksumHelper.UpdateChecksum(blockBytes, 8);
            loadSegBlock.BlockBytes = blockBytes;

            return blockBytes;
        }
    }
}