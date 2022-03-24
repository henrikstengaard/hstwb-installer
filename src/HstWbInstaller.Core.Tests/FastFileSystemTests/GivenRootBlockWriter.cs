namespace HstWbInstaller.Core.Tests.FastFileSystemTests
{
    using System;
    using System.Threading.Tasks;
    using IO.FastFileSystem;
    using Xunit;

    public class GivenRootBlockWriter : FastFileSystemTestBase
    {
        [Fact]
        public async Task WhenBuildingRootBlockForDoubleDensityFloppyDiskThenBytesMatch()
        {
            // arrange - create root block for double density floppy disk
            var blockSize = 512U;
            var now = DateTime.UtcNow;
            var diskName = "HstWB";
            var rootBlock = new RootBlock
            {
                DiskName = diskName,
                BitmapBlocksOffset = 881,
                RootAlterationDate = now,
                DiskAlterationDate = DateTime.MinValue,
                FileSystemCreationDate = now,
                BitmapBlocks = new []{new BitmapBlock()} // dummy used for writing bitmap block
            };
            
            // act - build root block bytes
            var rootBlockBytes = await RootBlockWriter.BuildBlock(rootBlock, blockSize);
            
            // assert - root block bytes are equal to expected for double density floppy disk
            var expectedRootBlockBytes = await CreateExpectedRootBlockBytes();
            Assert.Equal(expectedRootBlockBytes, rootBlockBytes);
        }
    }
}