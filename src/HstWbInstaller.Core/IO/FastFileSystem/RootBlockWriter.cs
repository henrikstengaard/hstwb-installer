namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System;
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;

    public static class RootBlockWriter
    {
        public static async Task<byte[]> BuildBlock(RootBlock rootBlock, uint blockSize)
        {
            var blockStream =
                new MemoryStream(
                    rootBlock.BlockBytes == null || rootBlock.BlockBytes.Length == 0
                        ? new byte[blockSize]
                        : rootBlock.BlockBytes);
            
            await blockStream.WriteLittleEndianInt32(rootBlock.Type); // type
            // await blockStream.WriteLittleEndianInt32(0); // headerKey
            // await blockStream.WriteLittleEndianInt32(0); // highSeq
            blockStream.Seek(4 * 2, SeekOrigin.Current);
            await blockStream.WriteLittleEndianInt32(rootBlock.HashTableSize); // ht_size
            // await blockStream.WriteLittleEndianInt32(0); // firstData
            // await blockStream.WriteLittleEndianInt32(0); // checksum
            blockStream.Seek(4 * 2, SeekOrigin.Current);

            for (var i = 0; i < Constants.HT_SIZE; i++)
            {
                await blockStream.WriteLittleEndianInt32(rootBlock.HashTable[i]);
            }
            
            await blockStream.WriteLittleEndianInt32(rootBlock.BitmapFlags); // bm_flag

            for (var i = 0U; i < Constants.BM_SIZE; i++)
            {
                await blockStream.WriteLittleEndianInt32(i < rootBlock.bmPages.Length ? rootBlock.bmPages[i] : 0);
            }

            // write first bitmap extension block pointer
            if (rootBlock.BitmapExtensionBlocksOffset != 0)
            {
                await blockStream.WriteLittleEndianUInt32(rootBlock.BitmapExtensionBlocksOffset);
            }
            
            blockStream.Seek(blockSize - 92, SeekOrigin.Begin);
            
            // last root alteration date
            await DateHelper.WriteDate(blockStream, rootBlock.RootAlterationDate);

            var diskName = rootBlock.DiskName.Length > Constants.MAXNAMELEN + 1
                ? rootBlock.DiskName.Substring(0, Constants.MAXNAMELEN + 1)
                : rootBlock.DiskName;

            await blockStream.WriteBytes(new[] { Convert.ToByte(diskName.Length) });
            await blockStream.WriteString(diskName, Constants.MAXNAMELEN + 1);

            // await blockStream.WriteBytes(new byte[8]); // r2
            blockStream.Seek(4 * 2, SeekOrigin.Current);
            
            // last disk alteration date
            await DateHelper.WriteDate(blockStream, rootBlock.DiskAlterationDate);

            // filesystem creation date
            await DateHelper.WriteDate(blockStream, rootBlock.FileSystemCreationDate);
            
            await blockStream.WriteLittleEndianInt32(rootBlock.NextSameHash); // FFS: first directory cache block, 0 otherwise
            await blockStream.WriteLittleEndianInt32(rootBlock.Parent); // FFS: first directory cache block, 0 otherwise
            await blockStream.WriteLittleEndianInt32(rootBlock.Extension); // FFS: first directory cache block, 0 otherwise
            await blockStream.WriteLittleEndianInt32(rootBlock.SecType); // block secondary type = ST_ROOT (value 1)
            
            // calculate and update checksum
            var blockBytes = blockStream.ToArray();
            rootBlock.Checksum = await ChecksumHelper.UpdateChecksum(blockBytes, 20);
            rootBlock.BlockBytes = blockBytes;

            return blockBytes;
        }
    }
}