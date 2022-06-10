namespace HstWbInstaller.Core.Tests.FastFileSystemTests
{
    using System.Linq;
    using System.Threading.Tasks;
    using IO.FastFileSystem;
    using Xunit;

    public class GivenDirBlock
    {
        [Fact]
        public async Task WhenReadAsEntryBlockThenBlocksAreEqual()
        {
            var dirBlock = new DirBlock
            {
                Type = Constants.T_HEADER,
                HeaderKey = 887,
                HighSeq = 0,
                HashTableSize = 0,
                HashTable = Enumerable.Range(1, 72).ToArray(),
                Comment = "Comment",
                Name = "DirEntry",
                Parent = 880,
                SecType = Constants.ST_DIR
            };

            var dirBlockBytes = await DirBlockWriter.BuildBlock(dirBlock, 512);

            var entryBlock = await EntryBlockReader.Parse(dirBlockBytes);
            
            Assert.Equal(dirBlock.Type, entryBlock.Type);
            Assert.Equal(dirBlock.HeaderKey, entryBlock.HeaderKey);
            Assert.Equal(dirBlock.HighSeq, entryBlock.HighSeq);
            Assert.Equal(dirBlock.HashTableSize, entryBlock.HashTableSize);
            Assert.Equal(dirBlock.HashTable, entryBlock.HashTable);
            Assert.Equal(dirBlock.Comment, entryBlock.Comment);
            Assert.Equal(dirBlock.Name, entryBlock.Name);
            Assert.Equal(dirBlock.Parent, entryBlock.Parent);
            Assert.Equal(dirBlock.SecType, entryBlock.SecType);
        }
        
    }
}