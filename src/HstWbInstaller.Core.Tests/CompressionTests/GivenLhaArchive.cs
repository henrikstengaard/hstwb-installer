namespace HstWbInstaller.Core.Tests.CompressionTests
{
    using System.IO;
    using System.Text;
    using System.Threading.Tasks;
    using Extensions;
    using IO.Lha;
    using Xunit;

    public class GivenLhaArchive
    {
        [Fact]
        public async Task WhenExtractLhaEntriesDataThenDataIsReturned()
        {
            // arrange - open lha file
            var path = @"TestData\Lha\amiga.lha";
            await using var stream = new MemoryStream(await File.ReadAllBytesAsync(path));
            var lhaReader = new LhaReader(stream, Encoding.GetEncoding("ISO-8859-1"));
            var lhExt = new LhExt();

            // act - read entries from lha file until header is null
            LzHeader header;
            do
            {
                // read next header
                header = await lhaReader.Read();

                // skip, if header is null (end of archive)
                if (header == null)
                {
                    continue;
                }

                // read packed bytes for entry
                var packedBytes = await stream.ReadBytes((int)header.PackedSize);
                
                // extract packed bytes for entry
                await using var input = new MemoryStream(packedBytes);
                await using var output = new MemoryStream();
                lhExt.ExtractOne(input, output, header); // something cases this to periodically fail when running all tests
                //
                // assert - header original size is equal to uncompressed output
                Assert.Equal(header.OriginalSize, output.Length);
            } while (header != null);
        }
    }
}