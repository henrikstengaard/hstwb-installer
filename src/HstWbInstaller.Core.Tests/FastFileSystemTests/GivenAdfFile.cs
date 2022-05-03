namespace HstWbInstaller.Core.Tests.FastFileSystemTests
{
    using System.Linq;
    using System.Text;
    using System.Threading.Tasks;
    using IO.FastFileSystem;
    using Xunit;

    public class GivenAdfFile
    {
        [Fact]
        public async Task WhenMountAdfAndReadEntriesRecursivelyThenEntriesAreReturned()
        {
            // arrange - adf file
            var adfPath = @"TestData\adf\ffstest.adf";
            await using var adfStream = System.IO.File.OpenRead(adfPath);
            
            // act - mount adf
            var volume = await FastFileSystemHelper.MountAdf(adfStream);

            // act - read entries recursively from root block
            var entries = (await Directory.AdfGetRDirEnt(volume, volume.RootBlock, true))
                .OrderBy(x => x.Name).ToList();
            
            // assert - root block contains 2 entries
            Assert.NotEmpty(entries);
            Assert.Equal(2, entries.Count);

            // assert - entry "test.txt" in root block
            var entry1 = entries.FirstOrDefault(x => x.Name == "test.txt");
            Assert.NotNull(entry1);
            Assert.Equal(Entry.EntryType.File, entry1.Type);
            Assert.Equal(21, entry1.Size);
            Assert.Null(entry1.SubDir);
            
            // assert - entry "testdir" in root block
            var entry2 = entries.FirstOrDefault(x => x.Name == "testdir");
            Assert.NotNull(entry2);
            Assert.Equal(Entry.EntryType.Dir, entry2.Type);
            Assert.Equal(0, entry2.Size);
            Assert.NotEmpty(entry2.SubDir);
            
            // assert - entry "test2.txt" in entry 2 sub directory
            var entry3 = entry2.SubDir.FirstOrDefault(x => x.Name == "test2.txt");
            Assert.NotNull(entry3);
            Assert.Equal(Entry.EntryType.File, entry3.Type);
            Assert.Equal(29, entry3.Size);
        }
        
        [Fact]
        public async Task WhenMountAdfAndReadFileFromThenDataIsReadCorrectly()
        {
            // arrange - adf file
            var adfPath = @"TestData\adf\ffstest.adf";
            await using var adfStream = System.IO.File.OpenRead(adfPath);
            
            // act - mount adf
            var volume = await FastFileSystemHelper.MountAdf(adfStream);
            
            // act - open entry stream
            var entryStream = await File.Open(volume, volume.RootBlock, "test.txt", FileMode.Read);

            // act - read entry stream
            var buffer = new byte[512];
            var bytesRead = await entryStream.ReadAsync(buffer, 0, buffer.Length);

            // assert - read entry matches text
            Assert.Equal(21, bytesRead);
            var text = Encoding.GetEncoding("ISO-8859-1").GetString(buffer, 0, bytesRead);
            Assert.Equal("This is a test file!\n", text);
        }
    }
}