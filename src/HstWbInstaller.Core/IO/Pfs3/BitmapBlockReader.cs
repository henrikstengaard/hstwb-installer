namespace HstWbInstaller.Core.IO.Pfs3
{
    using System.Collections.Generic;
    using System.IO;
    using System.Threading.Tasks;
    using Blocks;
    using Extensions;

    public static class BitmapBlockReader
    {
        public static async Task<BitmapBlock> Parse(byte[] blockBytes, globaldata g)
        {
            var blockStream = new MemoryStream(blockBytes);

            var id = await blockStream.ReadUInt16();
            
            if (id != Constants.IBLKID)
            {
                return null;
            }
            
            var not_used = await blockStream.ReadUInt16();
            var datestamp = await blockStream.ReadUInt32();
            var seqnr = await blockStream.ReadUInt32();
            
            var bitmap = new List<uint>();
            var bitmapCount = (blockBytes.Length - SizeOf.UWORD * 2 - SizeOf.ULONG * 2) / SizeOf.ULONG;
            for (var i = 0; i < bitmapCount; i++)
            {
                bitmap.Add(await blockStream.ReadUInt32());
            }
            
            return new BitmapBlock(blockBytes.Length, g)
            {
                id = id,
                not_used_1 = not_used,
                datestamp = datestamp,
                seqnr = seqnr,
                bitmap = bitmap.ToArray()
            };
        }
    }
}