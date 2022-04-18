namespace HstWbInstaller.Core.IO.Pfs3
{
    using System.IO;
    using System.Threading.Tasks;
    using Blocks;
    using Extensions;

    public static class DirBlockReader
    {
        public static async Task<dirblock> Parse(byte[] blockBytes, globaldata g)
        {
            var blockStream = new MemoryStream(blockBytes);

            var id = await blockStream.ReadUInt16();
            var not_used = await blockStream.ReadUInt16();
            var datestamp = await blockStream.ReadUInt32();
            
            // not_used_2
            for (var i = 0; i < 2; i++)
            {
                await blockStream.ReadUInt16();
            }
            var anodenr = await blockStream.ReadUInt32();
            var parent = await blockStream.ReadUInt32();

            if (id == 0)
            {
                return null;
            }

            var entriesCount = blockBytes.Length - SizeOf.UWORD * 4 - SizeOf.ULONG * 3;

            var entries = await blockStream.ReadBytes(entriesCount);

            return new dirblock(g)
            {
                id = id,
                not_used_1 = not_used,
                datestamp = datestamp,
                anodenr = anodenr,
                parent = parent,
                entries = entries
            };
        }
    }
}