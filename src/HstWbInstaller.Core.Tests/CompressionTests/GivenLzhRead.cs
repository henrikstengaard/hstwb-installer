namespace HstWbInstaller.Core.Tests.CompressionTests
{
    using System.IO;
    using System.Text;
    using System.Threading.Tasks;
    using IO.Lha.Decode;
    using Xunit;

    public class GivenLzhRead
    {
        [Fact]
        public async Task WhenReadUncompressedLh0DataThenDataIsUncompressed()
        {
            var bytes = await File.ReadAllBytesAsync(@"TestData\lha\test.txt.lh0.bin");
            var stream = new MemoryStream(bytes);

            var lha = new lha_data
            {
                entry_bytes_remaining = bytes.Length,
                entry_is_compressed = false,
                method = "-lh0-",
                stream = stream,
                strm = new lzh_stream()
            };

            var result = LzhRead.archive_read_format_lha_read_data(lha, out var buffer, out var size, out var offset);
            
            Assert.Equal(Constants.ARCHIVE_OK, result);
            Assert.Equal(15, size);
            Assert.NotNull(buffer);
            var text = Encoding.GetEncoding("ISO-8859-1").GetString(buffer, 0, (int)size);
            Assert.Equal("This is a test\n", text);
        }
        
        [Fact(Skip = "Initial port of libarchive, but not working")]
        public async Task WhenReadCompressedLh5DataThenDataIsUncompressed()
        {
            var bytes = await File.ReadAllBytesAsync(@"TestData\lha\test1.info.lh5.bin");
            var stream = new MemoryStream(bytes);

            var lha = new lha_data
            {
                entry_bytes_remaining = bytes.Length,
                entry_is_compressed = true,
                method = "-lh5-",
                stream = stream,
                strm = new lzh_stream()
            };

            var result = LzhRead.archive_read_format_lha_read_data(lha, out var buffer, out var size, out var offset);
            
            Assert.Equal(Constants.ARCHIVE_OK, result);
            Assert.NotNull(buffer);
            Assert.NotEmpty(buffer);
        }
    }
}