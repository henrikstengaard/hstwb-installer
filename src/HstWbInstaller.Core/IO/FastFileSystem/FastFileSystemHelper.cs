namespace HstWbInstaller.Core.IO.FastFileSystem
{
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using Extensions;
    using RigidDiskBlocks;

    public static class FastFileSystemHelper
    {
        public static uint CalculateRootBlockOffset(uint lowCyl, uint highCyl, uint reserved, uint heads, uint sectors)
        {
            var cylinders = highCyl - lowCyl + 1;
            var highKey = cylinders * heads * sectors - reserved;
            var rootKey = (reserved + highKey) / 2;
            return rootKey;
        }

        public static IEnumerable<BitmapExtensionBlock> CreateBitmapExtensionBlocks(
            uint blockSize, IEnumerable<BitmapBlock> bitmapBlocks, uint bitmapExtensionBlockOffset)
        {
            var offsetsPerBitmapExtensionBlock = Convert.ToInt32((blockSize - 4) / 4);
            var currentBitmapExtensionBlockOffset = bitmapExtensionBlockOffset;

            var bitmapBlockChunks = bitmapBlocks.ChunkBy(offsetsPerBitmapExtensionBlock).ToList();
            for (var i = 0; i < bitmapBlockChunks.Count; i++)
            {
                var bitmapBlockChunk = bitmapBlockChunks[i].ToList();

                var nextBitmapExtensionBlockOffset =
                    SetBitmapBlocksOffset(bitmapBlockChunk, currentBitmapExtensionBlockOffset + 1) + 1;

                yield return new BitmapExtensionBlock
                {
                    Offset = currentBitmapExtensionBlockOffset,
                    BitmapBlocks = bitmapBlockChunk,
                    NextBitmapExtensionBlockPointer = i < bitmapBlockChunks.Count - 1 ? nextBitmapExtensionBlockOffset : 0
                };

                currentBitmapExtensionBlockOffset = nextBitmapExtensionBlockOffset;
            }
        }

        public static uint SetBitmapBlocksOffset(
            IEnumerable<BitmapBlock> bitmapBlocks, uint startOffset)
        {
            var offset = startOffset;
            foreach (var bitmapBlock in bitmapBlocks)
            {
                bitmapBlock.Offset = offset++;
            }

            return offset;
        }
        
        /// <summary>
        /// format partition with fast file system
        /// </summary>
        public static async Task FormatPartition(Stream stream, PartitionBlock partitionBlock,
            string diskName)
        {
            var partitionStartByteOffset = partitionBlock.LowCyl * partitionBlock.Surfaces *
                                           partitionBlock.BlocksPerTrack *
                                           partitionBlock.FileSystemBlockSize;
            stream.Seek(partitionStartByteOffset, SeekOrigin.Begin);
            await stream.WriteBytes(partitionBlock.DosType);

            var rootBlockOffset = FastFileSystemHelper.CalculateRootBlockOffset(
                partitionBlock.LowCyl,
                partitionBlock.HighCyl,
                partitionBlock.Reserved,
                partitionBlock.Surfaces,
                partitionBlock.BlocksPerTrack);

            var rootBlock = new RootBlock
            {
                DiskName = diskName,
                BitmapBlocksOffset = rootBlockOffset + 1U,
                FirstDirectoryCacheBlock = rootBlockOffset
            };

            // bitmap blocks
            var cylinders = partitionBlock.HighCyl - partitionBlock.LowCyl + 1;
            var blocks = cylinders * partitionBlock.Surfaces * partitionBlock.BlocksPerTrack;

            var mapsPerBitmapBlocks =
                Convert.ToInt32((partitionBlock.FileSystemBlockSize - Constants.CHECKSUM_SIZE) / 4 * 32);
            var bitmapBlocksCount = Convert.ToInt32(Math.Ceiling((double)blocks / mapsPerBitmapBlocks)) + 1;

            var offsetsPerBitmapExtensionBlock = (partitionBlock.FileSystemBlockSize - 4) / 4;
            var bitmapExtensionBlocksCount =
                bitmapBlocksCount > 25
                    ? Convert.ToInt32(Math.Ceiling((double)(bitmapBlocksCount - 25) / offsetsPerBitmapExtensionBlock))
                    : 0;

            // build blocks free
            var blocksFree = new bool[blocks];
            for (var i = 0; i < blocks; i++)
            {
                if (i >= rootBlockOffset - partitionBlock.Reserved && i <= rootBlockOffset + bitmapBlocksCount +
                    bitmapExtensionBlocksCount - partitionBlock.Reserved - 1)
                {
                    blocksFree[i] = false;
                    continue;
                }

                blocksFree[i] = true;
            }

            var bitmapBlocks = blocksFree.ChunkBy(mapsPerBitmapBlocks).Select(x => new BitmapBlock
            {
                BlockFree = x.ToArray()
            }).ToList();

            rootBlock.BitmapBlocks = bitmapBlocks;

            if (bitmapBlocks.Count > 25)
            {
                rootBlock.BitmapExtensionBlocksOffset = rootBlock.BitmapBlocksOffset + 25;
            }

            // build root block bytes
            var rootBlockBytes = await RootBlockWriter.BuildBlock(rootBlock, partitionBlock.FileSystemBlockSize);

            // write root block
            var rootBlockByteOffset = partitionStartByteOffset + rootBlockOffset * partitionBlock.FileSystemBlockSize;
            stream.Seek(rootBlockByteOffset, SeekOrigin.Begin);
            await stream.WriteBytes(rootBlockBytes);

            // write bitmap blocks (first 25)
            var bitmapBlockByteOffset = partitionStartByteOffset +
                                        rootBlock.BitmapBlocksOffset * partitionBlock.FileSystemBlockSize;
            stream.Seek(bitmapBlockByteOffset, SeekOrigin.Begin);
            foreach (var bitmapBlock in bitmapBlocks.Take(25))
            {
                var bitmapBlockBytes = await BitmapBlockWriter.BuildBlock(bitmapBlock);
                await stream.WriteBytes(bitmapBlockBytes);
            }

            if (bitmapBlocks.Count > 25)
            {
                // seek bitmap extension block offset
                var bitmapExtensionBlockByteOffset = partitionStartByteOffset +
                                                     rootBlock.BitmapExtensionBlocksOffset *
                                                     partitionBlock.FileSystemBlockSize;
                stream.Seek(bitmapExtensionBlockByteOffset, SeekOrigin.Begin);

                // build bitmap extension blocks
                var bitmapExtensionBlocks = FastFileSystemHelper
                    .CreateBitmapExtensionBlocks(partitionBlock.FileSystemBlockSize, bitmapBlocks.Skip(25),
                        rootBlock.BitmapExtensionBlocksOffset);

                // build and write bitmap extension block bytes
                foreach (var bitmapExtensionBlock in bitmapExtensionBlocks)
                {
                    var bitmapExtensionBlockBytes =
                        await BitmapExtensionBlockWriter.BuildBlock(bitmapExtensionBlock,
                            partitionBlock.FileSystemBlockSize);
                    await stream.WriteBytes(bitmapExtensionBlockBytes);

                    foreach (var bitmapBlock in bitmapExtensionBlock.BitmapBlocks)
                    {
                        var bitmapBlockBytes = await BitmapBlockWriter.BuildBlock(bitmapBlock);
                        await stream.WriteBytes(bitmapBlockBytes);
                    }
                }
            }
        }
    }
}