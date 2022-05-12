namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System;
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;
    using RigidDiskBlocks;

    public static class DirCacheBlockWriter
    {
        public static async Task<byte[]> BuildBlock(DirCacheBlock dirCacheBlock, uint blockSize)
        {
            var blockStream =
                new MemoryStream(
                    dirCacheBlock.BlockBytes == null || dirCacheBlock.BlockBytes.Length == 0
                        ? new byte[blockSize]
                        : dirCacheBlock.BlockBytes);

            await blockStream.WriteLittleEndianInt32(dirCacheBlock.Type);
            await blockStream.WriteLittleEndianInt32(dirCacheBlock.HeaderKey);
            await blockStream.WriteLittleEndianInt32(dirCacheBlock.Parent);
            await blockStream.WriteLittleEndianInt32(dirCacheBlock.RecordsNb);
            await blockStream.WriteLittleEndianInt32(dirCacheBlock.NextDirC);
            await blockStream.WriteLittleEndianUInt32(0); // checksum

            await blockStream.WriteBytes(dirCacheBlock.Records);
            
            var blockBytes = blockStream.ToArray();
            var newSum = Raw.AdfNormalSum(blockBytes, 20, blockBytes.Length);
            // swLong(buf+20, newSum);
            var checksumBytes = LittleEndianConverter.ConvertToBytes(newSum);
            Array.Copy(checksumBytes, 0, blockBytes, 20, checksumBytes.Length);

            dirCacheBlock.BlockBytes = blockBytes;

            return blockBytes;
        }
    }
}