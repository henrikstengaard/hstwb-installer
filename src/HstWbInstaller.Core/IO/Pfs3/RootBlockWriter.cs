namespace HstWbInstaller.Core.IO.Pfs3
{
    using System.IO;
    using System.Threading.Tasks;
    using Blocks;

    public static class RootBlockWriter
    {
        public static async Task<byte[]> BuildBlock(RootBlock rootBlock)
        {
            var blockStream =
                new MemoryStream(
                    rootBlock.BlockBytes == null || rootBlock.BlockBytes.Length == 0
                        ? new byte[512]
                        : rootBlock.BlockBytes);
            
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