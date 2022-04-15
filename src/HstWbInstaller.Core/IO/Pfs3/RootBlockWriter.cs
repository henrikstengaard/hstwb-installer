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
            var blockStream =
                new MemoryStream(
                    rootBlock.BlockBytes == null || rootBlock.BlockBytes.Length == 0
                        ? new byte[512]
                        : rootBlock.BlockBytes);
            
            await blockStream.WriteLittleEndianInt32(rootBlock.DiskType);
            await blockStream.WriteLittleEndianUInt32((uint)rootBlock.Options);
            await blockStream.WriteLittleEndianUInt32(rootBlock.Datestamp);
            await DateHelper.WriteDate(blockStream, rootBlock.CreationDate);
            await blockStream.WriteLittleEndianUInt16(rootBlock.Protection);
            await blockStream.WriteString(rootBlock.DiskName, 32);
            await blockStream.WriteLittleEndianUInt32(rootBlock.LastReserved);
            await blockStream.WriteLittleEndianUInt32(rootBlock.FirstReserved);
            await blockStream.WriteLittleEndianUInt32(rootBlock.ReservedFree);
            await blockStream.WriteLittleEndianUInt16(rootBlock.ReservedBlksize);
            await blockStream.WriteLittleEndianUInt16(rootBlock.RblkCluster);
            await blockStream.WriteLittleEndianUInt32(rootBlock.BlocksFree);
            await blockStream.WriteLittleEndianUInt32(rootBlock.AlwaysFree);
            await blockStream.WriteLittleEndianUInt32(rootBlock.RovingPtr);
            await blockStream.WriteLittleEndianUInt32(rootBlock.DelDir);
            await blockStream.WriteLittleEndianUInt32(rootBlock.DiskSize);
            await blockStream.WriteLittleEndianUInt32(rootBlock.Extension);
            await blockStream.WriteLittleEndianUInt32(0); // not used

            //for(var i = 0; i < rootBlock.idx.)
            
            // await blockStream.WriteLittleEndianInt32(0); // checksum
            //
            // foreach (var map in bitmapBlock.BlocksFreeMap.ChunkBy(32))
            // {
            //     var mapBytes = MapBlockHelper.ConvertBlockFreeMapToByteArray(map.ToArray());
            //     await blockStream.WriteBytes(mapBytes);
            // }
            //     
            // // calculate and update checksum
            var blockBytes = blockStream.ToArray();
            // bitmapBlock.Checksum = await ChecksumHelper.UpdateChecksum(bitmapBytes, 0);
            // bitmapBlock.BlockBytes = bitmapBytes;

            return blockBytes;            
        }
    }
}