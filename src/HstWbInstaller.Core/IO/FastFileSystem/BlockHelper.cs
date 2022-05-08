namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Threading.Tasks;
    using Extensions;

    public static class BlockHelper
    {
        public static int CalculateOffsetsPerBitmapBlockCount(uint blockSize)
        {
            // calculate bitmaps per bitmap blocks count
            return Convert.ToInt32((blockSize - IO.Constants.LongSize) / IO.Constants.LongSize);
        }

        public static int CalculateBitmapsPerBitmapBlockCount(uint blockSize)
        {
            // calculate bitmaps per bitmap blocks count
            return Convert.ToInt32(CalculateOffsetsPerBitmapBlockCount(blockSize) *
                                   Constants.BitmapsPerLong);
        }

        public static IEnumerable<BitmapBlock> CreateBitmapBlocks(uint lowCyl, uint highCyl, uint heads,
            uint blocksPerTrack, uint blockSize)
        {
            // calculate blocks count
            var cylinders = highCyl - lowCyl + 1;
            var blocksCount = cylinders * heads * blocksPerTrack;

            var bitmapsPerBitmapBlockCount = CalculateBitmapsPerBitmapBlockCount(blockSize);

            // build bitmaps
            var blocksFreeMap = new bool[blocksCount];
            for (var i = 0; i < blocksCount; i++)
            {
                blocksFreeMap[i] = true;
            }

            return blocksFreeMap.ChunkBy(bitmapsPerBitmapBlockCount).Select(x => new BitmapBlock
            {
                BlocksFreeMap = x.ToArray()
            }).ToList();
        }

        public static IEnumerable<BitmapExtensionBlock> CreateBitmapExtensionBlocks(
            IEnumerable<BitmapBlock> bitmapBlocks, uint blockSize)
        {
            // calculate pointers per bitmap extension block based on block size - next pointer
            var pointersPerBitmapExtensionBlock =
                Convert.ToInt32((blockSize - IO.Constants.LongSize) / IO.Constants.LongSize);

            // chunk bitmap blocks
            var bitmapBlockChunks = bitmapBlocks.ChunkBy(pointersPerBitmapExtensionBlock).ToList();

            return bitmapBlockChunks.Select(x => new BitmapExtensionBlock
            {
                BitmapBlocks = x,
            }).ToList();
        }

        public static IEnumerable<BitmapExtensionBlock> CreateBitmapExtensionBlocks(
            IEnumerable<BitmapBlock> bitmapBlocks, uint blockSize, uint bitmapExtensionBlockOffset)
        {
            // calculate number of offsets stored in bitmap extension block
            var offsetsPerBitmapExtensionBlock = Convert.ToInt32((blockSize - 4) / 4);
            var currentBitmapExtensionBlockOffset = bitmapExtensionBlockOffset;

            var bitmapBlockChunks = bitmapBlocks.ChunkBy(offsetsPerBitmapExtensionBlock).ToList();
            for (var i = 0; i < bitmapBlockChunks.Count; i++)
            {
                var bitmapBlockChunk = bitmapBlockChunks[i].ToList();

                var nextBitmapExtensionBlockOffset =
                    OffsetHelper.SetBitmapBlockOffsets(bitmapBlockChunk, currentBitmapExtensionBlockOffset + 1) + 1;

                yield return new BitmapExtensionBlock
                {
                    Offset = currentBitmapExtensionBlockOffset,
                    BitmapBlocks = bitmapBlockChunk,
                    NextBitmapExtensionBlockPointer =
                        i < bitmapBlockChunks.Count - 1 ? nextBitmapExtensionBlockOffset : 0
                };

                currentBitmapExtensionBlockOffset = nextBitmapExtensionBlockOffset;
            }
        }

        /// <summary>
        /// create root block for fast file system
        /// </summary>
        /// <param name="lowCyl"></param>
        /// <param name="highCyl"></param>
        /// <param name="heads"></param>
        /// <param name="blocksPerTrack"></param>
        /// <param name="reserved"></param>
        /// <param name="preAlloc"></param>
        /// <param name="blockSize"></param>
        /// <param name="diskName"></param>
        /// <returns></returns>
        public static RootBlock CreateRootBlock(uint lowCyl, uint highCyl, uint heads, uint blocksPerTrack,
            uint reserved, uint blockSize, string diskName)
        {
            var rootBlockOffset =
                OffsetHelper.CalculateRootBlockOffset(lowCyl, highCyl, reserved, heads, blocksPerTrack);

            var bitmapBlocks = CreateBitmapBlocks(lowCyl, highCyl, heads, blocksPerTrack, blockSize).ToList();
            var bitmapExtensionBlocks =
                CreateBitmapExtensionBlocks(bitmapBlocks.Skip(Constants.MaxBitmapBlockPointersInRootBlock), blockSize)
                    .ToList();
            
            var rootBlock = new RootBlock
            {
                HeaderKey = (int)rootBlockOffset,
                Offset = rootBlockOffset,
                BitmapBlocksOffset = rootBlockOffset + 1,
                DiskName = diskName,
                BitmapBlocks = bitmapBlocks.Take(Constants.MaxBitmapBlockPointersInRootBlock).ToList(),
                BitmapExtensionBlocks = bitmapExtensionBlocks.ToList(),
                Extension = (int)rootBlockOffset
            };

            OffsetHelper.SetRootBlockOffsets(rootBlock);

            rootBlock.BitmapExtensionBlocksOffset = bitmapExtensionBlocks.Count > 0
                ? bitmapExtensionBlocks[0].Offset
                : 0;

            // create bitmap of blocks allocated by root block, bitmap blocks and bitmap extension blocks
            var bitmaps = new Dictionary<uint, bool>
            {
                { rootBlockOffset, false }
            };

            foreach (var bitmapBlock in bitmapBlocks)
            {
                bitmaps[bitmapBlock.Offset] = false;
            }

            foreach (var bitmapExtensionBlock in bitmapExtensionBlocks)
            {
                bitmaps[bitmapExtensionBlock.Offset] = false;
            }
            
            UpdateBitmaps(bitmapBlocks, bitmaps, reserved, blockSize);
            
            return rootBlock;
        }

        public static void UpdateBitmaps(IEnumerable<BitmapBlock> bitmapBlocks,
            IDictionary<uint, bool> blocksFreeMap, uint reserved, uint blockSize)
        {
            var bitmapBlocksList = bitmapBlocks.ToList();
            var bitmapsPerBitmapBlockCount = CalculateBitmapsPerBitmapBlockCount(blockSize);

            foreach (var entry in blocksFreeMap)
            {
                var bitmapBlockIndex = Convert.ToInt32((entry.Key - reserved) / bitmapsPerBitmapBlockCount);
                var blockIndex = (entry.Key - reserved) % bitmapsPerBitmapBlockCount;

                bitmapBlocksList[bitmapBlockIndex].BlocksFreeMap[blockIndex] = entry.Value;
            }
        }
        
        public static async Task<IEnumerable<BitmapBlock>> ReadBitmapBlocks(Volume volume,
            IEnumerable<uint> bitmapBlockOffsets)
        {
            var bitmapBlocks = new List<BitmapBlock>();
            foreach (var bitmapBlockOffset in bitmapBlockOffsets)
            {
                var bitmapBlock = await Disk.ReadBitmapBlock(volume, bitmapBlockOffset);
                bitmapBlock.Offset = bitmapBlockOffset;

                bitmapBlocks.Add(bitmapBlock);
            }

            return bitmapBlocks;
        }

        public static async Task<IEnumerable<BitmapExtensionBlock>> ReadBitmapExtensionBlocks(Volume volume,
            uint bitmapExtensionBlocksOffset)
        {
            var bitmapExtensionBlocks = new List<BitmapExtensionBlock>();

            while (bitmapExtensionBlocksOffset != 0)
            {
                var bitmapExtensionBlock = await Disk.ReadBitmapExtensionBlock(volume, bitmapExtensionBlocksOffset);
                bitmapExtensionBlock.BitmapBlocks =
                    await ReadBitmapBlocks(volume, bitmapExtensionBlock.BitmapBlockOffsets);

                bitmapExtensionBlocks.Add(bitmapExtensionBlock);

                bitmapExtensionBlocksOffset = bitmapExtensionBlock.NextBitmapExtensionBlockPointer;
            }

            return bitmapExtensionBlocks;
        }
    }
}