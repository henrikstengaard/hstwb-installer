namespace HstWbInstaller.Imager.Core.Tests
{
    using System;
    using System.IO;
    using System.Threading;
    using System.Threading.Tasks;
    using Commands;
    using HstWbInstaller.Core.IO.RigidDiskBlocks;
    using Microsoft.Extensions.Logging.Abstractions;
    using Models;
    using Xunit;

    public class GivenOptimizeCommand : CommandTestBase
    {
        [Fact]
        public async Task WhenOptimizeImgWithoutRigidDiskBlockThenSizeIsNotChanged()
        {
            // arrange
            var path = $"{Guid.NewGuid()}.img";
            var fakeCommandHelper = new FakeCommandHelper();
            var bytes = fakeCommandHelper.CreateTestData();
            fakeCommandHelper.WriteableMedias.Add(new Media(path, path, Media.MediaType.Raw, false,
                new MemoryStream(bytes)));
            var cancellationTokenSource = new CancellationTokenSource();
            
            // optimize
            var optimizeCommand = new OptimizeCommand(new NullLogger<OptimizeCommand>(), fakeCommandHelper, path);
            var result = await optimizeCommand.Execute(cancellationTokenSource.Token);
            Assert.True(result.IsSuccess);

            // assert bytes and media optimized bytes are identical
            var optimizedBytes = fakeCommandHelper.GetMedia(path).GetBytes();
            Assert.Equal(bytes.Length, optimizedBytes.Length);
            Assert.Equal(bytes, optimizedBytes);
        }

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
            var optimizeCommand = new OptimizeCommand(new NullLogger<OptimizeCommand>(), fakeCommandHelper, path);
            var result = await optimizeCommand.Execute(cancellationTokenSource.Token);
            Assert.True(result.IsSuccess);

            // assert media contains optimized rigid disk block size
            var optimizedBytes = fakeCommandHelper.GetMedia(path).GetBytes();
            Assert.Equal(rigidDiskBlockSize, optimizedBytes.Length);
        }
    }
}