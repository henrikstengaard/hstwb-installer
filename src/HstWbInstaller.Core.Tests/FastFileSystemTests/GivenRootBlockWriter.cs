namespace HstWbInstaller.Core.Tests.FastFileSystemTests
{
    using System;
    using System.IO;
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
                BitmapBlockOffsets = new[]{881},
                RootAlterationDate = Date,
                DiskAlterationDate = DateTime.MinValue,
                FileSystemCreationDate = Date,
                BitmapBlocks = new []{new BitmapBlock()} // dummy used for writing bitmap block
            };
            
            // act - build root block bytes
            var rootBlockBytes = await RootBlockWriter.BuildBlock(rootBlock, blockSize);
            
            // assert - root block bytes are equal to expected for double density floppy disk
            var expectedRootBlockBytes = await CreateExpectedRootBlockBytes();

            Assert.Equal(expectedRootBlockBytes, rootBlockBytes);
        }
        
        [Fact]
        public async Task WhenReadParseAndBuildRootBlockThenRootBlockIsUnchanged()
        {
            var adfPath = @"TestData\adf\ffstest.adf";

            // arrange - open adf path
            await using var adfStream = System.IO.File.OpenRead(adfPath);

            // act - seek root block 880 offset for floppy disk
            adfStream.Seek(880 * 512, SeekOrigin.Begin);

            // act - read root block bytes
            var rootBlockBytes = new byte[512];
            var bytesRead = await adfStream.ReadAsync(rootBlockBytes, 0, rootBlockBytes.Length);
            Assert.Equal(512, bytesRead);

            // act - parse and build root block
            var expectedRootBlock = await RootBlockReader.Parse(rootBlockBytes);
            var newRootBlockBytes = await RootBlockWriter.BuildBlock(expectedRootBlock, 512);

            // assert - root block and new root block bytes are equal
            Assert.Equal(rootBlockBytes, newRootBlockBytes);
        }
    }
}