namespace HstWbInstaller.Imager.Core.Tests
{
    using System;
    using System.IO;
    using System.Threading;
    using System.Threading.Tasks;
    using Commands;
    using HstWbInstaller.Core.IO.RigidDiskBlocks;
    using Models;
    using Xunit;

    public class GivenOptimizeCommand : CommandTestBase
    {
        [Fact]
        public async Task WhenOptimizeImgWithRigidDiskBlockThenSizeIsChanged()
        {
            // arrange
            var path = $"{Guid.NewGuid()}.img";
            var rigidDiskBlockSize = 8192;
            var fakeCommandHelper = new FakeCommandHelper(rigidDiskBlock: new RigidDiskBlock
            {
                DiskSize = rigidDiskBlockSize
            });
            // var bytes = fakeCommandHelper.CreateTestData();
            fakeCommandHelper.WriteableMedias.Add(new Media(path, path, Media.MediaType.Raw, false,
                new MemoryStream(new byte[16384])));
            var cancellationTokenSource = new CancellationTokenSource();

            // optimize
            var optimizeCommand = new OptimizeCommand(fakeCommandHelper, path);
            var result = await optimizeCommand.Execute(cancellationTokenSource.Token);
            Assert.True(result.IsSuccess);

            // assert media contains optimized rigid disk block size
            var optimizedBytes = fakeCommandHelper.GetMedia(path).GetBytes();
            Assert.Equal(rigidDiskBlockSize, optimizedBytes.Length);
        }
    }
}