namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System.Collections.Generic;
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;

    public static class FileExtBlockReader
    {
        public static async Task<FileExtBlock> Parse(byte[] blockBytes)
        {
            var blockStream = new MemoryStream(blockBytes);

            var type = await blockStream.ReadInt32();
            var headerKey = await blockStream.ReadInt32();
            var highSeq = await blockStream.ReadInt32();
            var dataSize = await blockStream.ReadInt32();
            var firstData = await blockStream.ReadInt32();
            var checkSum = await blockStream.ReadUInt32();

            var dataBlocks = new List<int>();
            for (var i = 0; i < Constants.MAX_DATABLK; i++)
            {
                dataBlocks.Add(await blockStream.ReadInt32());
            }

            for (var i = 0; i < 45; i++)
            {
                await blockStream.ReadInt32();
            }
            
            var info = await blockStream.ReadInt32();
            var nextSameHash = await blockStream.ReadInt32();
            var parent = await blockStream.ReadInt32();
            var extension = await blockStream.ReadInt32();
            var secType = await blockStream.ReadInt32();
            
            return new FileExtBlock
            {
                type = type,
                headerKey = headerKey,
                highSeq = highSeq,
                dataSize = dataSize,
                firstData = firstData,
                checkSum = checkSum,
                dataBlocks = dataBlocks.ToArray(),
                info = info,
                nextSameHash = nextSameHash,
                parent = parent,
                extension = extension,
                secType = secType
            };
        }
    }
}