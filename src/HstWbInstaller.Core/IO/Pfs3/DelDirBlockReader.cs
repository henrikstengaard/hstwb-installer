namespace HstWbInstaller.Core.IO.Pfs3
{
    using System.Collections.Generic;
    using System.IO;
    using System.Threading.Tasks;
    using Blocks;
    using Extensions;

    public static class DelDirBlockReader
    {
        public static async Task<deldirblock> Parse(byte[] blockBytes, globaldata g)
        {
            var blockStream = new MemoryStream(blockBytes);

            var id = await blockStream.ReadUInt16();
            
            if (id == 0)
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

            var entries = new List<deldirentry>();
            for (var i = 0; i < SizeOf.DelDirBlock.Entries(g); i++)
            {
                var anodenr = await blockStream.ReadUInt32(); // 32
                var fsize = await blockStream.ReadUInt32(); // 36
                var entryCreationDate = await DateHelper.ReadDate(blockStream); // 40
                var filename = await blockStream.ReadString(16); // 46
                var fsizex = await blockStream.ReadUInt16(); //

                entries.Add(new deldirentry
                {
                    anodenr = anodenr,
                    fsize = fsize,
                    CreationDate = entryCreationDate,
                    filename = filename,
                    fsizex = fsizex
                });
            }
            
            return new deldirblock(g)
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