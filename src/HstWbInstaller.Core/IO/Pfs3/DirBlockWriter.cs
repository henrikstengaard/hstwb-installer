namespace HstWbInstaller.Core.IO.Pfs3
{
    using System.IO;
    using System.Threading.Tasks;
    using Blocks;
    using Extensions;

    public static class DirBlockWriter
    {
        public static async Task<byte[]> BuildBlock(dirblock dirblock, int blockSize)
        {
            var blockStream = dirblock.BlockBytes == null || dirblock.BlockBytes.Length == 0 ?
                new MemoryStream() : new MemoryStream(dirblock.BlockBytes);
                
            await blockStream.WriteLittleEndianUInt16(dirblock.id);
            await blockStream.WriteLittleEndianUInt16(dirblock.not_used_1);
            await blockStream.WriteLittleEndianUInt32(dirblock.datestamp);
            await blockStream.WriteLittleEndianUInt32(dirblock.anodenr);
            
            // not_used_2
            for (var i = 0; i < 2; i++)
            {
                await blockStream.WriteLittleEndianUInt16(0);
            }
            
            await blockStream.WriteLittleEndianUInt32(dirblock.anodenr);
            await blockStream.WriteLittleEndianUInt32(dirblock.parent);
            await blockStream.WriteBytes(dirblock.entries);
                
            var blockBytes = blockStream.ToArray();
            dirblock.BlockBytes = blockBytes;

            return blockBytes;
        }
    }
}