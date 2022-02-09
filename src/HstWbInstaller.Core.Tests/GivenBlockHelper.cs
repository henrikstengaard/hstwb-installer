namespace HstWbInstaller.Core.Tests
{
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using IO.RigidDiskBlocks;
    using Xunit;

    public class GivenBlockHelper
    {
        [Fact]
        public async Task WhenCreateFileSystemHeaderBlockThenBlockIsValid()
        {
            var pfs3AioBytes = await File.ReadAllBytesAsync(@"TestData\pfs3aio");
            
            var fileSystemHeaderBlock =
                BlockHelper.CreateFileSystemHeaderBlock(FormatHelper.FormatDosType("PDS", 3), 19, 2,
                    pfs3AioBytes);

            Assert.Equal(1245186U, fileSystemHeaderBlock.Version);
            var loadSegBlockCount = Math.Ceiling((double)pfs3AioBytes.Length / (512 - 5 * 4));
            Assert.Equal(loadSegBlockCount, fileSystemHeaderBlock.LoadSegBlocks.Count());

            var actualPfs3AioBytes = new List<byte>();

            foreach (var loadSegBlock in fileSystemHeaderBlock.LoadSegBlocks)
            {
                actualPfs3AioBytes.AddRange(loadSegBlock.Data);
            }
            
            Assert.Equal(pfs3AioBytes.Length, actualPfs3AioBytes.Count);
            Assert.True(pfs3AioBytes.SequenceEqual(actualPfs3AioBytes));
        }
    }
}