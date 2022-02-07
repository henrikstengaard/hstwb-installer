namespace HstWbInstaller.Core.Tests
{
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using IO.Hunks;
    using Xunit;

    public class GivenHunkReader
    {
        [Fact]
        public async Task WhenReadHunkHeaderThenHunksAreReturned()
        {
            await using var pfs3AioStream = new MemoryStream(await File.ReadAllBytesAsync(@"TestData\pfs3aio"));
            var hunks = (await HunkReader.Parse(pfs3AioStream)).ToList();
            Assert.NotEmpty(hunks);
            Assert.Equal(4, hunks.Count);
            Assert.Equal(typeof(Header), hunks[0].GetType());
            Assert.Equal(typeof(Code), hunks[1].GetType());
            Assert.Equal(typeof(ReLoc32), hunks[2].GetType());
            Assert.Equal(typeof(End), hunks[3].GetType());
        }
    }
}