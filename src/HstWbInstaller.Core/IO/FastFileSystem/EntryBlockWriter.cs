namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System;
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;
    using RigidDiskBlocks;

    public static class EntryBlockWriter
    {
        public static async Task<byte[]> BuildBlock(EntryBlock entryBlock, uint blockSize)
        {
            var blockStream =
                new MemoryStream(
                    entryBlock.BlockBytes == null || entryBlock.BlockBytes.Length == 0
                        ? new byte[blockSize]
                        : entryBlock.BlockBytes);

            await blockStream.WriteLittleEndianInt32(entryBlock.Type);
            await blockStream.WriteLittleEndianInt32(entryBlock.HeaderKey);
            await blockStream.WriteLittleEndianInt32(entryBlock.HighSeq);
            await blockStream.WriteLittleEndianInt32(entryBlock.SharedSize);
            await blockStream.WriteLittleEndianInt32(entryBlock.FirstData);
            await blockStream.WriteLittleEndianUInt32(0); // checksum

            for (var i = 0; i < Constants.MAX_DATABLK; i++)
            {
                await blockStream.WriteLittleEndianInt32(entryBlock.SharedHashTableDataBlocks[i]);
            }
            
            await blockStream.WriteLittleEndianInt32(0); // r1
            await blockStream.WriteLittleEndianInt32(0); // r2
            await blockStream.WriteLittleEndianInt32(entryBlock.Access);
            await blockStream.WriteLittleEndianInt32(entryBlock.ByteSize);

            await blockStream.WriteStringWithLength(entryBlock.Comment, Constants.MAXCMMTLEN + 1);
            await blockStream.WriteBytes(new byte[91 - Constants.MAXCMMTLEN + 1]); // r3
            await DateHelper.WriteDate(blockStream, entryBlock.Date);
            await blockStream.WriteStringWithLength(entryBlock.Name, Constants.MAXNAMELEN + 1);
            await blockStream.WriteLittleEndianInt32(0); // r4
            await blockStream.WriteLittleEndianInt32(entryBlock.RealEntry);
            await blockStream.WriteLittleEndianInt32(entryBlock.NextLink);

            for (var i = 0; i < 5; i++)
            {
                await blockStream.WriteLittleEndianInt32(0); // r5
            }
            
            await blockStream.WriteLittleEndianInt32(entryBlock.NextSameHash);
            await blockStream.WriteLittleEndianInt32(entryBlock.Parent);
            await blockStream.WriteLittleEndianInt32(entryBlock.Extension);
            await blockStream.WriteLittleEndianInt32(entryBlock.SecType);
            
            var blockBytes = blockStream.ToArray();
            var newSum = Raw.AdfNormalSum(blockBytes, 20, blockBytes.Length);
            // swLong(buf+20, newSum);
            var checksumBytes = LittleEndianConverter.ConvertToBytes(newSum);
            Array.Copy(checksumBytes, 0, blockBytes, 20, checksumBytes.Length);

            entryBlock.BlockBytes = blockBytes;

            return blockBytes;
        }
    }
}