namespace HstWbInstaller.Core.IO.Pfs3
{
    using System.IO;
    using System.Threading.Tasks;
    using Blocks;
    using Extensions;

    public static class BitmapBlockWriter
    {
        public static async Task<byte[]> BuildBlock(BitmapBlock bitmapBlock)
        {
            var blockStream = bitmapBlock.BlockBytes == null || bitmapBlock.BlockBytes.Length == 0 ?
                new MemoryStream() : new MemoryStream(bitmapBlock.BlockBytes);
                
            await blockStream.WriteLittleEndianUInt16(bitmapBlock.id);
            await blockStream.WriteLittleEndianUInt16(bitmapBlock.not_used_1);
            await blockStream.WriteLittleEndianUInt32(bitmapBlock.datestamp);
            await blockStream.WriteLittleEndianUInt32(bitmapBlock.seqnr);
            
            foreach (var bitmap in bitmapBlock.bitmap)
            {
                await blockStream.WriteLittleEndianUInt32(bitmap);
            }
            
            var blockBytes = blockStream.ToArray();
            bitmapBlock.BlockBytes = blockBytes;

            return blockBytes;
        }
    }
}