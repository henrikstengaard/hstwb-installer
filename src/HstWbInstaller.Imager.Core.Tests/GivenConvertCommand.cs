﻿namespace HstWbInstaller.Imager.Core.Tests
{
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using System.Threading.Tasks;
    using Commands;
    using Xunit;

    public class GivenConvertCommand : CommandTestBase
    {
        [Fact]
        public async Task WhenConvertSourceToImgDestinationThenReadDataIsIdentical()
        {
            // arrange
            var sourcePath = $"{Guid.NewGuid()}.img";
            var destinationPath = $"{Guid.NewGuid()}.img";
            var fakeCommandHelper = new FakeCommandHelper(new []{sourcePath}, new []{destinationPath});
            
            // act - convert source img to destination img
            var convertCommand = new ConvertCommand(fakeCommandHelper, new List<IPhysicalDrive>(), sourcePath, destinationPath);
            DataProcessedEventArgs dataProcessedEventArgs = null;
            convertCommand.DataProcessed += (_, args) =>
            {
                dataProcessedEventArgs = args;
            };
            var result = await convertCommand.Execute();
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
        public async Task WhenConvertSourceToImgDestinationWithSizeThenReadDataIsIdentical()
        {
            // arrange
            var sourcePath = $"{Guid.NewGuid()}.img";
            var destinationPath = $"{Guid.NewGuid()}.img";
            var size = 16 * 512;
            var fakeCommandHelper = new FakeCommandHelper(new []{sourcePath}, new []{destinationPath});
            
            // act - convert source img to destination img
            var convertCommand = new ConvertCommand(fakeCommandHelper, new List<IPhysicalDrive>(), sourcePath, destinationPath, size);
            var result = await convertCommand.Execute();
            Assert.True(result.IsSuccess);

            // assert data is identical within defined size
            var sourceBytes = fakeCommandHelper.GetMedia(sourcePath).GetBytes(size);
            Assert.Equal(size, sourceBytes.Length);
            var destinationBytes = fakeCommandHelper.GetMedia(destinationPath).GetBytes();
            Assert.Equal(sourceBytes, destinationBytes);
        }
        
        [Fact]
        public async Task WhenConvertSourceToVhdDestinationThenReadDataIsIdentical()
        {
            // arrange
            var sourcePath = $"{Guid.NewGuid()}.img";
            var destinationPath = $"{Guid.NewGuid()}.vhd";
            var fakeCommandHelper = new FakeCommandHelper(new []{sourcePath}, new []{destinationPath});
            
            // act - read source img to destination vhd
            var convertCommand = new ConvertCommand(fakeCommandHelper, Enumerable.Empty<IPhysicalDrive>(), sourcePath, destinationPath);
            var result = await convertCommand.Execute();
            Assert.True(result.IsSuccess);

            // get source bytes
            var sourceBytes = fakeCommandHelper.GetMedia(sourcePath).GetBytes();

            // get destination bytes from vhd
            var destinationBytes = await ReadMediaBytes(fakeCommandHelper, destinationPath, sourceBytes.Length);
            var destinationPathSize = new FileInfo(destinationPath).Length;

            // assert length is not the same (vhd file format different than img) and bytes are the same
            Assert.NotEqual(sourceBytes.Length, destinationPathSize);
            Assert.Equal(sourceBytes, destinationBytes);
            
            // delete destination path vhd
            File.Delete(destinationPath);
        }
        
        [Fact]
        public async Task WhenConvertSourceToVhdDestinationWithSizeThenReadDataIsIdentical()
        {
            // arrange
            var sourcePath = $"{Guid.NewGuid()}.img";
            var destinationPath = $"{Guid.NewGuid()}.vhd";
            var size = 16 * 512;
            var fakeCommandHelper = new FakeCommandHelper(new []{sourcePath}, new []{destinationPath});
            
            // act - read source img to destination vhd
            var convertCommand = new ConvertCommand(fakeCommandHelper, Enumerable.Empty<IPhysicalDrive>(), sourcePath, destinationPath, size);
            var result = await convertCommand.Execute();
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