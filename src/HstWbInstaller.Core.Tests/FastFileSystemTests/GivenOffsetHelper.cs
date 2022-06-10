namespace HstWbInstaller.Core.Tests.FastFileSystemTests
{
    using System.Linq;
    using IO;
    using IO.FastFileSystem;
    using Xunit;

    public class GivenOffsetHelper
    {
        [Fact]
        public void WhenCalculateRootBlockOffsetForDoubleDensityFloppyDiskThenOffsetMatch()
        {
            var rootBlockOffset = OffsetHelper.CalculateRootBlockOffset(
                FloppyDiskConstants.DoubleDensity.LowCyl,
                FloppyDiskConstants.DoubleDensity.HighCyl,
                FloppyDiskConstants.DoubleDensity.ReservedBlocks,
                FloppyDiskConstants.DoubleDensity.Heads,
                FloppyDiskConstants.DoubleDensity.Sectors);

            Assert.Equal(880U, rootBlockOffset);
        }

        [Fact]
        public void WhenSetOffsetsForOneBitmapExtensionBlockThenOffsetsAreSetSequential()
        {
            const int blockSize = 512;
            const int offsetSize = 4;
            const uint bitmapExtensionBlockOffset = 100U;
            var offsetsPerBitmapExtensionBlock = (blockSize - offsetSize) / offsetSize;
            var bitmapBlocksCount = offsetsPerBitmapExtensionBlock - 10;
            var bitmapBlocks = Enumerable.Range(1, bitmapBlocksCount)
                .Select(x => new BitmapBlock()).ToList();
            
            var bitmapExtensionBlocks = BlockHelper
                .CreateBitmapExtensionBlocks(bitmapBlocks, blockSize)
                .ToList();

            OffsetHelper.SetBitmapExtensionBlockOffsets(bitmapExtensionBlocks, bitmapExtensionBlockOffset);
            
            Assert.Single(bitmapExtensionBlocks);

            var bitmapExtensionBlock1 = bitmapExtensionBlocks[0];
            Assert.Equal(100U, bitmapExtensionBlock1.Offset);
            Assert.Equal(bitmapBlocksCount, bitmapExtensionBlock1.BitmapBlocks.Count());
            Assert.Equal(0U, bitmapExtensionBlock1.NextBitmapExtensionBlockPointer);

            var bitmapBlocks1 = bitmapExtensionBlock1.BitmapBlocks.ToList();
            for (var i = 0; i < bitmapBlocks1.Count; i++)
            {
                Assert.Equal(100U + i + 1, bitmapBlocks1[i].Offset);
            }
        }
        
        [Fact]
        public void WhenSetOffsetsForMultipleBitmapExtensionBlocksThenOffsetsAreSetSequential()
        {
            const int blockSize = 512;
            const int nextPointerSize = 4;
            const int pointerSize = 4;
            const uint bitmapExtensionBlockOffset = 100U;
            
            var offsetsPerBitmapExtensionBlock = (blockSize - nextPointerSize) / pointerSize;
            var bitmapBlocksCount = offsetsPerBitmapExtensionBlock + 10;
            var bitmapBlocks = Enumerable.Range(1, bitmapBlocksCount)
                .Select(x => new BitmapBlock()).ToList();
            
            var bitmapExtensionBlocks = BlockHelper
                .CreateBitmapExtensionBlocks(bitmapBlocks, blockSize, bitmapExtensionBlockOffset)
                .ToList();

            OffsetHelper.SetBitmapExtensionBlockOffsets(bitmapExtensionBlocks, bitmapExtensionBlockOffset);
            
            Assert.NotEmpty(bitmapExtensionBlocks);
            Assert.Equal(2, bitmapExtensionBlocks.Count);

            var bitmapExtensionBlock1 = bitmapExtensionBlocks[0];
            Assert.Equal(100U, bitmapExtensionBlock1.Offset);
            Assert.Equal(offsetsPerBitmapExtensionBlock, bitmapExtensionBlock1.BitmapBlocks.Count());
            Assert.Equal(100U + offsetsPerBitmapExtensionBlock + 1,
                bitmapExtensionBlock1.NextBitmapExtensionBlockPointer);

            var bitmapBlocks1 = bitmapExtensionBlock1.BitmapBlocks.ToList();
            for (var i = 0; i < bitmapBlocks1.Count; i++)
            {
                Assert.Equal(100U + i + 1, bitmapBlocks1[i].Offset);
            }

            var bitmapExtensionBlock2 = bitmapExtensionBlocks[1];
            Assert.Equal(100U + offsetsPerBitmapExtensionBlock + 1, bitmapExtensionBlock2.Offset);
            Assert.Equal(10, bitmapExtensionBlock2.BitmapBlocks.Count());
            Assert.Equal(0U, bitmapExtensionBlock2.NextBitmapExtensionBlockPointer);

            var bitmapBlocks2 = bitmapExtensionBlock2.BitmapBlocks.ToList();
            for (var i = 0; i < bitmapBlocks2.Count; i++)
            {
                Assert.Equal(100U + offsetsPerBitmapExtensionBlock + 2 + i, bitmapBlocks2[i].Offset);
            }
        }
    }
}