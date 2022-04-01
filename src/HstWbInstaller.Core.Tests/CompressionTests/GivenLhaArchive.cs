namespace HstWbInstaller.Core.Tests.CompressionTests
{
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Text;
    using System.Threading.Tasks;
    using IO.Lha;
    using Xunit;

    public class GivenLhaArchive
    {
        [Fact]
        public async Task WhenReadAmigaLhaFileThenHeadersAreReturned()
        {
            // arrange - open lha file
            var path = @"TestData\Lha\amiga.lha";
            await using var stream = File.OpenRead(path);
            var lhaReader = new LhaReader(stream, Encoding.GetEncoding("ISO-8859-1"));

            // act - read entries from lha file
            var entries = new List<LzHeader>();
            LzHeader header;
            do
            {
                header = await lhaReader.Read();

                if (header == null)
                {
                    continue;
                }

                entries.Add(header);
            } while (header != null);
            
            // assert - entries have been read from lha file
            Assert.NotEmpty(entries);
            var expectedEntryNames = new[] { "test.txt", "test1.info", @"test1\test1.txt", @"test1\test2.info", @"test1\test2\test2.txt" };
            Assert.Equal(expectedEntryNames, entries.Select(x => x.Name));
        }
    }
}