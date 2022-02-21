namespace HstWbInstaller.Imager.Core.Tests
{
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Threading;
    using System.Threading.Tasks;
    using Commands;
    using Models;
    using PhysicalDrives;
    using Xunit;

    public class GivenListCommand : CommandTestBase
    {
        [Fact]
        public async Task WhenListPhysicalDrivesThenListReadIsTriggered()
        {
            var physicalDrives = new[]
            {
                new FakePhysicalDrive("Path", "Type", "Model", 8192)
            };
            var fakeCommandHelper = new FakeCommandHelper();
            var cancellationTokenSource = new CancellationTokenSource();
            
            var listCommand = new ListCommand(fakeCommandHelper, physicalDrives);
            IEnumerable<MediaInfo> mediaInfos = null;
            listCommand.ListRead += (sender, args) =>
            {
                mediaInfos = args?.MediaInfos;
            };
            var result = await listCommand.Execute(cancellationTokenSource.Token);
            Assert.True(result.IsSuccess);

            var mediaInfosList = mediaInfos.ToList();
            Assert.Single(mediaInfosList);

            var mediaInfo = mediaInfosList.First();
            
            Assert.Equal("Path", mediaInfo.Path);
            Assert.Equal(Media.MediaType.Raw, mediaInfo.Type);
            Assert.True(mediaInfo.IsPhysicalDrive);
            Assert.Equal("Model", mediaInfo.Model);
            Assert.Equal(8192, mediaInfo.DiskSize);
            Assert.Null(mediaInfo.RigidDiskBlock);
        }
        
        [Fact]
        public async Task WhenListPhysicalDrivesWithRigidDiskBlockThenListReadIsTriggered()
        {
            var path = Path.Combine("TestData", "rigid-disk-block.img");
            var physicalDrives = new[]
            {
                new FakePhysicalDrive(path, "Type", "Model", await File.ReadAllBytesAsync(path))
            };
            var fakeCommandHelper = new FakeCommandHelper(new[] { path });
            var cancellationTokenSource = new CancellationTokenSource();
            
            var listCommand = new ListCommand(fakeCommandHelper, physicalDrives);
            IEnumerable<MediaInfo> mediaInfos = null;
            listCommand.ListRead += (sender, args) =>
            {
                mediaInfos = args?.MediaInfos;
            };
            var result = await listCommand.Execute(cancellationTokenSource.Token);
            Assert.True(result.IsSuccess);

            var mediaInfosList = mediaInfos.ToList();
            Assert.Single(mediaInfosList);

            var mediaInfo = mediaInfosList.First();
            
            Assert.Equal(path, mediaInfo.Path);
            Assert.Equal(Media.MediaType.Raw, mediaInfo.Type);
            Assert.True(mediaInfo.IsPhysicalDrive);
            Assert.Equal("Model", mediaInfo.Model);
            Assert.Equal(131072, mediaInfo.DiskSize);
            Assert.NotNull(mediaInfo.RigidDiskBlock);
        }
    }
}