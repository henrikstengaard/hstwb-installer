using Xunit;

namespace HstWbInstaller.Imager.Core.Tests
{
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Threading;
    using System.Threading.Tasks;
    using Commands;
    using Microsoft.Extensions.Logging.Abstractions;

    public class GivenReadCommand : CommandTestBase
    {
        [Fact]
        public async Task WhenReadSourceToImgDestinationThenReadDataIsIdentical()
        {
            // arrange
            var sourcePath = $"{Guid.NewGuid()}.img";
            var destinationPath = $"{Guid.NewGuid()}.img";
            var fakeCommandHelper = new FakeCommandHelper(new []{sourcePath}, new []{destinationPath});
            var cancellationTokenSource = new CancellationTokenSource();
            
            // act - read source img to destination img
            var readCommand = new ReadCommand(new NullLogger<ReadCommand>(), fakeCommandHelper, new List<IPhysicalDrive>(), sourcePath, destinationPath);
            DataProcessedEventArgs dataProcessedEventArgs = null;
            readCommand.DataProcessed += (_, args) =>
            {
                dataProcessedEventArgs = args;
            };
            var result = await readCommand.Execute(cancellationTokenSource.Token);
            Assert.True(result.IsSuccess);
            
            Assert.NotNull(dataProcessedEventArgs);
            Assert.NotEqual(0, dataProcessedEventArgs.PercentComplete);
            Assert.NotEqual(0, dataProcessedEventArgs.BytesProcessed);
            Assert.Equal(0, dataProcessedEventArgs.BytesRemaining);
            Assert.NotEqual(0, dataProcessedEventArgs.BytesTotal);

            // assert data is identical
            var sourceBytes = fakeCommandHelper.GetMedia(sourcePath).GetBytes();
            var destinationBytes = fakeCommandHelper.GetMedia(destinationPath).GetBytes();
            Assert.Equal(sourceBytes, destinationBytes);
        }

        [Fact]
        public async Task WhenReadSourceToImgDestinationWithSizeThenReadDataIsIdentical()
        {
            // arrange
            var sourcePath = $"{Guid.NewGuid()}.img";
            var destinationPath = $"{Guid.NewGuid()}.img";
            var size = 16 * 512;
            var fakeCommandHelper = new FakeCommandHelper(new []{sourcePath}, new []{destinationPath});
            var cancellationTokenSource = new CancellationTokenSource();

            // act - read source img to destination img
            var readCommand = new ReadCommand(new NullLogger<ReadCommand>(), fakeCommandHelper, new List<IPhysicalDrive>(), sourcePath, destinationPath, size);
            var result = await readCommand.Execute(cancellationTokenSource.Token);
            Assert.True(result.IsSuccess);

            // assert data is identical
            var sourceBytes = fakeCommandHelper.GetMedia(sourcePath).GetBytes(size);
            Assert.Equal(size, sourceBytes.Length);
            var destinationBytes = fakeCommandHelper.GetMedia(destinationPath).GetBytes();
            Assert.Equal(sourceBytes, destinationBytes);
        }
        
        [Fact]
        public async Task WhenReadSourceToVhdDestinationThenReadDataIsIdentical()
        {
            // arrange
            var sourcePath = $"{Guid.NewGuid()}.img";
            var destinationPath = $"{Guid.NewGuid()}.vhd";
            var fakeCommandHelper = new FakeCommandHelper(new []{sourcePath});
            var cancellationTokenSource = new CancellationTokenSource();

            // assert: destination path vhd doesn't exist
            Assert.False(File.Exists(destinationPath));
            
            // act: read source img to destination vhd
            var readCommand = new ReadCommand(new NullLogger<ReadCommand>(), fakeCommandHelper, Enumerable.Empty<IPhysicalDrive>(), sourcePath, destinationPath);
            var result = await readCommand.Execute(cancellationTokenSource.Token);
            Assert.True(result.IsSuccess);

            // get source bytes
            var sourceBytes = fakeCommandHelper.GetMedia(sourcePath).GetBytes();

            // get destination bytes from vhd
            var destinationBytes = await ReadMediaBytes(fakeCommandHelper, destinationPath, FakeCommandHelper.ImageSize);
            var destinationPathSize = new FileInfo(destinationPath).Length;

            // assert length is not the same (vhd file format different than img) and bytes are the same
            Assert.NotEqual(sourceBytes.Length, destinationPathSize);
            Assert.Equal(sourceBytes, destinationBytes);
            
            // delete destination path vhd
            File.Delete(destinationPath);
        }
        
        [Fact]
        public async Task WhenReadSourceToVhdDestinationWithSizeThenReadDataIsIdentical()
        {
            // arrange
            var sourcePath = $"{Guid.NewGuid()}.img";
            var destinationPath = $"{Guid.NewGuid()}.vhd";
            var size = 16 * 512;
            var fakeCommandHelper = new FakeCommandHelper(new []{sourcePath}, new []{destinationPath});
            var cancellationTokenSource = new CancellationTokenSource();

            // act - read source img to destination vhd
            var readCommand = new ReadCommand(new NullLogger<ReadCommand>(), fakeCommandHelper, Enumerable.Empty<IPhysicalDrive>(), sourcePath, destinationPath, size);
            var result = await readCommand.Execute(cancellationTokenSource.Token);
            Assert.True(result.IsSuccess);

            // get source bytes
            var sourceBytes = fakeCommandHelper.GetMedia(sourcePath).GetBytes(size);
            Assert.Equal(size, sourceBytes.Length);

            // get destination bytes from vhd
            var destinationBytes = await ReadMediaBytes(fakeCommandHelper, destinationPath, sourceBytes.Length);
            var destinationPathSize = new FileInfo(destinationPath).Length;

            // assert length is not the same (vhd file format different than img) and bytes are the same
            Assert.NotEqual(sourceBytes.Length, destinationPathSize);
            Assert.Equal(sourceBytes, destinationBytes);
            
            // delete destination path vhd
            File.Delete(destinationPath);
        }
    }
}