namespace HstWbInstaller.Core.Tests.CompressionTests
{
    using System;
    using System.IO;
    using System.Threading.Tasks;
    using IO.Lha;
    using Xunit;

    public class GivenLhExt
    {
        [Fact]
        public async Task WhenExtractUncompressedLh0DataThenBytesAreEqual()
        {
            // arrange - lh0 uncompressed entry (bytes extracted from header end to next header)
            var header = new LzHeader
            {
                Method = Constants.LZHUFF0_METHOD,
                Name = "test.txt",
                OriginalSize = 15,
                PackedSize = 15,
                HasCrc = true,
                Crc = 17248
            };
            var lh0CompressedBytes = await File.ReadAllBytesAsync(@"TestData\lha\test.txt.lh0.bin");
            var input = new MemoryStream(lh0CompressedBytes);
            var output = new MemoryStream();

            // act - extract lh0 uncompressed header
            var lhExt = new LhExt();
            lhExt.ExtractOne(input, output, header);

            // assert - compare uncompressed with expected bytes
            var uncompressedBytes = output.ToArray();
            var expectedBytes = await File.ReadAllBytesAsync(@"TestData\lha\test.txt");
            Assert.Equal(expectedBytes, uncompressedBytes);
        }
        
        [Fact]
        public async Task WhenExtractCompressedLh5DataThenBytesAreEqual()
        {
            // arrange - lh5 compressed entry (bytes extracted from header end to next header)
            var header = new LzHeader
            {
                Method = Constants.LZHUFF5_METHOD,
                Name = "test1.info",
                OriginalSize = 900,
                PackedSize = 435,
                HasCrc = true,
                Crc = 11704
            };
            var lh5CompressedBytes = await File.ReadAllBytesAsync(@"TestData\lha\test1.info.lh5.bin");
            await using var input = new MemoryStream(lh5CompressedBytes);
            await using var output = new MemoryStream();

            // act - extract lha5 compressed header
            var lhExt = new LhExt();
            lhExt.ExtractOne(input, output, header);

            // assert - compare uncompressed with expected bytes
            var uncompressedBytes = output.ToArray();
            var expectedBytes = await File.ReadAllBytesAsync(@"TestData\lha\test1.info");
            Assert.Equal(expectedBytes, uncompressedBytes);
        }
    }
}