namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System.Collections.Generic;
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;

    public static class BitmapExtensionBlockReader
    {
        public static async Task<BitmapExtensionBlock> Parse(byte[] blockBytes)
        {
            var blockStream = new MemoryStream(blockBytes);

            // read bitmap block offsets
            var bitmapBlockOffsets = new List<uint>();
            var bitmapBlocks = blockBytes.Length - SizeOf.ULONG / SizeOf.ULONG;
            for (var i = 0; i < bitmapBlocks; i++)
            {
                var bitmapBlockOffset = await blockStream.ReadUInt32();
                if (bitmapBlockOffset == 0)
                {
                    break;
                }

                bitmapBlockOffsets.Add(bitmapBlockOffset);
            }

            // read next bitmap block pointer
            blockStream.Seek(blockBytes.Length - 4, SeekOrigin.Begin);
            var nextBitmapExtensionBlockPointer = await blockStream.ReadUInt32();

            return new BitmapExtensionBlock
            {
                BlockBytes = blockBytes,
                BitmapBlockOffsets = bitmapBlockOffsets,
                NextBitmapExtensionBlockPointer = nextBitmapExtensionBlockPointer
            };
        }
    }
}