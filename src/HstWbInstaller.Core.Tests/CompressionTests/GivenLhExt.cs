namespace HstWbInstaller.Core.Tests.CompressionTests
{
    using System.IO;
    using System.Threading.Tasks;
    using IO.Lha;
    using Xunit;

    public class GivenLhExt
    {
        [Fact]
        public async Task WhenExtractUncompressedLh0DataThenBytesAreEqual()
        {
            // arrange - lha0 uncompressed entry (bytes extracted from header end to next header)
            var lha5CompressedBytes = await File.ReadAllBytesAsync(@"TestData\lha\test.txt.lh0.bin");
            var input = new MemoryStream(lha5CompressedBytes);
            var output = new MemoryStream();

            var lha = new Lha
            {
                compsize = 15,
                origsize = 15,
            };

            var header = new LzHeader
            {
                Method = Constants.LZHUFF0_METHOD,
                Name = "test1.info",
                OriginalSize = 15,
                PackedSize = 15,
            };

            // act - extract lha0 uncompressed header
            var crcIo = new CrcIo(lha);
            var lhExt = new LhExt(lha, crcIo);
            lhExt.ExtractOne(input, output, header);

            // assert - compare uncompressed with expected bytes
            var uncompressedBytes = output.ToArray();
            var expectedBytes = await File.ReadAllBytesAsync(@"TestData\lha\test.txt");
            Assert.Equal(expectedBytes, uncompressedBytes);
        }
        
        [Fact]
        public async Task WhenExtractCompressedLh5DataThenBytesAreEqual()
        {
            // arrange - lha5 compressed entry (bytes extracted from header end to next header)
            var lha5CompressedBytes = await File.ReadAllBytesAsync(@"TestData\lha\test1.info.lh5.bin");
            var input = new MemoryStream(lha5CompressedBytes);
            var output = new MemoryStream();

            var lha = new Lha
            {
                compsize = 435,
                origsize = 900,
            };

            var header = new LzHeader
            {
                Method = Constants.LZHUFF5_METHOD,
                Name = "test1.info",
                OriginalSize = 900,
                PackedSize = 435,
            };

            // act - extract lha5 compressed header
            var crcIo = new CrcIo(lha);
            var lhExt = new LhExt(lha, crcIo);
            lhExt.ExtractOne(input, output, header);

            // assert - compare uncompressed with expected bytes
            var uncompressedBytes = output.ToArray();
            var expectedBytes = await File.ReadAllBytesAsync(@"TestData\lha\test1.info");
            Assert.Equal(expectedBytes, uncompressedBytes);
        }
    }
}