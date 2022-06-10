namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System.Collections.Generic;
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;

    public static class DirBlockReader
    {
        public static async Task<DirBlock> Parse(byte[] blockBytes)
        {
            var blockStream = new MemoryStream(blockBytes);

            var type = await blockStream.ReadInt32();
            var headerKey = await blockStream.ReadInt32();
            var highSeq = await blockStream.ReadInt32();
            var hashTableSize = await blockStream.ReadInt32();
            await blockStream.ReadInt32(); // r1
            var checksum = await blockStream.ReadInt32();

            var hashTable = new List<int>();
            for (var i = 0; i < Constants.HT_SIZE; i++)
            {
                hashTable.Add(await blockStream.ReadInt32());
            }

            // r1 og r2
            for (var i = 0; i < 2; i++)
            {
                await blockStream.ReadInt32();
            }
            
            var access = await blockStream.ReadInt32();
            await blockStream.ReadInt32();// r4
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

            return new DirBlock
            {
                BlockBytes = blockBytes,
                Type = type,
                HeaderKey = headerKey,
                HighSeq = highSeq,
                HashTableSize = hashTableSize,
                Checksum = checksum,
                HashTable = hashTable.ToArray(),
                Access = access,
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