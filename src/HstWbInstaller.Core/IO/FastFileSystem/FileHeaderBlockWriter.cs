namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System;
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;
    using RigidDiskBlocks;

    public static class FileHeaderBlockWriter
    {
        public static async Task<byte[]> BuildBlock(FileHeaderBlock fileHeaderBlock, uint blockSize)
        {
            var blockStream =
                new MemoryStream(
                    fileHeaderBlock.BlockBytes == null || fileHeaderBlock.BlockBytes.Length == 0
                        ? new byte[blockSize]
                        : fileHeaderBlock.BlockBytes);

            await blockStream.WriteLittleEndianInt32(fileHeaderBlock.type);
            await blockStream.WriteLittleEndianInt32(fileHeaderBlock.HeaderKey);
            await blockStream.WriteLittleEndianInt32(fileHeaderBlock.highSeq);
            await blockStream.WriteLittleEndianInt32(fileHeaderBlock.dataSize);
            await blockStream.WriteLittleEndianInt32(fileHeaderBlock.firstData);
            await blockStream.WriteLittleEndianUInt32(0); // checksum

            for (var i = 0; i < Constants.MAX_DATABLK; i++)
            {
                await blockStream.WriteLittleEndianInt32(fileHeaderBlock.DataBlocks[i]);
            }
            
            await blockStream.WriteLittleEndianInt32(0); // r1
            await blockStream.WriteLittleEndianInt32(0); // r2
            await blockStream.WriteLittleEndianInt32(fileHeaderBlock.access);
            await blockStream.WriteLittleEndianUInt32(fileHeaderBlock.byteSize);

            await blockStream.WriteStringWithLength(fileHeaderBlock.comment, Constants.MAXCMMTLEN + 1);
            await blockStream.WriteBytes(new byte[91 - Constants.MAXCMMTLEN + 1]); // r3
            await DateHelper.WriteDate(blockStream, fileHeaderBlock.Date);
            await blockStream.WriteStringWithLength(fileHeaderBlock.fileName, Constants.MAXNAMELEN + 1);
            await blockStream.WriteLittleEndianInt32(0); // r4
            await blockStream.WriteLittleEndianInt32(fileHeaderBlock.real);
            await blockStream.WriteLittleEndianInt32(fileHeaderBlock.nextLink);

            for (var i = 0; i < 5; i++)
            {
                await blockStream.WriteLittleEndianInt32(0); // r5
            }
            
            await blockStream.WriteLittleEndianInt32(fileHeaderBlock.nextSameHash);
            await blockStream.WriteLittleEndianInt32(fileHeaderBlock.parent);
            await blockStream.WriteLittleEndianInt32(fileHeaderBlock.Extension);
            await blockStream.WriteLittleEndianInt32(fileHeaderBlock.secType);
            
            var blockBytes = blockStream.ToArray();
            var newSum = Raw.AdfNormalSum(blockBytes, 20, blockBytes.Length);
            // swLong(buf+20, newSum);
            var checksumBytes = LittleEndianConverter.ConvertToBytes(newSum);
            Array.Copy(checksumBytes, 0, blockBytes, 20, checksumBytes.Length);

            fileHeaderBlock.BlockBytes = blockBytes;

            return blockBytes;
        }
    }
}