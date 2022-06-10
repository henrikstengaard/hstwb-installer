namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;

    public static class OfsDataBlockReader
    {
        public static async Task<OfsDataBlock> Parse(byte[] blockBytes)
        {
            var blockStream = new MemoryStream(blockBytes);

            var type = await blockStream.ReadInt32();
            var headerKey = await blockStream.ReadInt32();
            var seqNum = await blockStream.ReadInt32();
            var dataSize = await blockStream.ReadInt32();
            var nextData = await blockStream.ReadInt32();
            var checkSum = await blockStream.ReadUInt32();
            var data = await blockStream.ReadBytes(488);
            
            return new OfsDataBlock
            {
                Type = type,
                HeaderKey = headerKey,
                SeqNum = seqNum,
                DataSize = dataSize,
                NextData = nextData,
                CheckSum = checkSum,
                Data = data
            };
        }
    }
}