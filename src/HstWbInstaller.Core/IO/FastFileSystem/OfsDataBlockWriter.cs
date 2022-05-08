namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System;
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;
    using RigidDiskBlocks;

    public static class OfsDataBlockWriter
    {
        public static async Task<byte[]> BuildBlock(OfsDataBlock ofsDataBlock, uint blockSize)
        {
            var blockStream =
                new MemoryStream(
                    ofsDataBlock.BlockBytes == null || ofsDataBlock.BlockBytes.Length == 0
                        ? new byte[blockSize]
                        : ofsDataBlock.BlockBytes);

            await blockStream.WriteLittleEndianInt32(ofsDataBlock.Type); // 0x000
            await blockStream.WriteLittleEndianInt32(ofsDataBlock.HeaderKey); // 0x004
            await blockStream.WriteLittleEndianInt32(ofsDataBlock.SeqNum); // 0x008
            await blockStream.WriteLittleEndianInt32(ofsDataBlock.DataSize); // 0x0c
            await blockStream.WriteLittleEndianInt32(ofsDataBlock.NextData); // 0x10
            await blockStream.WriteLittleEndianUInt32(0); // 0x014: checksum
            await blockStream.WriteBytes(ofsDataBlock.Data); // 0x018 : data
            
            var blockBytes = blockStream.ToArray();
            var newSum = Raw.AdfNormalSum(blockBytes, 20, blockBytes.Length);
            // swLong(buf+20, newSum);
            var checksumBytes = LittleEndianConverter.ConvertToBytes(newSum);
            Array.Copy(checksumBytes, 0, blockBytes, 20, checksumBytes.Length);

            ofsDataBlock.BlockBytes = blockBytes;

            return blockBytes;
        }
    }
}