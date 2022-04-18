namespace HstWbInstaller.Core.IO.Pfs3
{
    using System.IO;
    using System.Threading.Tasks;
    using Blocks;
    using Extensions;

    public static class IndexBlockWriter
    {
        public static async Task<byte[]> BuildBlock(indexblock indexBlock, int blockSize)
        {
            var blockStream = indexBlock.BlockBytes == null || indexBlock.BlockBytes.Length == 0 ?
                new MemoryStream() : new MemoryStream(indexBlock.BlockBytes);
                
            await blockStream.WriteLittleEndianUInt16(indexBlock.id);
            await blockStream.WriteLittleEndianUInt16(indexBlock.not_used_1);
            await blockStream.WriteLittleEndianUInt32(indexBlock.datestamp);
            await blockStream.WriteLittleEndianUInt32(indexBlock.seqnr);

            foreach (var t in indexBlock.index)
            {
                await blockStream.WriteLittleEndianInt32(t);
            }
                
            var blockBytes = blockStream.ToArray();
            indexBlock.BlockBytes = blockBytes;

            return blockBytes;
        }
    }
}