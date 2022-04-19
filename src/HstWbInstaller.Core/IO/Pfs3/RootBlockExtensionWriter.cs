namespace HstWbInstaller.Core.IO.Pfs3
{
    using System.IO;
    using System.Threading.Tasks;
    using Blocks;
    using Extensions;

    public static class RootBlockExtensionWriter
    {
        public static async Task<byte[]> BuildBlock(rootblockextension rootblockextension)
        {
            var blockStream = rootblockextension.BlockBytes == null || rootblockextension.BlockBytes.Length == 0 ?
                new MemoryStream() : new MemoryStream(rootblockextension.BlockBytes);
                
            await blockStream.WriteLittleEndianUInt16(rootblockextension.id); // 0
            await blockStream.WriteLittleEndianUInt16(rootblockextension.not_used_1); // 2
            await blockStream.WriteLittleEndianUInt32(rootblockextension.ext_options); // 4
            await blockStream.WriteLittleEndianUInt32(rootblockextension.datestamp); // 8
            await blockStream.WriteLittleEndianUInt32(rootblockextension.pfs2version); // 12
            await DateHelper.WriteDate(blockStream, rootblockextension.RootDate); // 16
            await DateHelper.WriteDate(blockStream, rootblockextension.VolumeDate); // 22
            
            await blockStream.WriteLittleEndianUInt32(rootblockextension.tobedone.operation_id); // 28
            await blockStream.WriteLittleEndianUInt32(rootblockextension.tobedone.argument1); // 32
            await blockStream.WriteLittleEndianUInt32(rootblockextension.tobedone.argument2); // 36
            await blockStream.WriteLittleEndianUInt32(rootblockextension.tobedone.argument3); // 40

            await blockStream.WriteLittleEndianUInt32(rootblockextension.reserved_roving); // 44
            await blockStream.WriteLittleEndianUInt16(rootblockextension.rovingbit); // 48
            await blockStream.WriteLittleEndianUInt16(rootblockextension.curranseqnr); // 50
            await blockStream.WriteLittleEndianUInt16(rootblockextension.deldirroving); // 52
            await blockStream.WriteLittleEndianUInt16(rootblockextension.deldirsize); // 54
            await blockStream.WriteLittleEndianUInt16(rootblockextension.fnsize); // 56
            await blockStream.WriteLittleEndianUInt16(rootblockextension.rovingbit); // 58

            // not_used_2[3]
            await blockStream.WriteLittleEndianUInt16(0); // 60
            await blockStream.WriteLittleEndianUInt16(0); // 62
            await blockStream.WriteLittleEndianUInt16(0); // 64
            
            foreach (var superindex in rootblockextension.superindex)
            {
                await blockStream.WriteLittleEndianUInt32(superindex); // 66
            }
            
            await blockStream.WriteLittleEndianUInt16(rootblockextension.dd_uid); // 130 = (66 + (16 * 4))
            await blockStream.WriteLittleEndianUInt16(rootblockextension.dd_gid); // 132
            await blockStream.WriteLittleEndianUInt32(rootblockextension.dd_protection); // 134
            await DateHelper.WriteDate(blockStream, rootblockextension.dd_creationdate); // 138
            
            // not_used_3
            await blockStream.WriteLittleEndianUInt16(0); // 144
            
            foreach (var deldir in rootblockextension.deldir)
            {
                await blockStream.WriteLittleEndianUInt32(deldir); // 146
            }
            
            var blockBytes = blockStream.ToArray();
            rootblockextension.BlockBytes = blockBytes;

            return blockBytes;
        }
    }
}