namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System;
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;
    using RigidDiskBlocks;

    public static class FileExtBlockWriter
    {
        public static async Task<byte[]> BuildBlock(FileExtBlock fileExtBlock, uint blockSize)
        {
            var blockStream =
                new MemoryStream(
                    fileExtBlock.BlockBytes == null || fileExtBlock.BlockBytes.Length == 0
                        ? new byte[blockSize]
                        : fileExtBlock.BlockBytes);

            await blockStream.WriteLittleEndianInt32(fileExtBlock.type);
            await blockStream.WriteLittleEndianInt32(fileExtBlock.headerKey);
            await blockStream.WriteLittleEndianInt32(fileExtBlock.highSeq);
            await blockStream.WriteLittleEndianInt32(fileExtBlock.dataSize);
            await blockStream.WriteLittleEndianInt32(fileExtBlock.firstData);
            await blockStream.WriteLittleEndianUInt32(0); // checksum

            for (var i = 0; i < Constants.MAX_DATABLK; i++)
            {
                await blockStream.WriteLittleEndianInt32(fileExtBlock.dataBlocks[i]);
            }
            
            for (var i = 0; i < 45; i++)
            {
                await blockStream.WriteLittleEndianInt32(0);
            }

            await blockStream.WriteLittleEndianInt32(fileExtBlock.info);
            await blockStream.WriteLittleEndianInt32(fileExtBlock.nextSameHash);
            await blockStream.WriteLittleEndianInt32(fileExtBlock.parent);
            await blockStream.WriteLittleEndianInt32(fileExtBlock.extension);
            await blockStream.WriteLittleEndianInt32(fileExtBlock.secType);
            
            var blockBytes = blockStream.ToArray();
            var newSum = Raw.AdfNormalSum(blockBytes, 20, blockBytes.Length);
            // swLong(buf+20, newSum);
            var checksumBytes = LittleEndianConverter.ConvertToBytes(newSum);
            Array.Copy(checksumBytes, 0, blockBytes, 20, checksumBytes.Length);

            fileExtBlock.BlockBytes = blockBytes;

            return blockBytes;
        }
    }
}