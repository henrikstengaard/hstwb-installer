namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System;
    using System.IO;
    using System.Linq;
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
            
            await blockStream.WriteLittleEndianUInt32(rootBlock.Type); // type

            blockStream.Seek(12, SeekOrigin.Begin);
            await blockStream.WriteLittleEndianUInt32(rootBlock.HashtableSize); // ht_size
            
            blockStream.Seek(blockSize - 200, SeekOrigin.Begin);
            await blockStream.WriteLittleEndianInt32(rootBlock.BitmapFlags); // bm_flag

            var bitmapBlocks = rootBlock.BitmapBlocks.ToList();

            for (var i = 0U; i < bitmapBlocks.Count; i++)
            {
                await blockStream.WriteLittleEndianUInt32(rootBlock.BitmapBlocksOffset + i);
            }

            // write first bitmap extension block pointer
            if (rootBlock.BitmapExtensionBlocksOffset != 0)
            {
                await blockStream.WriteLittleEndianUInt32(rootBlock.BitmapExtensionBlocksOffset);
            }
            
            blockStream.Seek(blockSize - 92, SeekOrigin.Begin);
            
            // last root alteration date
            await DateHelper.WriteDate(blockStream, rootBlock.RootAlterationDate);

            var diskName = rootBlock.DiskName.Length > 30
                ? rootBlock.DiskName.Substring(0, 30)
                : rootBlock.DiskName;

            await blockStream.WriteBytes(new[] { Convert.ToByte(diskName.Length) });
            await blockStream.WriteString(diskName, 30);

            // last disk alteration date
            blockStream.Seek(blockSize - 40, SeekOrigin.Begin);
            if (rootBlock.DiskAlterationDate == DateTime.MinValue)
            {
                await blockStream.WriteLittleEndianInt32(0); // days since 1 jan 78
                await blockStream.WriteLittleEndianInt32(0); // minutes past midnight
                await blockStream.WriteLittleEndianInt32(0); // ticks (1/50 sec) past last minute
            }
            else
            {
                await DateHelper.WriteDate(blockStream, rootBlock.DiskAlterationDate);
            }

            // filesystem creation date
            await DateHelper.WriteDate(blockStream, rootBlock.FileSystemCreationDate);
            
            blockStream.Seek(blockSize - 8, SeekOrigin.Begin);
            await blockStream.WriteLittleEndianUInt32(rootBlock.FirstDirectoryCacheBlock); // FFS: first directory cache block, 0 otherwise
            await blockStream.WriteLittleEndianUInt32(rootBlock.BlockSecondaryType); // block secondary type = ST_ROOT (value 1)
            
            // calculate and update checksum
            var blockBytes = blockStream.ToArray();
            rootBlock.Checksum = await ChecksumHelper.UpdateChecksum(blockBytes, 20);
            rootBlock.BlockBytes = blockBytes;

            return blockBytes;
        }
    }
}