namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System;
    using System.Collections.Generic;
    using System.Linq;

    public static class OffsetHelper
    {
        public static uint CalculateRootBlockOffset(uint lowCyl, uint highCyl, uint reserved, uint heads, uint sectors)
        {
            var cylinders = highCyl - lowCyl + 1;
            var highKey = cylinders * heads * sectors - reserved;
            var rootKey = (reserved + highKey) / 2;
            return rootKey;
        }

        public static void SetRootBlockOffsets(RootBlock rootBlock)
        {
            if (rootBlock.Offset == 0)
            {
                throw new ArgumentException("Root block offset is not set", nameof(RootBlock.Offset));
            }

            if (rootBlock.BitmapBlocksOffset == 0)
            {
                throw new ArgumentException("Bitmap block offset is not set", nameof(RootBlock.BitmapBlocksOffset));
            }
            
            SetBitmapBlockOffsets(rootBlock.BitmapBlocks, rootBlock.BitmapBlocksOffset);

            rootBlock.BitmapExtensionBlocksOffset =
                rootBlock.BitmapExtensionBlocks.Any()
                    ? rootBlock.BitmapBlocksOffset + Constants.MaxBitmapBlockPointersInRootBlock
                    : 0;

            SetBitmapExtensionBlockOffsets(rootBlock.BitmapExtensionBlocks, rootBlock.BitmapExtensionBlocksOffset);
        }

        public static uint SetBitmapBlockOffsets(
            IEnumerable<BitmapBlock> bitmapBlocks, uint startOffset)
        {
            var offset = startOffset;
            foreach (var bitmapBlock in bitmapBlocks)
            {
                bitmapBlock.Offset = offset++;
            }

            return offset;
        }
        
        public static void SetBitmapExtensionBlockOffsets(IEnumerable<BitmapExtensionBlock> bitmapExtensionBlocks, uint startOffset)
        {
            var bitmapExtensionBlocksList = bitmapExtensionBlocks.ToList();
            
            var offset = startOffset;
            for (var i = 0; i < bitmapExtensionBlocksList.Count; i++)
            {
                var bitmapExtensionBlock = bitmapExtensionBlocksList[i];
                
                bitmapExtensionBlock.Offset = offset++;

                offset = SetBitmapBlockOffsets(bitmapExtensionBlock.BitmapBlocks, offset);

                bitmapExtensionBlock.NextBitmapExtensionBlockPointer =
                    i < bitmapExtensionBlocksList.Count - 1 ? offset : 0;
            }
        }
    }
}