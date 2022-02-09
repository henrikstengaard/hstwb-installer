namespace HstWbInstaller.Core.IO.RigidDiskBlocks
{
    using System;
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;

    public static class BadBlockWriter
    {
        public static async Task<byte[]> BuildBlock(BadBlock badBlock)
        {
            if (badBlock.Data.Length % 4 != 0)
            {
                throw new ArgumentException("Bad block data must be dividable by 4", nameof(BadBlock.Data));
            }

            var structureSize = 6 * 4;
            var maxDataSize = 512 - structureSize;
            if (badBlock.Data.Length > maxDataSize)
            {
                throw new ArgumentException($"Bad block data is larger than max data size {maxDataSize}",
                    nameof(LoadSegBlock.Data));
            }

            var blockStream = new MemoryStream(badBlock.BlockBytes == null || badBlock.BlockBytes.Length == 0
                ? new byte[structureSize + badBlock.Data.Length]
                : badBlock.BlockBytes);
            var size = (structureSize + badBlock.Data.Length) / 4;

            await blockStream.WriteAsciiString(BlockIdentifiers.BadBlock);
            await blockStream.WriteLittleEndianUInt32((uint)size); // size

            // skip checksum, calculated when block is built
            blockStream.Seek(4, SeekOrigin.Current);

            await blockStream.WriteLittleEndianUInt32(badBlock.HostId); // SCSI Target ID of host, not really used 
            await blockStream.WriteLittleEndianUInt32(badBlock.NextBadBlock); // next BadBlock block

            // skip reserved
            blockStream.Seek(4, SeekOrigin.Current);

            // bad block data
            await blockStream.WriteBytes(badBlock.Data);

            // calculate and update checksum
            var blockBytes = blockStream.ToArray();
            badBlock.Checksum = await BlockHelper.UpdateChecksum(blockBytes, 8);
            badBlock.BlockBytes = blockBytes;

            return blockBytes;
        }
    }
}