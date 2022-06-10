namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System.Collections.Generic;
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;

    public static class EntryBlockReader
    {
        public static async Task<EntryBlock> Parse(byte[] blockBytes)
        {
            var blockStream = new MemoryStream(blockBytes);

            var type = await blockStream.ReadInt32();
            var headerKey = await blockStream.ReadInt32();

            blockStream.Seek(0x14, SeekOrigin.Begin);
            var checksum = await blockStream.ReadInt32();

            var hashTable = new List<int>();
            for (var i = 0; i < Constants.HT_SIZE; i++)
            {
                hashTable.Add(await blockStream.ReadInt32());
            }

            blockStream.Seek(0x140, SeekOrigin.Begin);
            var access = await blockStream.ReadInt32();
            var byteSize = await blockStream.ReadInt32();
            var comment = await blockStream.ReadString();
            
            blockStream.Seek(0x1a4, SeekOrigin.Begin);
            var date = await DateHelper.ReadDate(blockStream);
            var name = await blockStream.ReadString();
            
            blockStream.Seek(0x1d4, SeekOrigin.Begin);
            var realEntry = await blockStream.ReadInt32();
            var nextLink = await blockStream.ReadInt32();

            blockStream.Seek(0x1f0, SeekOrigin.Begin);
            var nextSameHash = await blockStream.ReadInt32();
            var parent = await blockStream.ReadInt32();
            var extension = await blockStream.ReadInt32();
            var secType = await blockStream.ReadInt32();

            return new EntryBlock
            {
                BlockBytes = blockBytes,
                Type = type,
                HeaderKey = headerKey,
                Checksum = checksum,
                HashTable = hashTable.ToArray(),
                Access = access,
                ByteSize = byteSize,
                Comment = comment,
                Date = date,
                Name = name,
                RealEntry = realEntry,
                NextLink = nextLink,
                NextSameHash = nextSameHash,
                Parent = parent,
                Extension = extension,
                SecType = secType
            };
        }
    }
}