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

            var maxSize = 512 - (6 * 4);
            if (badBlock.Data.Length > maxSize)
            {
                throw new ArgumentException($"Bad block data is larger than max size {maxSize}",
                    nameof(LoadSegBlock.Data));
            }

            var size = badBlock.Data.Length / 4 + 6;
            var blockStream = new MemoryStream(size);

            await blockStream.WriteAsciiString(BlockIdentifiers.BadBlock);
            await blockStream.WriteLittleEndianUInt32((uint)size); // size
            await blockStream.WriteLittleEndianInt32(0); // checksum, calculated when block is built
            await blockStream.WriteLittleEndianUInt32(badBlock.HostId); // SCSI Target ID of host, not really used 
            await blockStream.WriteLittleEndianUInt32(badBlock.NextBadBlock); // next BadBlock block
            
            // reserved
            await blockStream.WriteBytes(new byte[4]);

            // bad block data
            await blockStream.WriteBytes(badBlock.Data);

            // calculate and update checksum
            var blockBytes = blockStream.ToArray();
            await BlockHelper.UpdateChecksum(blockBytes, 8);

            return blockBytes;
        }
    }
}