namespace HstWbInstaller.Core.Tests.FastFileSystemTests
{
    using System.Collections.Generic;
    using System.Linq;
    using IO;
    using IO.FastFileSystem;
    using Xunit;

    public class GivenBlockHelper
    {
        [Fact]
        public void WhenCreateBitmapBlockThenBitmapsMatchBlocksAndAreSetToBeFree()
        {
            // calculate blocks
            var cylinders = FloppyDiskConstants.DoubleDensity.HighCyl - FloppyDiskConstants.DoubleDensity.LowCyl + 1;
            var blocks = cylinders * FloppyDiskConstants.DoubleDensity.Heads *
                         FloppyDiskConstants.DoubleDensity.Sectors;

            // act - create bitmap blocks
            var bitmapBlocks = BlockHelper.CreateBitmapBlocks(
                FloppyDiskConstants.DoubleDensity.LowCyl,
                FloppyDiskConstants.DoubleDensity.HighCyl,
                FloppyDiskConstants.DoubleDensity.Heads,
                FloppyDiskConstants.DoubleDensity.Sectors,
                FloppyDiskConstants.BlockSize).ToList();

            // assert - 1 bitmap block is created and have bitmaps matching blocks
            Assert.Single(bitmapBlocks);
            Assert.NotEmpty(bitmapBlocks[0].BlocksFreeMap);
            Assert.Equal(blocks, bitmapBlocks[0].BlocksFreeMap.Length);

            // assert - bitmaps are set to be free (true)
            Assert.Equal(blocks, bitmapBlocks[0].BlocksFreeMap.Count(x => x));
        }

        [Fact]
        public void WhenCreateBitmapExtensionBlocksSmallerThanBlockSizeThenOnlyOneIsCreated()
        {
            const int blockSize = 512;
            const int nextPointerSize = 4;
            const int pointerSize = 4;
            var offsetsPerBitmapExtensionBlock = (blockSize - nextPointerSize) / pointerSize;
            var bitmapBlocksCount = offsetsPerBitmapExtensionBlock - 10;
            var bitmapBlocks = Enumerable.Range(1, bitmapBlocksCount)
                .Select(x => new BitmapBlock()).ToList();

            var bitmapExtensionBlocks = BlockHelper
                .CreateBitmapExtensionBlocks(bitmapBlocks, blockSize)
                .ToList();

            Assert.Single(bitmapExtensionBlocks);

            var bitmapExtensionBlock1 = bitmapExtensionBlocks[0];
            Assert.Equal(bitmapBlocksCount, bitmapExtensionBlock1.BitmapBlocks.Count());
        }

        [Fact]
        public void WhenCreateBitmapExtensionBlocksLargerThanBlockSizeThenMultipleAreCreated()
        {
            const int blockSize = 512;
            const int nextPointerSize = 4;
            const int pointerSize = 4;
            var offsetsPerBitmapExtensionBlock = (blockSize - nextPointerSize) / pointerSize;
            var bitmapBlocksCount = offsetsPerBitmapExtensionBlock + 10;
            var bitmapBlocks = Enumerable.Range(1, bitmapBlocksCount)
                .Select(x => new BitmapBlock()).ToList();

            var bitmapExtensionBlocks = BlockHelper
                .CreateBitmapExtensionBlocks(bitmapBlocks, blockSize)
                .ToList();

            Assert.NotEmpty(bitmapExtensionBlocks);
            Assert.Equal(2, bitmapExtensionBlocks.Count);

            var bitmapExtensionBlock1 = bitmapExtensionBlocks[0];
            Assert.Equal(offsetsPerBitmapExtensionBlock, bitmapExtensionBlock1.BitmapBlocks.Count());

            var bitmapExtensionBlock2 = bitmapExtensionBlocks[1];
            Assert.Equal(10, bitmapExtensionBlock2.BitmapBlocks.Count());
        }

        [Fact]
        public void WhenUpdateBitmapsForBitmapBlocksThenBitmapsAreChanged()
        {
            var bitmapBlocks = BlockHelper.CreateBitmapBlocks(
                FloppyDiskConstants.DoubleDensity.LowCyl,
                FloppyDiskConstants.DoubleDensity.HighCyl,
                FloppyDiskConstants.DoubleDensity.Heads,
                FloppyDiskConstants.DoubleDensity.Sectors,
                FloppyDiskConstants.BlockSize).ToList();

            var rootBlockOffset = 880U;
            var bitmapBlockOffset = 881U;

            var bitmaps = new Dictionary<uint, bool>
            {
                { rootBlockOffset, false },
                { bitmapBlockOffset, false }
            };

            // act - update bitmaps
            BlockHelper.UpdateBitmaps(bitmapBlocks, bitmaps, FloppyDiskConstants.DoubleDensity.ReservedBlocks,
                FloppyDiskConstants.BlockSize);

            // assert - bitmaps for root block and bitmap block offsets are changed to false
            Assert.Single(bitmapBlocks);
            Assert.False(bitmapBlocks[0].BlocksFreeMap[rootBlockOffset]);
            Assert.False(bitmapBlocks[0].BlocksFreeMap[bitmapBlockOffset]);
        }
    }
}