namespace HstWbInstaller.Imager.Core.Tests
{
    using System;
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using Commands;
    using Xunit;

    public class GivenInfoCommand : CommandTestBase
    {
        [Fact]
        public async Task WhenReadInfoFromSourceImgThenDiskInfoIsReturned()
        {
            // arrange
            var path = $"{Guid.NewGuid()}.img";
            var fakeCommandHelper = new FakeCommandHelper(new[] { path });

            // read info from path
            var infoCommand = new InfoCommand(fakeCommandHelper, Enumerable.Empty<IPhysicalDrive>(), path);
            MediaInfo mediaInfo = null;
            infoCommand.DiskInfoRead += (_, args) =>
            {
                mediaInfo = args.MediaInfo;
            };
            var result = await infoCommand.Execute();
            Assert.True(result.IsSuccess);

            // assert media info
            Assert.NotNull(mediaInfo);
            Assert.Equal(mediaInfo.DiskSize, FakeCommandHelper.ImageSize);
            Assert.Null(mediaInfo.RigidDiskBlock);
        }
        
        [Fact]
        public async Task WhenReadInfoFromSourceImgWithRigidDiskBlockThenDiskInfoIsReturned()
        {
            // arrange
            var path = Path.Combine("TestData", "rigid-disk-block.img");
            var fakeCommandHelper = new FakeCommandHelper(new[] { path });

            // read info from path
            var infoCommand = new InfoCommand(fakeCommandHelper, Enumerable.Empty<IPhysicalDrive>(), path);
            MediaInfo mediaInfo = null;
            infoCommand.DiskInfoRead += (_, args) =>
            {
                mediaInfo = args.MediaInfo;
            };
            await infoCommand.Execute();
            
            // assert media info
            Assert.NotNull(mediaInfo);
            //Assert.Equal(mediaInfo.DiskSize, FakeCommandHelper.ImageSize);
            Assert.NotNull(mediaInfo.RigidDiskBlock);
        }
    }
}