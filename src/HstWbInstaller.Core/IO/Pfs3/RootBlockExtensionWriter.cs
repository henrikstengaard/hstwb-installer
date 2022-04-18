namespace HstWbInstaller.Core.IO.Pfs3
{
    using System.IO;
    using System.Threading.Tasks;
    using Blocks;
    using Extensions;

    public static class RootBlockExtensionWriter
    {
        public static async Task<byte[]> BuildBlock(rootblockextension rootblockextension, int blockSize)
        {
            var blockStream = rootblockextension.BlockBytes == null || rootblockextension.BlockBytes.Length == 0 ?
                new MemoryStream() : new MemoryStream(rootblockextension.BlockBytes);
                
            await blockStream.WriteLittleEndianUInt16(rootblockextension.id);
            await blockStream.WriteLittleEndianUInt16(rootblockextension.not_used_1);
            await blockStream.WriteLittleEndianUInt32(rootblockextension.ext_options);
            await blockStream.WriteLittleEndianUInt32(rootblockextension.datestamp);
            await blockStream.WriteLittleEndianUInt32(rootblockextension.pfs2version);
            await DateHelper.WriteDate(blockStream, rootblockextension.RootDate);
            await DateHelper.WriteDate(blockStream, rootblockextension.VolumeDate);
            
            await blockStream.WriteLittleEndianUInt32(rootblockextension.tobedone.operation_id);
            await blockStream.WriteLittleEndianUInt32(rootblockextension.tobedone.argument1);
            await blockStream.WriteLittleEndianUInt32(rootblockextension.tobedone.argument2);
            await blockStream.WriteLittleEndianUInt32(rootblockextension.tobedone.argument3);

            await blockStream.WriteLittleEndianUInt32(rootblockextension.reserved_roving);
            await blockStream.WriteLittleEndianUInt16(rootblockextension.rovingbit);
            await blockStream.WriteLittleEndianUInt16(rootblockextension.curranseqnr);
            await blockStream.WriteLittleEndianUInt16(rootblockextension.deldirroving);
            await blockStream.WriteLittleEndianUInt16(rootblockextension.deldirsize);
            await blockStream.WriteLittleEndianUInt16(rootblockextension.fnsize);
            await blockStream.WriteLittleEndianUInt16(rootblockextension.rovingbit);

            // not_used_2
            await blockStream.WriteLittleEndianUInt16(0);
            await blockStream.WriteLittleEndianUInt16(0);
            await blockStream.WriteLittleEndianUInt16(0);
            
            foreach (var superindex in rootblockextension.superindex)
            {
                await blockStream.WriteLittleEndianUInt32(superindex);
            }
            
            await blockStream.WriteLittleEndianUInt16(rootblockextension.dd_uid);
            await blockStream.WriteLittleEndianUInt16(rootblockextension.dd_gid);
            await blockStream.WriteLittleEndianUInt32(rootblockextension.dd_protection);
            await DateHelper.WriteDate(blockStream, rootblockextension.dd_creationdate);
            
            foreach (var deldir in rootblockextension.deldir)
            {
                await blockStream.WriteLittleEndianUInt32(deldir);
            }
            
            var blockBytes = blockStream.ToArray();
            rootblockextension.BlockBytes = blockBytes;

            return blockBytes;
        }
    }
}