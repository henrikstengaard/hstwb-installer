namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System;
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;
    using RigidDiskBlocks;

    public static class DirBlockWriter
    {
        public static async Task<byte[]> BuildBlock(DirBlock dirBlock, uint blockSize)
        {
            var blockStream =
                new MemoryStream(
                    dirBlock.BlockBytes == null || dirBlock.BlockBytes.Length == 0
                        ? new byte[blockSize]
                        : dirBlock.BlockBytes);

            await blockStream.WriteLittleEndianInt32(dirBlock.Type);
            await blockStream.WriteLittleEndianInt32(dirBlock.HeaderKey);
            await blockStream.WriteLittleEndianInt32(dirBlock.HighSeq);
            await blockStream.WriteLittleEndianInt32(dirBlock.HashTableSize);
            await blockStream.WriteLittleEndianInt32(0); // r1
            await blockStream.WriteLittleEndianUInt32(0); // checksum

            for (var i = 0; i < Constants.HT_SIZE; i++)
            {
                await blockStream.WriteLittleEndianInt32(dirBlock.HashTable[i]);
            }
            
            // await blockStream.WriteLittleEndianInt32(0); // r2
            // await blockStream.WriteLittleEndianInt32(0); // r2
            blockStream.Seek(4 * 2, SeekOrigin.Current);
            await blockStream.WriteLittleEndianInt32(dirBlock.Access);
            // await blockStream.WriteLittleEndianInt32(0); // r4
            blockStream.Seek(4, SeekOrigin.Current);

            await blockStream.WriteStringWithLength(dirBlock.Comment, Constants.MAXCMMTLEN);
            await blockStream.WriteBytes(new byte[91 - Constants.MAXCMMTLEN]); // r5
            await DateHelper.WriteDate(blockStream, dirBlock.Date);
            await blockStream.WriteStringWithLength(dirBlock.Name, Constants.MAXNAMELEN + 1);
            // await blockStream.WriteLittleEndianInt32(0); // r6
            blockStream.Seek(4, SeekOrigin.Current);
            await blockStream.WriteLittleEndianInt32(dirBlock.RealEntry);
            await blockStream.WriteLittleEndianInt32(dirBlock.NextLink);

            // for (var i = 0; i < 5; i++)
            // {
            //     await blockStream.WriteLittleEndianInt32(0); // r7
            // }
            blockStream.Seek(4 * 5, SeekOrigin.Current);
            
            await blockStream.WriteLittleEndianInt32(dirBlock.NextSameHash);
            await blockStream.WriteLittleEndianInt32(dirBlock.Parent);
            await blockStream.WriteLittleEndianInt32(dirBlock.Extension);
            await blockStream.WriteLittleEndianInt32(dirBlock.SecType);
            
            var blockBytes = blockStream.ToArray();
            var newSum = Raw.AdfNormalSum(blockBytes, 20, blockBytes.Length);
            // swLong(buf+20, newSum);
            var checksumBytes = LittleEndianConverter.ConvertToBytes(newSum);
            Array.Copy(checksumBytes, 0, blockBytes, 20, checksumBytes.Length);

            dirBlock.BlockBytes = blockBytes;

            return blockBytes;
        }
    }
}