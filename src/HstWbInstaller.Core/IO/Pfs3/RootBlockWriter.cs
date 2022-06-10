namespace HstWbInstaller.Core.IO.Pfs3
{
    using System.IO;
    using System.Threading.Tasks;
    using Blocks;
    using Extensions;

    public static class RootBlockWriter
    {
        public static async Task<byte[]> BuildBlock(RootBlock rootBlock)
        {
            var blockStream = rootBlock.BlockBytes == null || rootBlock.BlockBytes.Length == 0 ?
                new MemoryStream() : new MemoryStream(rootBlock.BlockBytes);
            
            await blockStream.WriteLittleEndianInt32(rootBlock.DiskType); // 0
            await blockStream.WriteLittleEndianUInt32((uint)rootBlock.Options); // 4
            await blockStream.WriteLittleEndianUInt32(rootBlock.Datestamp); // 8
            await DateHelper.WriteDate(blockStream, rootBlock.CreationDate); // 12
            await blockStream.WriteLittleEndianUInt16(rootBlock.Protection); // 18
            blockStream.WriteByte((byte)(rootBlock.DiskName.Length > 31 ? 31 : rootBlock.DiskName.Length)); // 20
            await blockStream.WriteString(rootBlock.DiskName, 31); // 21
            await blockStream.WriteLittleEndianUInt32(rootBlock.LastReserved); // 52
            await blockStream.WriteLittleEndianUInt32(rootBlock.FirstReserved); // 56
            await blockStream.WriteLittleEndianUInt32(rootBlock.ReservedFree); // 60
            await blockStream.WriteLittleEndianUInt16(rootBlock.ReservedBlksize); // 64
            await blockStream.WriteLittleEndianUInt16(rootBlock.RblkCluster); // 66
            await blockStream.WriteLittleEndianUInt32(rootBlock.BlocksFree); // 68
            await blockStream.WriteLittleEndianUInt32(rootBlock.AlwaysFree); // 72
            await blockStream.WriteLittleEndianUInt32(rootBlock.RovingPtr); // 76
            await blockStream.WriteLittleEndianUInt32(rootBlock.DelDir); // 80
            await blockStream.WriteLittleEndianUInt32(rootBlock.DiskSize); // 84
            await blockStream.WriteLittleEndianUInt32(rootBlock.Extension); // 88
            await blockStream.WriteLittleEndianUInt32(0); // not used, 92

            foreach (var t in rootBlock.idx.union)
            {
                await blockStream.WriteLittleEndianUInt32(t);
            }

            await blockStream.WriteBytes(await BitmapBlockWriter.BuildBlock(rootBlock.ReservedBitmapBlock));
            
            var blockBytes = blockStream.ToArray();
            return blockBytes;            
        }
    }
}