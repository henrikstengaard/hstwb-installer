namespace HstWbInstaller.Core.IO.Pfs3
{
    using System.IO;
    using System.Threading.Tasks;
    using Blocks;
    using Extensions;

    public static class DelDirBlockReader
    {
        public static async Task<deldirblock> Parse(byte[] blockBytes)
        {
            var blockStream = new MemoryStream(blockBytes);

            var id = await blockStream.ReadUInt16();
            
            if (id != Constants.DELDIRID)
            {
                return null;
            }
            
            var not_used = await blockStream.ReadUInt16();
            var datestamp = await blockStream.ReadUInt32();
            var seqnr = await blockStream.ReadUInt32();
            
            // not_used_2 + not_used_3
            for (var i = 0; i < 3; i++)
            {
                await blockStream.ReadUInt16();
            }

            var uid = await blockStream.ReadUInt16();
            var gid = await blockStream.ReadUInt16();
            var protection = await blockStream.ReadUInt32();
            var creationDate = await DateHelper.ReadDate(blockStream);

            return new deldirblock(blockBytes.Length)
            {
                id = id,
                not_used_1 = not_used,
                datestamp = datestamp,
                seqnr = seqnr,
                uid = uid,
                gid = gid,
                protection = protection,
                CreationDate = creationDate
            };
        }
    }
}