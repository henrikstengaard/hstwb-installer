﻿namespace HstWbInstaller.Imager.Core.Tests
{
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Threading.Tasks;
    using Commands;
    using Xunit;

    public class GivenWriteCommand : CommandTestBase
    {
        [Fact]
        public async Task WhenWriteSourceToImgDestinationThenReadDataIsIdentical()
        {
            // arrange
            var sourcePath = $"{Guid.NewGuid()}.img";
            var destinationPath = $"{Guid.NewGuid()}.img";
            var fakeCommandHelper = new FakeCommandHelper(new[] { sourcePath }, new []{ destinationPath });

            // act - write source img to destination img
            var writeCommand =
                new WriteCommand(fakeCommandHelper, new List<IPhysicalDrive>(), sourcePath, destinationPath);
            DataProcessedEventArgs dataProcessedEventArgs = null;
            writeCommand.DataProcessed += (_, args) =>
            {
                dataProcessedEventArgs = args;
            };
            var result = await writeCommand.Execute();
            Assert.True(result.IsSuccess);
            
            Assert.NotNull(dataProcessedEventArgs);
            Assert.NotEqual(0, dataProcessedEventArgs.PercentComplete);
            Assert.NotEqual(0, dataProcessedEventArgs.BytesProcessed);
            Assert.NotEqual(0, dataProcessedEventArgs.TotalBytesProcessed);
            Assert.NotEqual(0, dataProcessedEventArgs.TotalBytes);

            // assert data is identical
            var sourceBytes = fakeCommandHelper.GetMedia(sourcePath).GetBytes();
            var destinationBytes = fakeCommandHelper.GetMedia(destinationPath).GetBytes();
            Assert.Equal(sourceBytes, destinationBytes);
        }
        
        [Fact]
        public async Task WhenWriteSourceToVhdDestinationThenReadDataIsIdentical()
        {
            // arrange
            var sourcePath = $"{Guid.NewGuid()}.img";
            var destinationPath = $"{Guid.NewGuid()}.vhd";
            var fakeCommandHelper = new FakeCommandHelper(new[] { sourcePath });

            // arrange destination vhd has copy of source img data
            var sourceBytes = fakeCommandHelper.GetMedia(sourcePath).GetBytes();

            // act - write source img to destination vhd
            var writeCommand = new WriteCommand(fakeCommandHelper, new List<IPhysicalDrive>(), sourcePath, destinationPath, sourceBytes.Length);
            var result = await writeCommand.Execute();
            Assert.True(result.IsSuccess);

            // delete destination path vhd
            File.Delete(destinationPath);
        }
    }
}