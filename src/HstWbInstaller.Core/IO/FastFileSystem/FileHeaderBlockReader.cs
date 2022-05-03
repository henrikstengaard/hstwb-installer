namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System.Collections.Generic;
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;

    public static class FileHeaderBlockReader
    {
        public static async Task<FileHeaderBlock> Parse(byte[] blockBytes)
        {
            var blockStream = new MemoryStream(blockBytes);

            var type = await blockStream.ReadInt32();
            var headerKey = await blockStream.ReadInt32();
            var highSeq = await blockStream.ReadInt32();
            var dataSize = await blockStream.ReadInt32();
            var firstData = await blockStream.ReadInt32();
            var checksum = await blockStream.ReadUInt32();

            var hashTable = new List<int>();
            for (var i = 0; i < Constants.MAX_DATABLK; i++)
            {
                hashTable.Add(await blockStream.ReadInt32());
            }

            // r1 og r2
            for (var i = 0; i < 2; i++)
            {
                await blockStream.ReadInt32();
            }
            
            var access = await blockStream.ReadInt32();
            var byteSize = await blockStream.ReadUInt32();
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

            return new FileHeaderBlock
            {
                BlockBytes = blockBytes,
                type = type,
                HeaderKey = headerKey,
                highSeq = highSeq,
                dataSize = dataSize,
                firstData = firstData,
                checkSum = checksum,
                HashTable = hashTable.ToArray(),
                access = access,
                byteSize = byteSize,
                comment = comment,
                Date = date,
                fileName = name,
                real = realEntry,
                nextLink = nextLink,
                nextSameHash = nextSameHash,
                parent = parent,
                Extension = extension,
                secType = secType
            };
        }
    }
}