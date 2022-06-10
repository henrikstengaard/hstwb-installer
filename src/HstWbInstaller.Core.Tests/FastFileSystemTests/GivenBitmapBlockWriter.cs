namespace HstWbInstaller.Core.Tests.FastFileSystemTests
{
    using System.Threading.Tasks;
    using IO;
    using IO.FastFileSystem;
    using Xunit;

    public class GivenBitmapBlockWriter : FastFileSystemTestBase
    {
        [Fact]
        public async Task WhenBuildingBitmapBlockForDoubleDensityFloppyDiskThenBytesMatch()
        {
            // 2 blocks reserved for boot block
            var bootBlocks = 2;
            
            // arrange - create bitmap block for blank formatted adf
            var blocks = FloppyDiskConstants.DoubleDensity.Size / FloppyDiskConstants.BlockSize;
            var blockFree = new bool[blocks];
            for (var i = 0; i < blocks; i++)
            {
                blockFree[i] = true;
            }

            // arrange - calculate root block offset for double density floppy disk
            var rootBlockOffset = OffsetHelper.CalculateRootBlockOffset(
                FloppyDiskConstants.DoubleDensity.LowCyl,
                FloppyDiskConstants.DoubleDensity.HighCyl,
                FloppyDiskConstants.DoubleDensity.ReservedBlocks,
                FloppyDiskConstants.DoubleDensity.Heads,
                FloppyDiskConstants.DoubleDensity.Sectors);

            // arrange - create bitmap block for blank formatted adf
            var bitmapBlockOffset = rootBlockOffset + 1;
            blockFree[rootBlockOffset - bootBlocks] = false;
            blockFree[bitmapBlockOffset - bootBlocks] = false;
            var bitmapBlock = new BitmapBlock
            {
                BlocksFreeMap = blockFree
            };

            // act - build bitmap block bytes
            var bitmapBlockBytes = await BitmapBlockWriter.BuildBlock(bitmapBlock);

            // assert - bitmap block bytes are equal to expected
            var expectedBitmapBlockBytes = await CreateExpectedBitmapBlockBytes();
            Assert.Equal(expectedBitmapBlockBytes, bitmapBlockBytes);
        }
    }
}