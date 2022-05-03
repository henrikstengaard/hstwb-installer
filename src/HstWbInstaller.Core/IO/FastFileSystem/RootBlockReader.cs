namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using Extensions;

    public static class RootBlockReader
    {
        public static async Task<RootBlock> Parse(byte[] blockBytes)
        {
            var blockStream = new MemoryStream(blockBytes);
            
            var type = await blockStream.ReadInt32(); // type
            var headerKey = await blockStream.ReadInt32(); // headerKey
            var highSeq = await blockStream.ReadInt32(); // highSeq
            var hashtableSize = await blockStream.ReadUInt32(); // hashTableSize
            var firstData = await blockStream.ReadInt32(); // firstData
            var checksum = await blockStream.ReadUInt32(); // checksum

            var hashtableEntries = new List<int>();
            
            for (var i = 0; i < Constants.HT_SIZE; i++)
            {
                hashtableEntries.Add(await blockStream.ReadInt32());
            }
            
            var bitmapFlags = await blockStream.ReadInt32(); // bm_flag
            
            var bitmapBlockOffsets = new List<uint>();

            for (var i = 0; i < 25; i++)
            {
                var bitmapBlockOffset = await blockStream.ReadUInt32();
                if (bitmapBlockOffset == 0)
                {
                    continue;
                }
                bitmapBlockOffsets.Add(bitmapBlockOffset);
            }
            
            var bitmapExtensionBlocksOffset = await blockStream.ReadUInt32();
            
            // last root alteration date
            var rootAlterationDate = await DateHelper.ReadDate(blockStream);

            var diskName = await blockStream.ReadString();
            
            blockStream.Seek(blockBytes.Length - 40, SeekOrigin.Begin);
            var diskAlterationDate = await DateHelper.ReadDate(blockStream);
            var fileSystemCreationDate = await DateHelper.ReadDate(blockStream);

            var nextHash = await blockStream.ReadUInt32();
            var parentDir = await blockStream.ReadUInt32();
            var extension = await blockStream.ReadUInt32();
            var secType= await blockStream.ReadUInt32();
            
            return new RootBlock
            {
                Type = (uint)type,
                HashtableSize = hashtableSize,
                HashTable = hashtableEntries.ToArray(),
                BitmapFlags = bitmapFlags,
                BitmapBlocksOffset = bitmapBlockOffsets.FirstOrDefault(),
                BitmapBlockOffsets = bitmapBlockOffsets.ToArray(),
                BitmapExtensionBlocksOffset = bitmapExtensionBlocksOffset,
                RootAlterationDate = rootAlterationDate,
                DiskName = diskName,
                DiskAlterationDate = diskAlterationDate,
                FileSystemCreationDate = fileSystemCreationDate,
                ExtensionBlockOffset = extension
            };
        }
    }
}