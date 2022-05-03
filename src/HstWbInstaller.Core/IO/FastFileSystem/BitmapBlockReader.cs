namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System.Collections.Generic;
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;

    public static class BitmapBlockReader
    {
        public static async Task<BitmapBlock> Parse(byte[] blockBytes)
        {
            var blockStream = new MemoryStream(blockBytes);

            var calculatedChecksum = await ChecksumHelper.CalculateChecksum(blockBytes, 0);
            var checksum = await blockStream.ReadInt32(); // checksum

            if (calculatedChecksum != checksum)
            {
                throw new IOException("Invalid checksum for bitmap block");
            }
            
            var blocksFreeMap = new List<bool>();
            var entries = blockBytes.Length - SizeOf.ULONG / SizeOf.ULONG;
            for (var i = 0; i < entries; i++)
            {
                var mapBytes = await blockStream.ReadBytes(4);
                blocksFreeMap.AddRange(MapBlockHelper.ConvertByteArrayToBlockFreeMap(mapBytes));
            }

            return new BitmapBlock
            {
                Checksum = checksum,
                BlockBytes = blockBytes,
                BlocksFreeMap = blocksFreeMap.ToArray()
            };
        }
    }
}