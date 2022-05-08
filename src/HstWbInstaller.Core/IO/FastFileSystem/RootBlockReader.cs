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
            var hashtableSize = await blockStream.ReadInt32(); // hashTableSize
            var firstData = await blockStream.ReadInt32(); // firstData
            var checksum = await blockStream.ReadUInt32(); // checksum

            var hashtableEntries = new List<int>();
            
            for (var i = 0; i < Constants.HT_SIZE; i++)
            {
                hashtableEntries.Add(await blockStream.ReadInt32());
            }
            
            var bitmapFlags = await blockStream.ReadInt32(); // bm_flag
            
            var bitmapBlockOffsets = new List<int>();

            for (var i = 0; i < 25; i++)
            {
                var bitmapBlockOffset = await blockStream.ReadInt32();
                bitmapBlockOffsets.Add(bitmapBlockOffset);
            }
            
            var bitmapExtensionBlocksOffset = await blockStream.ReadUInt32();
            
            // last root alteration date
            var rootAlterationDate = await DateHelper.ReadDate(blockStream);

            var diskName = await blockStream.ReadString();
            
            blockStream.Seek(blockBytes.Length - 40, SeekOrigin.Begin);
            var diskAlterationDate = await DateHelper.ReadDate(blockStream);
            var fileSystemCreationDate = await DateHelper.ReadDate(blockStream);

            var nextSameHash = await blockStream.ReadInt32();
            var parent = await blockStream.ReadInt32();
            var extension = await blockStream.ReadInt32();
            var secType= await blockStream.ReadInt32();
            
            return new RootBlock
            {
                Type = type,
                HashTableSize = hashtableSize,
                HashTable = hashtableEntries.ToArray(),
                BitmapFlags = bitmapFlags,
                BitmapBlocksOffset = (uint)bitmapBlockOffsets[0],
                BitmapBlockOffsets = bitmapBlockOffsets.ToArray(),
                BitmapExtensionBlocksOffset = bitmapExtensionBlocksOffset,
                RootAlterationDate = rootAlterationDate, // 0x1a4
                DiskName = diskName, // 0x1b0
                DiskAlterationDate = diskAlterationDate, // 0x1d8
                FileSystemCreationDate = fileSystemCreationDate, // 0x1e4
                NextSameHash = nextSameHash,
                Parent = parent,
                Extension = extension,
                SecType = secType
            };
        }
    }
}