namespace HstWbInstaller.Core.IO.Pfs3
{
    using System.IO;
    using System.Threading.Tasks;
    using Blocks;
    using Extensions;

    public static class DelDirBlockWriter
    {
        public static async Task<byte[]> BuildBlock(deldirblock deldirblock)
        {
            var blockStream = deldirblock.BlockBytes == null || deldirblock.BlockBytes.Length == 0 ?
                new MemoryStream() : new MemoryStream(deldirblock.BlockBytes);
                
            await blockStream.WriteLittleEndianUInt16(deldirblock.id);
            await blockStream.WriteLittleEndianUInt16(deldirblock.not_used_1);
            await blockStream.WriteLittleEndianUInt32(deldirblock.datestamp);
            await blockStream.WriteLittleEndianUInt32(deldirblock.seqnr);

            // not_used_2 + not_used_3
            await blockStream.WriteLittleEndianUInt16(0);
            await blockStream.WriteLittleEndianUInt16(0);
            await blockStream.WriteLittleEndianUInt16(deldirblock.uid);
            await blockStream.WriteLittleEndianUInt16(deldirblock.gid);
            await blockStream.WriteLittleEndianUInt32(deldirblock.protection);
            await DateHelper.WriteDate(blockStream, deldirblock.CreationDate);
            
            foreach (var entry in deldirblock.entries)
            {
                await blockStream.WriteLittleEndianUInt32(entry.anodenr);
                await blockStream.WriteLittleEndianUInt32(entry.fsize);
                await DateHelper.WriteDate(blockStream, entry.CreationDate);
                await blockStream.WriteString(entry.filename, 16);
                await blockStream.WriteLittleEndianUInt16(entry.fsizex);
            }
            
            var blockBytes = blockStream.ToArray();
            deldirblock.BlockBytes = blockBytes;

            return blockBytes;
        }
    }
}