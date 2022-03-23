namespace HstWbInstaller.Core.Tests.FastFileSystemTests
{
    using System.IO;
    using System.Threading.Tasks;
    using Extensions;
    using IO;
    using IO.FastFileSystem;
    using Xunit;

    public class GivenBitmapBlockWriter : FastFileSystemTestBase
    {
        [Fact]
        public async Task WhenBuildingBitmapBlockForDoubleDensityFloppyDiskThenBytesMatch()
        {
            // arrange - create bitmap block for blank formatted adf
            var blocks = FloppyDiskConstants.DoubleDensity.Size / FloppyDiskConstants.BlockSize;
            var blockFree = new bool[blocks];
            for (var i = 0; i < blocks; i++)
            {
                blockFree[i] = true;
            }

            // arrange - calculate root block offset for double density floppy disk
            var rootBlockOffset = FastFileSystemBlockHelper.CalculateRootBlockOffset(
                FloppyDiskConstants.DoubleDensity.LowCyl,
                FloppyDiskConstants.DoubleDensity.HighCyl,
                FloppyDiskConstants.DoubleDensity.ReservedBlocks,
                FloppyDiskConstants.DoubleDensity.Heads,
                FloppyDiskConstants.DoubleDensity.Sectors);

            // arrange - create bitmap block for blank formatted adf
            var bitmapBlockOffset = rootBlockOffset + 1;
            blockFree[rootBlockOffset] = false;
            blockFree[bitmapBlockOffset] = false;
            var bitmapBlock = new BitmapBlock
            {
                BlockFree = blockFree
            };

            // act - build bitmap block bytes
            var bitmapBlockBytes = await BitmapBlockWriter.BuildBlock(bitmapBlock);

            // assert - bitmap block bytes are equal to expected
            var expectedBitmapBlockBytes = await CreateExpectedBitmapBlockBytes();
            Assert.Equal(expectedBitmapBlockBytes, bitmapBlockBytes);
        }

        [Fact]
        public async Task WhenCreatingBitmapBlockWithFirstBlockSetAsAllocatedThenBytesDoesntHaveBitSet()
        {
            // arrange
            var bitmapBlock = CreateBitmapBlock(FloppyDiskConstants.BlockSize);
            bitmapBlock.BlockFree[0] = false;

            // act - build bitmap block bytes
            var blockBytes = await BitmapBlockWriter.BuildBlock(bitmapBlock);
            var blockStream = new MemoryStream(blockBytes);

            // ignore checksum
            blockStream.Seek(4, SeekOrigin.Begin);

            // assert
            var mapBytes = await blockStream.ReadBytes(4);

            // assert - map bytes doesn't have 1st / 128 bit set when is it set as allocated (block free = false)
            var expectedMapBytes = new byte[] { 255 - 128, 255, 255, 255 };
            Assert.Equal(expectedMapBytes, mapBytes);

            // assert - free blocks have bits set to 1, 255 for all bytes
            var expectedFreeMapBytes = new byte[] { 255, 255, 255, 255 };
            for (var i = 0; i < ((FloppyDiskConstants.BlockSize - Constants.CHECKSUM_SIZE) / 4) - 1; i++)
            {
                var freeMapBytes = await blockStream.ReadBytes(4);
                Assert.Equal(expectedFreeMapBytes, freeMapBytes);
            }
        }

        private BitmapBlock CreateBitmapBlock(int blockSize)
        {
            var blocksPerMap = 32;
            var mapsPerLongDataType = 4;

            var bitmapBlock = new BitmapBlock
            {
                BlockFree = new bool[((blockSize - Constants.CHECKSUM_SIZE) / mapsPerLongDataType) * blocksPerMap]
            };

            for (var i = 0; i < bitmapBlock.BlockFree.Length; i++)
            {
                bitmapBlock.BlockFree[i] = true;
            }

            return bitmapBlock;
        }
    }
}