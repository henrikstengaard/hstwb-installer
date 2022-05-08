namespace HstWbInstaller.Core.Tests.FastFileSystemTests
{
    using System.IO;
    using System.Threading.Tasks;
    using IO;
    using IO.FastFileSystem;
    using Xunit;
    using Constants = IO.FastFileSystem.Constants;

    public class GivenRootBlockReader
    {
        [Fact]
        public async Task WhenReadRootBlockFromAdfThenRootBlockIsValid()
        {
            // arrange - adf file
            var adfPath = @"TestData\adf\ffstest.adf";

            // arrange - calculate root block offset
            var rootBlockOffset = OffsetHelper.CalculateRootBlockOffset(FloppyDiskConstants.DoubleDensity.LowCyl,
                FloppyDiskConstants.DoubleDensity.HighCyl, FloppyDiskConstants.DoubleDensity.ReservedBlocks,
                FloppyDiskConstants.DoubleDensity.Heads, FloppyDiskConstants.DoubleDensity.Sectors);
            await using var adfStream = System.IO.File.OpenRead(adfPath);

            // arrange - seek root block offset
            adfStream.Seek(rootBlockOffset * FloppyDiskConstants.BlockSize, SeekOrigin.Begin);

            // act - read root block bytes
            var rootBlockBytes = new byte[FloppyDiskConstants.BlockSize];
            var bytesRead = await adfStream.ReadAsync(rootBlockBytes, 0, FloppyDiskConstants.BlockSize);
            var rootBlock = await RootBlockReader.Parse(rootBlockBytes);
            
            // assert - bytes read and root block matches type and disk name
            Assert.Equal(FloppyDiskConstants.BlockSize, bytesRead);
            Assert.Equal(2, rootBlock.Type);
            Assert.Equal(0, rootBlock.HeaderKey);
            Assert.Equal(0, rootBlock.HighSeq);
            Assert.Equal(Constants.HT_SIZE, (int)rootBlock.HashTableSize);
            Assert.Equal("FFSTEST", rootBlock.DiskName);
        }
    }
}