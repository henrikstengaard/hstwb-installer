namespace HstWbInstaller.Core.IO.Pfs3
{
    using System.IO;
    using System.Threading.Tasks;
    using Blocks;
    using Extensions;

    public static class AnodeBlockWriter
    {
        public static async Task<byte[]> BuildBlock(anodeblock anodeblock, int blockSize)
        {
            var blockStream =
                new MemoryStream(
                    anodeblock.BlockBytes == null || anodeblock.BlockBytes.Length == 0
                        ? new byte[blockSize]
                        : anodeblock.BlockBytes);
                
            await blockStream.WriteLittleEndianUInt16(anodeblock.id);
            await blockStream.WriteLittleEndianUInt16(0); // not_used
            await blockStream.WriteLittleEndianUInt32(anodeblock.datestamp);
            await blockStream.WriteLittleEndianUInt32(anodeblock.seqnr);
            await blockStream.WriteLittleEndianUInt32(0); // not_used2
                
            foreach (var anode in anodeblock.nodes)
            {
                await blockStream.WriteLittleEndianUInt32(anode.clustersize);
                await blockStream.WriteLittleEndianUInt32(anode.blocknr);
                await blockStream.WriteLittleEndianUInt32(anode.next);
            }
            
            var blockBytes = blockStream.ToArray();
            anodeblock.BlockBytes = blockBytes;

            return blockBytes;
        }
    }
}