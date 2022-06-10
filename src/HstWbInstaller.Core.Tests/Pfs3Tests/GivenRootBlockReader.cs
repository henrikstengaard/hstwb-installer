namespace HstWbInstaller.Core.Tests.Pfs3Tests
{
    using System.IO;
    using System.Threading.Tasks;
    using IO.Pfs3;
    using Xunit;

    public class GivenRootBlockReader
    {
        [Fact]
        public async Task WhenReadRootBlockFromPfs3PartitionThenRootBlockIsValid()
        {
            var blockBytes = await File.ReadAllBytesAsync(@"TestData\Pfs3RootBlock");
            var rootBlock = await RootBlockReader.Parse(blockBytes);
            
            Assert.Equal("Workbench", rootBlock.DiskName);
        }
    }
}