namespace HstWbInstaller.Core.Tests.FastFileSystemTests
{
    using System.IO;
    using System.Linq;
    using System.Text;
    using System.Threading.Tasks;
    using IO.FastFileSystem;
    using Xunit;
    using Directory = IO.FastFileSystem.Directory;
    using File = IO.FastFileSystem.File;
    using FileMode = IO.FastFileSystem.FileMode;

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

        [Fact]
        public async Task WhenMountAdfAndWriteFileThenFileIsCreated()
        {
            // arrange - adf file
            var fileName = "newtest.txt";
            var fileContent = "Hello world!";
            var adfPath = @"TestData\adf\ffstest.adf";
            var modifiedAdfPath = @"TestData\adf\ffstest_modified.adf";

            // arrange - copy adf file for testing
            System.IO.File.Copy(adfPath, modifiedAdfPath, true);
            await using var adfStream =
                System.IO.File.Open(modifiedAdfPath, System.IO.FileMode.Open, FileAccess.ReadWrite);

            // act - mount adf
            var volume = await FastFileSystemHelper.MountAdf(adfStream);

            // act - open entry stream
            var entryStream = await File.Open(volume, volume.RootBlock, fileName, FileMode.Write);

            // act - write entry stream
            var buffer = Encoding.ASCII.GetBytes(fileContent);
            await entryStream.WriteAsync(buffer, 0, buffer.Length);
            entryStream.Close();

            // act - read entries recursively from root block
            var entries = (await Directory.AdfGetRDirEnt(volume, volume.RootBlock, true))
                .OrderBy(x => x.Name).ToList();

            // assert - entry exists
            var entry = entries.FirstOrDefault(x => x.Name == fileName);
            Assert.NotNull(entry);
            Assert.Equal(fileName, entry.Name);
            Assert.Equal(fileContent.Length, entry.Size);
            Assert.Equal(Entry.EntryType.File, entry.Type);
        }

        [Fact]
        public async Task WhenMountAdfAndCreateDirectoryThenDirectoryIsCreated()
        {
            // arrange - adf file
            var directoryName = "newdir";
            var adfPath = @"TestData\adf\ffstest.adf";
            var modifiedAdfPath = @"TestData\adf\ffstest_modified.adf";

            // arrange - copy adf file for testing
            System.IO.File.Copy(adfPath, modifiedAdfPath, true);
            await using var adfStream =
                System.IO.File.Open(modifiedAdfPath, System.IO.FileMode.Open, FileAccess.ReadWrite);

            // act - mount adf
            var volume = await FastFileSystemHelper.MountAdf(adfStream);

            // act - create directory in root block
            await Directory.AdfCreateDir(volume, volume.RootBlock, directoryName);

            // act - read entries recursively from root block
            var entries = (await Directory.AdfGetRDirEnt(volume, volume.RootBlock, true))
                .OrderBy(x => x.Name).ToList();

            // assert - entry exists
            var entry = entries.FirstOrDefault(x => x.Name == directoryName);
            Assert.NotNull(entry);
            Assert.Equal(directoryName, entry.Name);
            Assert.Equal(0, entry.Size);
            Assert.Equal(Entry.EntryType.Dir, entry.Type);
        }
        
        [Fact]
        public async Task WhenMountAdfAndRenameFileThenFileIsRenamed()
        {
            // arrange - adf file
            var newName = "renamed_test";
            var adfPath = @"TestData\adf\ffstest.adf";
            var modifiedAdfPath = @"TestData\adf\ffstest_modified.adf";

            // arrange - copy adf file for testing
            System.IO.File.Copy(adfPath, modifiedAdfPath, true);
            await using var adfStream =
                System.IO.File.Open(modifiedAdfPath, System.IO.FileMode.Open, FileAccess.ReadWrite);

            // act - mount adf
            var volume = await FastFileSystemHelper.MountAdf(adfStream);

            // // act - create directory in root block
            // await Directory.AdfCreateDir(volume, volume.RootBlock, directoryName);

            // act - read entries recursively from root block
            var entries = (await Directory.AdfGetRDirEnt(volume, volume.RootBlock, true))
                .OrderBy(x => x.Name).ToList();

            // act - get first file entry
            var oldEntry = entries.FirstOrDefault(x => x.Type == Entry.EntryType.File);
            Assert.NotNull(oldEntry);

            // act - rename file entry
            var oldName = oldEntry.Name;
            await Directory.AdfRenameEntry(volume, oldEntry.Parent, oldName, oldEntry.Parent, newName);

            // act - read entries recursively from root block
            entries = (await Directory.AdfGetRDirEnt(volume, volume.RootBlock, true))
                .OrderBy(x => x.Name).ToList();

            // assert - entry with old name doesn't exist
            var entry = entries.FirstOrDefault(x => x.Name == oldName);
            Assert.Null(entry);
            
            // assert - entry with new name exist
            entry = entries.FirstOrDefault(x => x.Name == newName);
            Assert.NotNull(entry);
            Assert.Equal(newName, entry.Name);
            Assert.Equal(oldEntry.Size, entry.Size);
            Assert.Equal(oldEntry.Type, entry.Type);
        }
        
        [Fact]
        public async Task WhenMountAdfAndDeleteFileThenFileIsDeleted()
        {
            // arrange - adf file
            var adfPath = @"TestData\adf\ffstest.adf";
            var modifiedAdfPath = @"TestData\adf\ffstest_modified.adf";

            // arrange - copy adf file for testing
            System.IO.File.Copy(adfPath, modifiedAdfPath, true);
            await using var adfStream =
                System.IO.File.Open(modifiedAdfPath, System.IO.FileMode.Open, FileAccess.ReadWrite);

            // act - mount adf
            var volume = await FastFileSystemHelper.MountAdf(adfStream);
            
            // act - read entries recursively from root block
            var entries = (await Directory.AdfGetRDirEnt(volume, volume.RootBlock, true))
                .OrderBy(x => x.Name).ToList();

            // act - get first file entry
            var entry = entries.FirstOrDefault(x => x.Type == Entry.EntryType.File);
            Assert.NotNull(entry);

            // act - remote entry from root block
            var entryName = entry.Name;
            await Directory.AdfRemoveEntry(volume, volume.RootBlock, entryName);
            
            // act - read entries recursively from root block
            entries = (await Directory.AdfGetRDirEnt(volume, volume.RootBlock, true))
                .OrderBy(x => x.Name).ToList();

            // assert - entry doesn't exist, is removed
            entry = entries.FirstOrDefault(x => x.Name == entryName);
            Assert.Null(entry);
        }
        
        [Fact]
        public async Task WhenMountAdfAndSetAccessForFileThenEntryIsUpdated()
        {
            // arrange - adf file
            var adfPath = @"TestData\adf\ffstest.adf";
            var modifiedAdfPath = @"TestData\adf\ffstest_modified.adf";

            // arrange - copy adf file for testing
            System.IO.File.Copy(adfPath, modifiedAdfPath, true);
            await using var adfStream =
                System.IO.File.Open(modifiedAdfPath, System.IO.FileMode.Open, FileAccess.ReadWrite);

            // act - mount adf
            var volume = await FastFileSystemHelper.MountAdf(adfStream);
            
            // act - read entries recursively from root block
            var entries = (await Directory.AdfGetRDirEnt(volume, volume.RootBlock, true))
                .OrderBy(x => x.Name).ToList();

            // act - get first file entry
            var entry = entries.FirstOrDefault(x => x.Type == Entry.EntryType.File);
            Assert.NotNull(entry);

            // act - set access for entry
            var entryName = entry.Name;
            await Directory.AdfSetEntryAccess(volume, volume.RootBlock, entryName,
                Constants.ACCMASK_A | Constants.ACCMASK_E | Constants.ACCMASK_W);
            
            // act - read entries recursively from root block
            entries = (await Directory.AdfGetRDirEnt(volume, volume.RootBlock, true))
                .OrderBy(x => x.Name).ToList();

            // assert - get entry
            entry = entries.FirstOrDefault(x => x.Name == entryName);
            Assert.NotNull(entry);
            Assert.Equal(Constants.ACCMASK_A | Constants.ACCMASK_E | Constants.ACCMASK_W, entry.Access);
            
            // act - set access for entry
            await Directory.AdfSetEntryAccess(volume, volume.RootBlock, entryName,
                Constants.ACCMASK_R);
            
            // act - read entries recursively from root block
            entries = (await Directory.AdfGetRDirEnt(volume, volume.RootBlock, true))
                .OrderBy(x => x.Name).ToList();

            // assert - get entry
            entry = entries.FirstOrDefault(x => x.Name == entryName);
            Assert.NotNull(entry);
            Assert.Equal(Constants.ACCMASK_R, entry.Access);
        }

        [Fact]
        public async Task WhenMountAdfAndSetCommentForFileThenEntryIsUpdated()
        {
            // arrange - adf file
            var adfPath = @"TestData\adf\ffstest.adf";
            var modifiedAdfPath = @"TestData\adf\ffstest_modified.adf";

            // arrange - copy adf file for testing
            System.IO.File.Copy(adfPath, modifiedAdfPath, true);
            await using var adfStream =
                System.IO.File.Open(modifiedAdfPath, System.IO.FileMode.Open, FileAccess.ReadWrite);

            // act - mount adf
            var volume = await FastFileSystemHelper.MountAdf(adfStream);
            
            // act - read entries recursively from root block
            var entries = (await Directory.AdfGetRDirEnt(volume, volume.RootBlock, true))
                .OrderBy(x => x.Name).ToList();

            // act - get first file entry
            var entry = entries.FirstOrDefault(x => x.Type == Entry.EntryType.File);
            Assert.NotNull(entry);
            Assert.Equal(string.Empty, entry.Comment);

            // act - set access for entry
            var entryName = entry.Name;
            await Directory.AdfSetEntryComment(volume, volume.RootBlock, entryName, "A comment");
            
            // act - read entries recursively from root block
            entries = (await Directory.AdfGetRDirEnt(volume, volume.RootBlock, true))
                .OrderBy(x => x.Name).ToList();

            // assert - get entry
            entry = entries.FirstOrDefault(x => x.Name == entryName);
            Assert.NotNull(entry);
            Assert.Equal("A comment", entry.Comment);
        }
    }
}