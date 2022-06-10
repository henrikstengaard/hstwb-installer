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

            await blockStream.WriteLittleEndianInt32(fileHeaderBlock.Type);
            await blockStream.WriteLittleEndianInt32(fileHeaderBlock.HeaderKey);
            await blockStream.WriteLittleEndianInt32(fileHeaderBlock.HighSeq);
            await blockStream.WriteLittleEndianInt32(fileHeaderBlock.DataSize);
            await blockStream.WriteLittleEndianInt32(fileHeaderBlock.FirstData);
            await blockStream.WriteLittleEndianUInt32(0); // checksum

            for (var i = 0; i < Constants.MAX_DATABLK; i++)
            {
                await blockStream.WriteLittleEndianInt32(fileHeaderBlock.DataBlocks[i]);
            }
            
            // await blockStream.WriteLittleEndianInt32(0); // r1
            // await blockStream.WriteLittleEndianInt32(0); // r2
            blockStream.Seek(4 * 2, SeekOrigin.Current);
            await blockStream.WriteLittleEndianInt32(fileHeaderBlock.Access);
            await blockStream.WriteLittleEndianInt32(fileHeaderBlock.ByteSize);

            await blockStream.WriteStringWithLength(fileHeaderBlock.Comment, Constants.MAXCMMTLEN);
            await blockStream.WriteBytes(new byte[91 - Constants.MAXCMMTLEN]); // r3
            await DateHelper.WriteDate(blockStream, fileHeaderBlock.Date); // 1a4
            await blockStream.WriteStringWithLength(fileHeaderBlock.Name, Constants.MAXNAMELEN + 1);
            // await blockStream.WriteLittleEndianInt32(0); // r4
            blockStream.Seek(4, SeekOrigin.Current);
            await blockStream.WriteLittleEndianInt32(fileHeaderBlock.RealEntry); // 1d4
            await blockStream.WriteLittleEndianInt32(fileHeaderBlock.NextLink);

            // for (var i = 0; i < 5; i++)
            // {
            //     await blockStream.WriteLittleEndianInt32(0); // r5
            // }
            blockStream.Seek(4 * 5, SeekOrigin.Current);
            
            await blockStream.WriteLittleEndianInt32(fileHeaderBlock.NextSameHash);
            await blockStream.WriteLittleEndianInt32(fileHeaderBlock.Parent);
            await blockStream.WriteLittleEndianInt32(fileHeaderBlock.Extension);
            await blockStream.WriteLittleEndianInt32(fileHeaderBlock.SecType);
            
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