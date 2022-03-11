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
    using Models;
    using Xunit;

    public class GivenVerifyCommand : CommandTestBase
    {
        [Fact]
        public async Task WhenVerifySourceToImgDestinationThenReadDataIsIdentical()
        {
            // arrange
            var sourcePath = $"{Guid.NewGuid()}.img";
            var destinationPath = $"{Guid.NewGuid()}.img";
            var fakeCommandHelper = new FakeCommandHelper(new[] { sourcePath, destinationPath });
            var cancellationTokenSource = new CancellationTokenSource();

            // act - verify source img to destination img
            var verifyCommand =
                new VerifyCommand(new NullLogger<VerifyCommand>(), fakeCommandHelper, new List<IPhysicalDrive>(), sourcePath, destinationPath);
            DataProcessedEventArgs dataProcessedEventArgs = null;
            verifyCommand.DataProcessed += (_, args) =>
            {
                dataProcessedEventArgs = args;
            };
            await verifyCommand.Execute(cancellationTokenSource.Token);

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
        public async Task WhenVerifySourceToVhdDestinationThenReadDataIsIdentical()
        {
            // arrange
            var sourcePath = $"{Guid.NewGuid()}.img";
            var destinationPath = $"{Guid.NewGuid()}.vhd";
            var fakeCommandHelper = new FakeCommandHelper(new[] { sourcePath });
            var cancellationTokenSource = new CancellationTokenSource();

            // arrange destination vhd has copy of source img data
            var sourceBytes = fakeCommandHelper.GetMedia(sourcePath).GetBytes();
            await fakeCommandHelper.AppendWriteableMediaDataVhd(destinationPath, sourceBytes.Length, sourceBytes);

            // act - verify source img to destination img
            var verifyCommand = new VerifyCommand(new NullLogger<VerifyCommand>(), fakeCommandHelper, new List<IPhysicalDrive>(), sourcePath, destinationPath);
            var result = await verifyCommand.Execute(cancellationTokenSource.Token);
            Assert.True(result.IsSuccess);

            // delete destination path vhd
            File.Delete(destinationPath);
        }
        
        [Fact]
        public async Task WhenVerifySourceToImgDestinationWithSizeThenReadDataIsIdentical()
        {
            // arrange
            var sourcePath = $"{Guid.NewGuid()}.img";
            var destinationPath = $"{Guid.NewGuid()}.img";
            var size = 16 * 512;
            var fakeCommandHelper = new FakeCommandHelper(new[] { sourcePath, destinationPath });
            var cancellationTokenSource = new CancellationTokenSource();

            // act - verify source img to destination img
            var verifyCommand = new VerifyCommand(new NullLogger<VerifyCommand>(), fakeCommandHelper, new List<IPhysicalDrive>(), sourcePath,
                destinationPath, size);
            var result = await verifyCommand.Execute(cancellationTokenSource.Token);
            Assert.True(result.IsSuccess);

            // assert data is identical
            var sourceBytes = fakeCommandHelper.GetMedia(sourcePath).GetBytes(size);
            var destinationBytes = fakeCommandHelper.GetMedia(destinationPath).GetBytes(size);
            Assert.Equal(sourceBytes, destinationBytes);
        }

        [Fact]
        public async Task WhenVerifySourceToImgDestinationWithDifferentBytesAtOffsetThenResultIsByteNotEqualError()
        {
            // arrange
            const int offsetWithError = 8390;
            const byte sourceByte = 178;
            const byte destinationByte = 250;
            var sourcePath = $"{Guid.NewGuid()}.img";
            var destinationPath = $"{Guid.NewGuid()}.img";
            var fakeCommandHelper = new FakeCommandHelper();
            var cancellationTokenSource = new CancellationTokenSource();

            // create source
            var sourceBytes = fakeCommandHelper.CreateTestData();
            sourceBytes[offsetWithError] = sourceByte;
            fakeCommandHelper.ReadableMedias.Add(new Media(sourcePath, sourcePath, Media.MediaType.Raw, false,
                new MemoryStream(sourceBytes)));

            // create destination
            var destinationBytesWithError = fakeCommandHelper.CreateTestData();
            destinationBytesWithError[offsetWithError] = destinationByte;
            fakeCommandHelper.ReadableMedias.Add(new Media(destinationPath, destinationPath, Media.MediaType.Raw, false,
                new MemoryStream(destinationBytesWithError)));

            // act - verify source img to destination img
            var verifyCommand =
                new VerifyCommand(new NullLogger<VerifyCommand>(), fakeCommandHelper, new List<IPhysicalDrive>(), sourcePath, destinationPath);
            var result = await verifyCommand.Execute(cancellationTokenSource.Token);
            Assert.False(result.IsSuccess);
            Assert.Equal(typeof(ByteNotEqualError), result.Error.GetType());
            var byteNotEqualError = (ByteNotEqualError)result.Error;
            Assert.Equal(offsetWithError, byteNotEqualError.Offset);
            Assert.Equal(sourceByte, byteNotEqualError.SourceByte);
            Assert.Equal(destinationByte, byteNotEqualError.DestinationByte);
        }

        [Fact]
        public async Task WhenVerifySourceToImgDestinationWithDifferentSizesThenResultIsSizeNotEqualError()
        {
            // arrange
            var sourcePath = $"{Guid.NewGuid()}.img";
            var destinationPath = $"{Guid.NewGuid()}.img";
            var fakeCommandHelper = new FakeCommandHelper();
            var cancellationTokenSource = new CancellationTokenSource();

            // create source
            var sourceBytes = fakeCommandHelper.CreateTestData();
            fakeCommandHelper.ReadableMedias.Add(new Media(sourcePath, sourcePath, Media.MediaType.Raw, false,
                new MemoryStream(sourceBytes)));

            // create destination
            var destinationSize = sourceBytes.Length / 2;
            var destinationBytesChunk = new byte[Convert.ToInt32(destinationSize)];
            Array.Copy(sourceBytes, 0, destinationBytesChunk, 0, destinationBytesChunk.Length);
            fakeCommandHelper.ReadableMedias.Add(new Media(destinationPath, destinationPath, Media.MediaType.Raw, false,
                new MemoryStream(destinationBytesChunk)));

            // act - verify source img to destination img
            var verifyCommand =
                new VerifyCommand(new NullLogger<VerifyCommand>(), fakeCommandHelper, new List<IPhysicalDrive>(), sourcePath, destinationPath);
            var result = await verifyCommand.Execute(cancellationTokenSource.Token);
            Assert.False(result.IsSuccess);

            Assert.Equal(typeof(SizeNotEqualError), result.Error.GetType());
            var sizeNotEqualError = (SizeNotEqualError)result.Error;
            Assert.Equal(0, sizeNotEqualError.Offset);
            Assert.Equal(sourceBytes.Length, sizeNotEqualError.Size);
        }

        [Fact]
        public async Task WhenVerifySourceSmallerThanDestinationThenDataIsIdentical()
        {
            // arrange
            var sourcePath = $"{Guid.NewGuid()}.img";
            var destinationPath = $"{Guid.NewGuid()}.img";
            var fakeCommandHelper = new FakeCommandHelper();
            var cancellationTokenSource = new CancellationTokenSource();
            var testDataBytes = fakeCommandHelper.CreateTestData();

            // create source
            fakeCommandHelper.ReadableMedias.Add(new Media(sourcePath, sourcePath, Media.MediaType.Raw, false,
                new MemoryStream(testDataBytes)));
            
            // create destination
            fakeCommandHelper.ReadableMedias.Add(new Media(destinationPath, destinationPath, Media.MediaType.Raw, false,
                new MemoryStream(testDataBytes.Concat(testDataBytes).ToArray())));
            
            // act - verify source img to destination img
            var verifyCommand =
                new VerifyCommand(new NullLogger<VerifyCommand>(), fakeCommandHelper, new List<IPhysicalDrive>(), sourcePath, destinationPath);
            var result = await verifyCommand.Execute(cancellationTokenSource.Token);
            Assert.True(result.IsSuccess);
        }
        
        [Fact]
        public async Task WhenVerifySourceIsLargerThanDestinationThenResultIsSizeNotEqualError()
        {
            // arrange
            var sourcePath = $"{Guid.NewGuid()}.img";
            var destinationPath = $"{Guid.NewGuid()}.img";
            var fakeCommandHelper = new FakeCommandHelper();
            var cancellationTokenSource = new CancellationTokenSource();
            var testDataBytes = fakeCommandHelper.CreateTestData();

            // create source
            fakeCommandHelper.ReadableMedias.Add(new Media(sourcePath, sourcePath, Media.MediaType.Raw, false,
                new MemoryStream(testDataBytes.Concat(testDataBytes).ToArray())));
            
            // create destination
            fakeCommandHelper.ReadableMedias.Add(new Media(destinationPath, destinationPath, Media.MediaType.Raw, false,
                new MemoryStream(testDataBytes)));
            
            // act - verify source img to destination img
            var verifyCommand =
                new VerifyCommand(new NullLogger<VerifyCommand>(), fakeCommandHelper, new List<IPhysicalDrive>(), sourcePath, destinationPath);
            var result = await verifyCommand.Execute(cancellationTokenSource.Token);
            Assert.False(result.IsSuccess);
            
            Assert.Equal(typeof(SizeNotEqualError), result.Error.GetType());
            var sizeNotEqualError = (SizeNotEqualError)result.Error;
            Assert.Equal(0, sizeNotEqualError.Offset);
            Assert.Equal(testDataBytes.Length * 2, sizeNotEqualError.Size);
        }
    }
}