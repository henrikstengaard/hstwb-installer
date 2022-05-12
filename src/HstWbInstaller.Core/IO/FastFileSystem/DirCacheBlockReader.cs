namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;

    public static class DirCacheBlockReader
    {
        public static async Task<DirCacheBlock> Parse(byte[] blockBytes)
        {
            var blockStream = new MemoryStream(blockBytes);

            var type = await blockStream.ReadInt32();
            var headerKey = await blockStream.ReadInt32();
            var parent = await blockStream.ReadInt32();
            var recordsNb = await blockStream.ReadInt32();
            var nextDirC = await blockStream.ReadInt32();
            var checksum = await blockStream.ReadInt32();
            var records = await blockStream.ReadBytes(488);

            
            return new DirCacheBlock
            {
                BlockBytes = blockBytes,
                Type = type,
                HeaderKey = headerKey,
                Parent = parent,
                RecordsNb = recordsNb,
                NextDirC = nextDirC,
                CheckSum = checksum,
                Records = records
            };
        }
    }
}