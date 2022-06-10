namespace HstWbInstaller.Imager.Core.Tests
{
    using System;
    using System.IO;
    using System.Threading;
    using System.Threading.Tasks;
    using Commands;
    using Microsoft.Extensions.Logging.Abstractions;
    using Xunit;

    public class GivenBlankCommand : CommandTestBase
    {
        [Fact]
        public async Task WhenCreateBlankImgThenDataIzZeroFilled()
        {
            // arrange
            var path = $"{Guid.NewGuid()}.img";
            var size = 512 * 512;
            var fakeCommandHelper = new FakeCommandHelper(writeableMediaPaths: new[] { path });
            var cancellationTokenSource = new CancellationTokenSource();

            // act - create blank
            var blankCommand = new BlankCommand(new NullLogger<BlankCommand>(), fakeCommandHelper, path, size);
            var result = await blankCommand.Execute(cancellationTokenSource.Token);
            Assert.True(result.IsSuccess);

            // assert data is zero filled
            var sourceBytes = new byte[size];
            var destinationBytes = fakeCommandHelper.GetMedia(path).GetBytes();
            Assert.Equal(sourceBytes, destinationBytes);
        }

        [Fact]
        public async Task WhenCreateBlankVhdThenDataIzZeroFilled()
        {
            // arrange
            var path = $"{Guid.NewGuid()}.vhd";
            var size = 512 * 512;
            var fakeCommandHelper = new FakeCommandHelper();
            var cancellationTokenSource = new CancellationTokenSource();

            // act - create blank
            var blankCommand = new BlankCommand(new NullLogger<BlankCommand>(), fakeCommandHelper, path, size);
            var result = await blankCommand.Execute(cancellationTokenSource.Token);
            Assert.True(result.IsSuccess);

            // get destination bytes from vhd
            var destinationBytes = await ReadMediaBytes(fakeCommandHelper, path, size);
            var destinationPathSize = new FileInfo(path).Length;

            // assert vhd is less than size
            Assert.True(destinationPathSize < size);

            // assert data is zero filled
            var sourceBytes = new byte[size];
            Assert.Equal(sourceBytes, destinationBytes);

            // delete vhd file
            File.Delete(path);
        }
    }
}