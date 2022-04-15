namespace HstWbInstaller.Core.IO.Pfs3
{
    using System.Collections.Generic;
    using System.IO;
    using System.Threading.Tasks;
    using Blocks;
    using Extensions;

    public static class IndexBlockReader
    {
        public static async Task<indexblock> Parse(byte[] blockBytes)
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

            var index = new List<int>();
            var indexCount = (blockBytes.Length - SizeOf.UWORD * 2 - SizeOf.ULONG * 2) / SizeOf.LONG;
            for (var i = 0; i < indexCount; i++)
            {
                index.Add(await blockStream.ReadInt32());
            }
            
            return new indexblock(blockBytes.Length)
            {
                id = id,
                not_used_1 = not_used,
                datestamp = datestamp,
                seqnr = seqnr,
                index = index.ToArray()
            };
        }
    }
}